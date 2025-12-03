import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/event_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/shared_game_repository.dart';
import 'image_upload_service.dart';
import 'notification_service.dart';

/// Firestoreイベント操作の例外クラス
class EventServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const EventServiceException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'EventServiceException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// イベント作成結果
class EventCreationResult {
  final String eventId;
  final String? imageUrl;
  final String? imagePath;

  const EventCreationResult({
    required this.eventId,
    this.imageUrl,
    this.imagePath,
  });
}

/// Firestoreイベントサービス
class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _eventsCollection = 'events';

  /// 招待制イベントの招待通知を送信
  static Future<void> sendEventInvitations({
    required String eventId,
    required String eventName,
    required List<String> invitedUserIds,
    required String createdByUserId,
  }) async {
    try {

      // 招待されたユーザーのデータを取得
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      final createdByName = currentUser.displayName ?? currentUser.email ?? 'ユーザー';

      // 各招待ユーザーに通知を送信
      for (final userId in invitedUserIds) {
        try {
          await NotificationService.instance.createNotification(
            NotificationData(
              toUserId: userId,
              fromUserId: createdByUserId,
              type: NotificationType.eventInvite,
              title: 'イベントに招待されました',
              message: '${createdByName}さんが「$eventName」に招待しました',
              isRead: false,
              createdAt: DateTime.now(),
              data: {
                'eventId': eventId,
                'eventName': eventName,
                'createdBy': createdByUserId,
                'createdByName': createdByName,
              },
            ),
          );
        } catch (e) {
          // 個別の送信失敗は続行
        }
      }

    } catch (e) {
      throw EventServiceException(
        'イベント招待の送信に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントを作成（画像アップロードを含む）
  static Future<EventCreationResult> createEvent({
    required EventInput eventInput,
    required String createdBy,
    File? imageFile,
    String? existingImageUrl,
    Function(double)? onUploadProgress,
  }) async {
    try {

      // Firebase Authentication の確認
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw EventServiceException('ユーザーが認証されていません');
      }


      // ドキュメント参照を作成（IDを事前生成）
      final eventRef = _firestore.collection(_eventsCollection).doc();
      final eventId = eventRef.id;

      String? imageUrl;
      String? imagePath;

      // 画像がある場合はアップロード、ない場合は既存画像URLを使用
      if (imageFile != null) {
        final imageResult = await ImageUploadService.uploadEventImage(
          imageFile,
          eventId,
          onProgress: onUploadProgress,
        );
        imageUrl = imageResult.downloadUrl;
        imagePath = imageResult.filePath;
      } else if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
        // 新規画像がない場合、既存の画像URLを使用（コピー時）
        imageUrl = existingImageUrl;
      }

      // イベントオブジェクトを作成
      final now = DateTime.now();

      // ゲーム名を取得
      final gameName = await _getGameNameById(eventInput.gameId);

      final event = Event(
        id: eventId,
        name: eventInput.name,
        subtitle: eventInput.subtitle,
        description: eventInput.description,
        rules: eventInput.rules,
        imageUrl: imageUrl,
        gameId: eventInput.gameId,
        gameName: gameName,
        platforms: eventInput.platforms,
        eventDate: eventInput.eventDate,
        registrationDeadline: eventInput.registrationDeadline,
        maxParticipants: eventInput.maxParticipants,
        additionalInfo: eventInput.additionalInfo,
        hasParticipationFee: eventInput.hasParticipationFee,
        participationFeeText: eventInput.participationFeeText,
        participationFeeSupplement: eventInput.participationFeeSupplement,
        hasPrize: eventInput.hasPrize,
        prizeContent: eventInput.prizeContent,
        sponsorIds: eventInput.sponsorIds,
        managerIds: eventInput.managerIds,
        blockedUserIds: eventInput.blockedUserIds,
        visibility: eventInput.visibility,
        eventTags: eventInput.eventTags,
        language: eventInput.language,
        contactInfo: eventInput.contactInfo,
        hasStreaming: eventInput.hasStreaming,
        streamingUrls: eventInput.streamingUrls,
        policy: eventInput.policy,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        participantIds: [], // 初期状態は空
        status: eventInput.status,
        eventPassword: eventInput.eventPassword,
        scheduledPublishAt: eventInput.scheduledPublishAt,
      );

      // Firestoreデータの準備と確認
      final eventData = event.toFirestore();

      // Firestoreに保存

      try {
        await eventRef.set(eventData);
      } catch (firestoreError) {
        rethrow;
      }


      return EventCreationResult(
        eventId: eventId,
        imageUrl: imageUrl,
        imagePath: imagePath,
      );
    } catch (e) {

      // 画像のクリーンアップ（エラー時）
      if (imageFile != null) {
        try {
          final eventRef = _firestore.collection(_eventsCollection).doc();
          final tempImageResult = await ImageUploadService.uploadEventImage(
            imageFile,
            eventRef.id,
          );
          await ImageUploadService.deleteImage(tempImageResult.filePath);
        } catch (cleanupError) {
        }
      }

      throw EventServiceException(
        'イベントの作成に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントを更新
  static Future<void> updateEvent({
    required String eventId,
    required EventInput eventInput,
    File? newImageFile,
    String? currentImagePath,
    Function(double)? onUploadProgress,
  }) async {
    try {

      final eventRef = _firestore.collection(_eventsCollection).doc(eventId);

      // 既存のイベントを取得
      final existingEvent = await getEventById(eventId);
      if (existingEvent == null) {
        throw EventServiceException('イベントが見つかりません');
      }

      String? imageUrl = existingEvent.imageUrl;
      String? imagePath = currentImagePath ?? existingEvent.imageUrl;

      // 新しい画像がある場合は処理
      if (newImageFile != null) {
        // 古い画像を削除
        if (currentImagePath != null && currentImagePath.isNotEmpty) {
          try {
            await ImageUploadService.deleteImage(currentImagePath);
          } catch (deleteError) {
          }
        }

        // 新しい画像をアップロード
        final imageResult = await ImageUploadService.uploadEventImage(
          newImageFile,
          eventId,
          onProgress: onUploadProgress,
        );
        imageUrl = imageResult.downloadUrl;
        imagePath = imageResult.filePath;
      }

      // 更新されたイベントオブジェクトを作成
      final updatedEvent = Event(
        id: existingEvent.id,
        name: eventInput.name,
        subtitle: eventInput.subtitle,
        description: eventInput.description,
        rules: eventInput.rules,
        imageUrl: imageUrl,
        gameId: eventInput.gameId,
        gameName: await _getGameNameById(eventInput.gameId),
        platforms: eventInput.platforms,
        eventDate: eventInput.eventDate,
        registrationDeadline: eventInput.registrationDeadline,
        maxParticipants: eventInput.maxParticipants,
        additionalInfo: eventInput.additionalInfo,
        hasParticipationFee: eventInput.hasParticipationFee,
        participationFeeText: eventInput.participationFeeText,
        hasPrize: eventInput.hasPrize,
        prizeContent: eventInput.prizeContent,
        sponsorIds: eventInput.sponsorIds,
        managerIds: eventInput.managerIds,
        blockedUserIds: eventInput.blockedUserIds,
        visibility: eventInput.visibility,
        eventTags: eventInput.eventTags,
        language: eventInput.language,
        contactInfo: eventInput.contactInfo,
        hasStreaming: eventInput.hasStreaming,
        streamingUrls: eventInput.streamingUrls,
        policy: eventInput.policy,
        createdBy: existingEvent.createdBy,
        createdAt: existingEvent.createdAt,
        updatedAt: DateTime.now(),
        participantIds: existingEvent.participantIds,
        status: existingEvent.status,
      );

      await eventRef.update(updatedEvent.toFirestore());
    } catch (e) {
      throw EventServiceException(
        'イベントの更新に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントステータスを更新
  static Future<void> updateEventStatus(String eventId, EventStatus status) async {
    try {

      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

    } catch (e) {
      throw EventServiceException(
        'イベントステータスの更新に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントをIDで取得
  static Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection(_eventsCollection).doc(eventId).get();

      if (!doc.exists) {
        return null;
      }

      final event = Event.fromFirestore(doc);
      return event;
    } catch (e) {
      throw EventServiceException(
        'イベントの取得に失敗しました',
        originalException: e,
      );
    }
  }

  /// ユーザーが作成したイベント一覧を取得
  static Future<List<Event>> getUserCreatedEvents(String userId, {int limit = 20}) async {
    try {

      final query = await _firestore
          .collection(_eventsCollection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final events = query.docs.map((doc) => Event.fromFirestore(doc)).toList();

      return events;
    } catch (e) {
      throw EventServiceException(
        'ユーザーのイベント一覧の取得に失敗しました',
        originalException: e,
      );
    }
  }

  /// 公開中のイベント一覧を取得（検索・一覧表示用）
  static Future<List<Event>> getPublicEvents({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    List<String>? platforms,
    List<String>? tags,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {

      Query query = _firestore
          .collection(_eventsCollection)
          .where('status', isEqualTo: 'published')
          .where('visibility', isEqualTo: 'public');

      // プラットフォームでフィルタ
      if (platforms != null && platforms.isNotEmpty) {
        query = query.where('platforms', arrayContainsAny: platforms);
      }

      // タグでフィルタ
      if (tags != null && tags.isNotEmpty) {
        query = query.where('eventTags', arrayContainsAny: tags);
      }

      // 日付範囲でフィルタ
      if (fromDate != null) {
        query = query.where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('eventDate', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      // ソートとページング
      query = query.orderBy('eventDate', descending: false);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      final events = querySnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      return events;
    } catch (e) {
      throw EventServiceException(
        '公開イベントの取得に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントを削除（画像も含む）
  static Future<void> deleteEvent(String eventId) async {
    try {

      // イベント情報を取得
      final event = await getEventById(eventId);
      if (event == null) {
        throw EventServiceException('削除対象のイベントが見つかりません');
      }

      // 関連する画像を削除
      if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        // Firebase StorageのパスからファイルパスToを推定
        final imagePath = _extractImagePathFromUrl(event.imageUrl!);
        if (imagePath != null) {
          try {
            await ImageUploadService.deleteImage(imagePath);
          } catch (imageError) {
          }
        }
      }

      // Firestoreドキュメントを削除
      await _firestore.collection(_eventsCollection).doc(eventId).delete();
    } catch (e) {
      throw EventServiceException(
        'イベントの削除に失敗しました',
        originalException: e,
      );
    }
  }

  /// ゲームIDからゲーム名を取得（SharedGameRepositoryから取得）
  static Future<String?> _getGameNameById(String? gameId) async {
    if (gameId == null || gameId.isEmpty) {
      return null;
    }

    try {
      final sharedGameRepository = SharedGameRepository();

      // SharedGameRepositoryから既存のゲームデータを検索
      final existingGame = await sharedGameRepository.findExistingGame(gameId);

      if (existingGame != null) {
        final gameName = existingGame.game.name;
        return gameName;
      } else {
        // SharedGameRepositoryにない場合は、gameIdをそのまま返す（将来的には取得・保存処理を追加）
        return 'Game ID: $gameId';
      }
    } catch (e) {
      // エラーが発生した場合もgameIdを返す
      return 'Game ID: $gameId';
    }
  }

  /// FirebaseStorageのURLからファイルパスを抽出
  static String? _extractImagePathFromUrl(String url) {
    try {
      // Firebase StorageのURLパターンから相対パスを抽出
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // URLパターン: /v0/b/{bucket}/o/{path}
      if (pathSegments.length >= 4 && pathSegments[2] == 'o') {
        return Uri.decodeComponent(pathSegments[3]);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 検索キーワードでイベントを検索（将来の機能）
  static Future<List<Event>> searchEvents({
    required String keyword,
    List<String>? platforms,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {

      // TODO: 将来的にはAlgolia等の検索エンジンと連携
      // 現在は基本的な検索を実装
      Query query = _firestore
          .collection(_eventsCollection)
          .where('status', isEqualTo: 'published')
          .where('visibility', isEqualTo: 'public');

      if (platforms != null && platforms.isNotEmpty) {
        query = query.where('platforms', arrayContainsAny: platforms);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('eventTags', arrayContainsAny: tags);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      final allEvents = querySnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

      // クライアントサイドでキーワード検索（暫定）
      final filteredEvents = allEvents.where((event) {
        final searchText = '${event.name} ${event.description} ${event.gameName ?? ''}'.toLowerCase();
        return searchText.contains(keyword.toLowerCase());
      }).toList();

      return filteredEvents;
    } catch (e) {
      throw EventServiceException(
        'イベントの検索に失敗しました',
        originalException: e,
      );
    }
  }

  /// ゲームIDに関連するイベント一覧を取得
  static Future<List<Event>> getEventsByGameId(String gameId, {int limit = 20}) async {
    try {

      final query = await _firestore
          .collection(_eventsCollection)
          .where('gameId', isEqualTo: gameId)
          .where('status', isEqualTo: 'published')
          .where('visibility', isEqualTo: 'public')
          .orderBy('eventDate', descending: false)
          .limit(limit)
          .get();

      final events = query.docs.map((doc) => Event.fromFirestore(doc)).toList();

      return events;
    } catch (e) {
      throw EventServiceException(
        'ゲーム関連イベントの取得に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントにリアルタイム監視を設定
  static Stream<Event?> watchEvent(String eventId) {
    return _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Event.fromFirestore(doc);
    });
  }

  /// 公開イベント一覧のリアルタイム監視
  static Stream<List<Event>> watchPublicEvents({
    List<String>? platforms,
    List<String>? tags,
    int limit = 20,
  }) {
    Query query = _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: 'published')
        .where('visibility', isEqualTo: 'public');

    if (platforms != null && platforms.isNotEmpty) {
      query = query.where('platforms', arrayContainsAny: platforms);
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('eventTags', arrayContainsAny: tags);
    }

    return query
        .orderBy('eventDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  /// イベントのパスワードを検証し、参加申請を送信
  static Future<bool> submitEventJoinRequest({
    required String eventId,
    required String password,
    required String userId,
  }) async {
    try {

      // イベントデータを取得
      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) {
        throw EventServiceException('イベントが見つかりません');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final storedPassword = eventData['eventPassword'] as String?;

      // パスワード検証
      if (storedPassword == null || storedPassword != password) {
        throw EventServiceException('パスワードが正しくありません');
      }

      // 既に参加申請済みかチェック
      final participantsDoc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .collection('participants')
          .doc(userId)
          .get();

      if (participantsDoc.exists) {
        final participantData = participantsDoc.data() as Map<String, dynamic>;
        final status = participantData['status'] as String?;
        if (status == 'pending' || status == 'approved') {
          throw EventServiceException('既に参加申請済みです');
        }
      }

      // 参加申請を保存
      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .collection('participants')
          .doc(userId)
          .set({
        'userId': userId,
        'status': 'pending', // pending, approved, rejected
        'appliedAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'rejectedAt': null,
        'approvedBy': null,
        'rejectedBy': null,
      });

      return true;
    } catch (e) {
      if (e is EventServiceException) {
        rethrow;
      }
      throw EventServiceException(
        '参加申請の送信に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベント参加申請を承認
  static Future<bool> approveJoinRequest({
    required String eventId,
    required String userId,
    required String approvedBy,
  }) async {
    try {

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .collection('participants')
          .doc(userId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': approvedBy,
      });

      // 承認通知を送信
      await _sendJoinRequestStatusNotification(
        eventId: eventId,
        userId: userId,
        status: 'approved',
      );

      return true;
    } catch (e) {
      throw EventServiceException(
        '参加申請の承認に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベント参加申請を拒否
  static Future<bool> rejectJoinRequest({
    required String eventId,
    required String userId,
    required String rejectedBy,
  }) async {
    try {

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .collection('participants')
          .doc(userId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': rejectedBy,
      });

      // 拒否通知を送信
      await _sendJoinRequestStatusNotification(
        eventId: eventId,
        userId: userId,
        status: 'rejected',
      );

      return true;
    } catch (e) {
      throw EventServiceException(
        '参加申請の拒否に失敗しました',
        originalException: e,
      );
    }
  }

  /// イベントの参加申請一覧を取得
  static Stream<List<Map<String, dynamic>>> getJoinRequestsStream(String eventId) {
    return _firestore
        .collection(_eventsCollection)
        .doc(eventId)
        .collection('participants')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// 参加申請状況の通知を送信
  static Future<void> _sendJoinRequestStatusNotification({
    required String eventId,
    required String userId,
    required String status,
  }) async {
    try {
      // イベント情報を取得
      final eventDoc = await _firestore.collection(_eventsCollection).doc(eventId).get();
      if (!eventDoc.exists) return;

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final eventName = eventData['name'] as String;

      String title, message;
      if (status == 'approved') {
        title = 'イベント参加が承認されました';
        message = '「$eventName」への参加申請が承認されました';
      } else {
        title = 'イベント参加が拒否されました';
        message = '「$eventName」への参加申請が拒否されました';
      }

      // 通知を作成
      await NotificationService.instance.createNotification(
        NotificationData(
          toUserId: userId,
          fromUserId: null, // システム通知
          type: NotificationType.system,
          title: title,
          message: message,
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': eventId,
            'eventName': eventName,
            'status': status,
          },
        ),
      );
    } catch (e) {
      // 通知送信失敗は非致命的
    }
  }
}