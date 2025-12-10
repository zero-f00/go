import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'navigation_service.dart';

/// トップレベル関数として定義（バックグラウンド処理用）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await PushNotificationService.instance.handleBackgroundMessage(message);
}

/// プッシュ通知管理サービス
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static PushNotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  bool _isInitialized = false;

  /// FCMトークンを取得
  String? get fcmToken => _fcmToken;

  /// 初期化済みかどうか
  bool get isInitialized => _isInitialized;

  /// プッシュ通知サービスを初期化
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // 通知権限をリクエスト
      await _requestPermissions();

      // ローカル通知を初期化
      await _initializeLocalNotifications();

      // FCMトークンを取得
      await _getFCMToken();

      // メッセージリスナーをセットアップ
      _setupMessageHandlers();

      // バックグラウンドメッセージハンドラーを設定
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 通知権限をリクエスト
  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// ローカル通知を初期化
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// FCMトークンを取得
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }

      // トークン更新をリッスン
      _messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      // トークン取得エラー
    }
  }

  /// FCMトークンをFirestoreに保存
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'devicePlatform': Platform.operatingSystem,
      });
    } catch (e) {
      // トークン保存エラー
    }
  }

  /// メッセージハンドラーをセットアップ
  void _setupMessageHandlers() {
    // フォアグラウンドメッセージ
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 通知タップ時（アプリが終了状態から起動）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // アプリ起動時の初期メッセージチェック
    _checkForInitialMessage();
  }

  /// フォアグラウンドメッセージを処理
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      // フォアグラウンドでもローカル通知を表示
      // これにより、アプリが開いている時でもバナー通知が表示される
      await _showLocalNotification(message);

      // バッジ数を更新
      await updateBadgeCount();
    } catch (e) {
      // フォアグラウンドメッセージ処理エラー
    }
  }

  /// バックグラウンドメッセージを処理
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    // バックグラウンドでのデータ処理のみ
    // 通知表示はOSが自動処理
  }

  /// 通知タップ時の処理
  void _handleNotificationTap(RemoteMessage message) {
    try {
      // 通知データに基づいて適切な画面に遷移
      _navigateBasedOnNotificationData(message.data);
    } catch (e) {
      // 通知タップ処理エラー
    }
  }

  /// ローカル通知応答時の処理
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        // ペイロードをパースして画面遷移
        _parsePayloadAndNavigate(response.payload!);
      }
    } catch (e) {
      // ローカル通知タップ処理エラー
    }
  }

  /// アプリ起動時の初期メッセージをチェック
  void _checkForInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// ローカル通知を表示
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'go_notifications',
        'Go Game Events',
        channelDescription: 'Game event management notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false, // バッジはAppBadgePlusで管理するため無効化
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = message.notification?.title ?? 'Go';
      final body = message.notification?.body ?? '';
      final payload = _createPayloadFromMessage(message);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      // ローカル通知表示エラー
    }
  }

  /// メッセージからペイロードを作成
  String _createPayloadFromMessage(RemoteMessage message) {
    try {
      return jsonEncode(message.data);
    } catch (e) {
      return '{}'; // 空のJSONを返す
    }
  }

  /// ペイロードをパースして画面遷移
  void _parsePayloadAndNavigate(String payload) {
    try {
      if (payload.isEmpty) {
        // 空の場合は通知画面に遷移
        NavigationService.instance.navigateToNotifications();
        return;
      }

      // JSON形式のペイロードをパース
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateBasedOnNotificationData(data);
    } catch (e) {
      // エラーの場合は通知画面に遷移
      NavigationService.instance.navigateToNotifications();
    }
  }

  /// 通知データに基づいて画面遷移
  void _navigateBasedOnNotificationData(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;

      switch (type) {
        case 'friendRequest':
        case 'friendAccepted':
        case 'friendRejected':
          // フレンド関連の通知は通知画面へ
          NavigationService.instance.navigateToNotifications();
          break;
        case 'eventInvite':
          // イベント招待は通知画面へ
          NavigationService.instance.navigateToNotifications();
          break;
        case 'eventApproved':
        case 'eventRejected':
          // イベント承認/拒否の場合、eventIdがあればイベント詳細画面へ
          final eventId = data['eventId'] as String?;
          if (eventId != null && eventId.isNotEmpty) {
            NavigationService.instance.navigateToEventDetail(eventId);
          } else {
            NavigationService.instance.navigateToNotifications();
          }
          break;
        case 'violationReported':
        case 'violationProcessed':
          // 違反報告関連は通知画面へ
          NavigationService.instance.navigateToNotifications();
          break;
        default:
          // デフォルトは通知画面へ
          NavigationService.instance.navigateToNotifications();
          break;
      }
    } catch (e) {
      // エラーの場合も通知画面へ
      NavigationService.instance.navigateToNotifications();
    }
  }

  /// バッジ数を更新
  Future<void> updateBadgeCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final unreadCount = await NotificationService.instance
          .getUnreadNotificationCount(user.uid);

      if (Platform.isIOS || Platform.isAndroid) {
        await AppBadgePlus.updateBadge(unreadCount);
      }
    } catch (e) {
      // バッジ更新エラー
    }
  }

  /// バッジをクリア
  Future<void> clearBadge() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await AppBadgePlus.updateBadge(0);
      }
    } catch (e) {
      // バッジクリアエラー
    }
  }

  /// プッシュ通知を送信（サーバーサイド用のヘルパー）
  static Future<bool> sendPushNotification({
    required String toUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // ユーザーのFCMトークンを取得
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        return false;
      }

      // TODO: 実際のプッシュ通知送信はFirebase Functionsまたは
      // サーバーサイドで実装する必要があります

      return true;
    } catch (e) {
      return false;
    }
  }

  /// テスト用ローカル通知表示
  Future<void> showTestLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'go_notifications',
        'Go Game Events',
        channelDescription: 'Game event management notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        autoCancel: true,
        ongoing: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false, // バッジはAppBadgePlusで管理するため無効化
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = data != null ? data.toString() : '';

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      // テスト通知表示エラー
    }
  }

  /// サービスをクリーンアップ
  void dispose() {
    _isInitialized = false;
  }
}
