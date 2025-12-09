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

      print('🔔 PushNotificationService: Initializing...');

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
      print('✅ PushNotificationService: Initialization completed');

      // 初期化完了後に再度FCMトークンを表示
      if (_fcmToken != null) {
        print('🎯 FCM TOKEN FOR FIREBASE CONSOLE TEST:');
        print(_fcmToken!);
        print('🎯 END TOKEN');
      }

      return true;
    } catch (e) {
      print('❌ PushNotificationService: Initialization failed: $e');
      return false;
    }
  }

  /// 通知権限をリクエスト
  Future<void> _requestPermissions() async {
    print('🔔 PushNotificationService: Requesting permissions...');

    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print(
      '🔔 PushNotificationService: Permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ PushNotificationService: Permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ PushNotificationService: Provisional permissions granted');
    } else {
      print('❌ PushNotificationService: Permissions denied');
    }
  }

  /// ローカル通知を初期化
  Future<void> _initializeLocalNotifications() async {
    print('🔔 PushNotificationService: Initializing local notifications...');

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

    print('✅ PushNotificationService: Local notifications initialized');
  }

  /// FCMトークンを取得
  Future<void> _getFCMToken() async {
    try {
      print('🔔 PushNotificationService: Getting FCM token...');

      _fcmToken = await _messaging.getToken();

      if (_fcmToken != null) {
        print(
          '✅ PushNotificationService: FCM token obtained: ${_fcmToken!.substring(0, 20)}...',
        );
        print('📋 Complete FCM Token for testing: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      } else {
        print('❌ PushNotificationService: Failed to get FCM token');
      }

      // トークン更新をリッスン
      _messaging.onTokenRefresh.listen((newToken) async {
        print('🔄 PushNotificationService: FCM token refreshed');
        _fcmToken = newToken;
        await _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      print('❌ PushNotificationService: Error getting FCM token: $e');
    }
  }

  /// FCMトークンをFirestoreに保存
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          '⚠️ PushNotificationService: No authenticated user, skipping token save',
        );
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'devicePlatform': Platform.operatingSystem,
      });

      print('✅ PushNotificationService: FCM token saved to Firestore');
    } catch (e) {
      print('❌ PushNotificationService: Error saving FCM token: $e');
    }
  }

  /// メッセージハンドラーをセットアップ
  void _setupMessageHandlers() {
    print('🔔 PushNotificationService: Setting up message handlers...');

    // フォアグラウンドメッセージ
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 通知タップ時（アプリが終了状態から起動）
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // アプリ起動時の初期メッセージチェック
    _checkForInitialMessage();

    print('✅ PushNotificationService: Message handlers setup completed');
  }

  /// フォアグラウンドメッセージを処理
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      print('📱 PushNotificationService: Foreground message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      // フォアグラウンドでもローカル通知を表示
      // これにより、アプリが開いている時でもバナー通知が表示される
      await _showLocalNotification(message);

      // バッジ数を更新
      await updateBadgeCount();

      print('✅ PushNotificationService: Foreground notification displayed');
    } catch (e) {
      print('❌ PushNotificationService: Error handling foreground message: $e');
    }
  }

  /// バックグラウンドメッセージを処理
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('📱 PushNotificationService: Background message received');
      print('   Title: ${message.notification?.title}');
      print('   Body: ${message.notification?.body}');
      print('   Data: ${message.data}');

      // バックグラウンドでのデータ処理のみ
      // 通知表示はOSが自動処理
    } catch (e) {
      print('❌ PushNotificationService: Error handling background message: $e');
    }
  }

  /// 通知タップ時の処理
  void _handleNotificationTap(RemoteMessage message) {
    try {
      print('👆 PushNotificationService: Notification tapped');
      print('   Data: ${message.data}');

      // 通知データに基づいて適切な画面に遷移
      _navigateBasedOnNotificationData(message.data);
    } catch (e) {
      print('❌ PushNotificationService: Error handling notification tap: $e');
    }
  }

  /// ローカル通知応答時の処理
  void _onNotificationTapped(NotificationResponse response) {
    try {
      print('👆 PushNotificationService: Local notification tapped');
      print('   Payload: ${response.payload}');

      if (response.payload != null) {
        // ペイロードをパースして画面遷移
        _parsePayloadAndNavigate(response.payload!);
      }
    } catch (e) {
      print('❌ PushNotificationService: Error handling notification tap: $e');
    }
  }

  /// アプリ起動時の初期メッセージをチェック
  void _checkForInitialMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 PushNotificationService: App launched from notification');
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
        presentBadge: true,
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

      print('✅ PushNotificationService: Local notification displayed');
    } catch (e) {
      print('❌ PushNotificationService: Error showing local notification: $e');
    }
  }

  /// メッセージからペイロードを作成
  String _createPayloadFromMessage(RemoteMessage message) {
    try {
      return jsonEncode(message.data);
    } catch (e) {
      print('❌ PushNotificationService: Error creating payload: $e');
      return '{}'; // 空のJSONを返す
    }
  }

  /// ペイロードをパースして画面遷移
  void _parsePayloadAndNavigate(String payload) {
    try {
      print('🔍 PushNotificationService: Parsing payload for navigation: $payload');

      if (payload.isEmpty) {
        // 空の場合は通知画面に遷移
        NavigationService.instance.navigateToNotifications();
        return;
      }

      // JSON形式のペイロードをパース
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigateBasedOnNotificationData(data);
    } catch (e) {
      print('❌ PushNotificationService: Error parsing payload: $e');
      // エラーの場合は通知画面に遷移
      NavigationService.instance.navigateToNotifications();
    }
  }

  /// 通知データに基づいて画面遷移
  void _navigateBasedOnNotificationData(Map<String, dynamic> data) {
    try {
      final type = data['type'] as String?;
      print('🔍 PushNotificationService: Navigating based on type: $type');

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
      print('❌ PushNotificationService: Error navigating: $e');
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
        print('✅ PushNotificationService: Badge count updated: $unreadCount');
      }
    } catch (e) {
      print('❌ PushNotificationService: Error updating badge count: $e');
    }
  }

  /// バッジをクリア
  Future<void> clearBadge() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await AppBadgePlus.updateBadge(0);
        print('✅ PushNotificationService: Badge cleared');
      }
    } catch (e) {
      print('❌ PushNotificationService: Error clearing badge: $e');
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
        print('❌ PushNotificationService: User document not found');
        return false;
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        print('❌ PushNotificationService: FCM token not found for user');
        return false;
      }

      // TODO: 実際のプッシュ通知送信はFirebase Functionsまたは
      // サーバーサイドで実装する必要があります
      print('📤 PushNotificationService: Push notification request prepared');
      print('   Token: ${fcmToken.substring(0, 20)}...');
      print('   Title: $title');
      print('   Body: $body');
      print('   Data: $data');
      print('🎯 COMPLETE FCM TOKEN FOR FIREBASE CONSOLE:');
      print(fcmToken);
      print('🎯 END TOKEN - Copy this for Firebase Console test');

      return true;
    } catch (e) {
      print('❌ PushNotificationService: Error sending push notification: $e');
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
      print('🔔 PushNotificationService: Showing test local notification');

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
        presentBadge: true,
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

      print('✅ PushNotificationService: Test local notification displayed');
    } catch (e) {
      print('❌ PushNotificationService: Error showing test local notification: $e');
    }
  }

  /// サービスをクリーンアップ
  void dispose() {
    print('🧹 PushNotificationService: Disposing...');
    _isInitialized = false;
  }
}
