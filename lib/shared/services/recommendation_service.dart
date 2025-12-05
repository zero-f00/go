import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../../data/models/user_model.dart';
import '../../data/models/event_model.dart';
import '../utils/event_converter.dart';
import 'event_filter_service.dart';

/// パーソナライズされたイベントレコメンデーションサービス
class RecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーのお気に入りゲームに基づくおすすめイベントを取得
  static Stream<List<GameEvent>> getRecommendedEvents(String firebaseUid) async* {
    try {
      // 空のuidまたは未認証ユーザーの場合は人気イベントを返す
      if (firebaseUid.isEmpty) {
        yield* _getPopularEvents();
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        yield* _getPopularEvents();
        return;
      }

      // ユーザードキュメントの読み取りを試行
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUid).get();

        // ユーザードキュメントが存在しない場合は人気イベントを返す
        if (!userDoc.exists) {
          yield* _getPopularEvents();
          return;
        }

        final userData = UserData.fromFirestore(userDoc);
        final favoriteGameIds = userData.favoriteGameIds;

        // お気に入りゲームが登録されていない場合は人気イベントを返す
        if (favoriteGameIds.isEmpty) {
          yield* _getPopularEvents();
          return;
        }

        // お気に入りゲームに基づくイベントを取得
        yield* _getFavoriteGameEvents(favoriteGameIds);
      } catch (userDocError) {
        // ユーザードキュメント読み取りエラーの場合は人気イベントにフォールバック
        yield* _getPopularEvents();
      }
    } catch (e, stackTrace) {
      // 全体的なエラーの場合は人気イベントにフォールバック
      yield* _getPopularEvents();
    }
  }


  /// フレンドが主催または参加しているイベントを取得
  static Stream<List<GameEvent>> getFriendEvents(String userId) async* {
    try {
      // フレンドリストを取得
      final friendsSnapshot = await _firestore
          .collection('friendships')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final friendIds = friendsSnapshot.docs
          .map((doc) => doc.data()['friendId'] as String)
          .toList();

      if (friendIds.isEmpty) {
        yield [];
        return;
      }

      // フレンドが主催しているイベント
      final hostedEventsQuery = _firestore
          .collection('events')
          .where('createdBy', whereIn: friendIds)
          .where('status', whereIn: ['published', 'scheduled'])
          .orderBy('eventDate', descending: false)
          .limit(10);

      // フレンドが参加しているイベント
      final participatingEventsQuery = _firestore
          .collection('events')
          .where('participantIds', arrayContainsAny: friendIds)
          .where('status', whereIn: ['published', 'scheduled'])
          .orderBy('eventDate', descending: false)
          .limit(10);

      final hostedEvents = await hostedEventsQuery.get();
      final participatingEvents = await participatingEventsQuery.get();

      final allEvents = <GameEvent>[];
      final eventIds = <String>{};

      // 重複を避けてイベントを統合
      for (final doc in hostedEvents.docs) {
        if (!eventIds.contains(doc.id)) {
          final event = Event.fromFirestore(doc);
          final gameEvent = await EventConverter.eventToGameEvent(event);
          allEvents.add(gameEvent);
          eventIds.add(doc.id);
        }
      }

      for (final doc in participatingEvents.docs) {
        if (!eventIds.contains(doc.id)) {
          final event = Event.fromFirestore(doc);
          final gameEvent = await EventConverter.eventToGameEvent(event);
          allEvents.add(gameEvent);
          eventIds.add(doc.id);
        }
      }

      // 開催日時順にソート
      allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // NGユーザーのイベントを除外
      final filteredEvents = EventFilterService.filterBlockedUserEvents(allEvents, userId);
      yield filteredEvents;
    } catch (e) {
      yield [];
    }
  }

  /// お気に入りゲームに関連するイベントを取得
  static Stream<List<GameEvent>> _getFavoriteGameEvents(List<String> gameIds) async* {
    try {

      // eventsコレクションとgameEventsコレクションの両方から検索
      final eventsQuery = _firestore
          .collection('events')
          .where('gameId', whereIn: gameIds)
          .limit(15);

      final gameEventsQuery = _firestore
          .collection('gameEvents')
          .where('gameId', whereIn: gameIds)
          .limit(15);


      yield* eventsQuery.snapshots().asyncMap((eventsSnapshot) async {
        // gameEventsコレクションからも取得
        final gameEventsSnapshot = await gameEventsQuery.get();

        final currentUser = FirebaseAuth.instance.currentUser;
        final currentUserId = currentUser?.uid;
        final now = DateTime.now();

        final events = <GameEvent>[];
        final eventIds = <String>{};

        // eventsコレクションからの処理
        for (final doc in eventsSnapshot.docs) {
          try {
            final data = doc.data();

            // 重複チェック
            if (eventIds.contains(doc.id)) {
              continue;
            }

            // 1. 自分が作成者のイベントは除外
            if (currentUserId != null && data['createdBy'] == currentUserId) {
              continue;
            }

            // 2. 自分が管理者のイベントは除外
            final managerIds = data['managerIds'] as List?;
            if (currentUserId != null && managerIds != null && managerIds.contains(currentUserId)) {
              continue;
            }

            // 3. 申込期限が過ぎているイベントは除外
            final registrationDeadline = (data['registrationDeadline'] as Timestamp?)?.toDate();
            if (registrationDeadline != null && registrationDeadline.isBefore(now)) {
              continue;
            }

            // 4. イベント開始時刻が過ぎているイベントも除外
            final startDate = (data['startDate'] as Timestamp?)?.toDate();
            if (startDate != null && startDate.isBefore(now)) {
              continue;
            }

            if (data['status'] == 'published' && data['visibility'] == 'public') {
              final event = Event.fromFirestore(doc);
              final gameEvent = await EventConverter.eventToGameEvent(event);
              events.add(gameEvent);
              eventIds.add(doc.id);
            } else {
            }
          } catch (e) {
          }
        }

        // gameEventsコレクションからの処理
        for (final doc in gameEventsSnapshot.docs) {
          try {
            final data = doc.data();

            // 重複チェック
            if (eventIds.contains(doc.id)) {
              continue;
            }

            // 1. 自分が作成者のイベントは除外
            if (currentUserId != null && data['createdBy'] == currentUserId) {
              continue;
            }

            // 2. 自分が管理者のイベントは除外
            final managerIds = data['managers'] as List?;
            if (currentUserId != null && managerIds != null && managerIds.contains(currentUserId)) {
              continue;
            }

            // 3. 申込期限が過ぎているイベントは除外（gameEventsの場合はregistrationDeadlineフィールド名を確認）
            final registrationDeadline = (data['registrationDeadline'] as Timestamp?)?.toDate();
            if (registrationDeadline != null && registrationDeadline.isBefore(now)) {
              continue;
            }

            // 4. イベント開始時刻が過ぎているイベントも除外
            final startDate = (data['startDate'] as Timestamp?)?.toDate();
            if (startDate != null && startDate.isBefore(now)) {
              continue;
            }

            if (data['status'] == 'active') {
              final gameEvent = GameEvent.fromFirestore(data, doc.id);
              events.add(gameEvent);
              eventIds.add(doc.id);
            } else {
            }
          } catch (e) {
          }
        }


        // 開催日時順にソート
        events.sort((a, b) => a.startDate.compareTo(b.startDate));

        // NGユーザーのイベントを除外
        final filteredEvents = EventFilterService.filterBlockedUserEvents(events, currentUserId);

        return filteredEvents;
      });
    } catch (e, stackTrace) {
      yield [];
    }
  }

  /// 人気のイベントを取得（お気に入りゲームが設定されていない場合のフォールバック）
  static Stream<List<GameEvent>> _getPopularEvents() async* {
    try {
      // 認証状態を確認（ゲストユーザーでも利用可能）
      final currentUser = FirebaseAuth.instance.currentUser;

      // まずシンプルなクエリで権限テストを実行
      try {
        final testQuery = await _firestore.collection('events').limit(1).get();
        // テストクエリが成功した場合は続行
      } catch (testError) {
        // 権限エラーの場合は空のリストを返す
        yield [];
        return;
      }

      // メインのイベント取得クエリ
      final eventsQuery = _firestore
          .collection('events')
          .where('status', whereIn: ['published', 'scheduled'])
          .where('visibility', isEqualTo: 'public')
          .limit(10);

      yield* eventsQuery.snapshots().handleError((error) {
        // エラーハンドリング: 空のリストを返すため
        return Stream.value(<GameEvent>[]);
      }).asyncMap((snapshot) async {
        try {
          final currentUserId = currentUser?.uid;
          final now = DateTime.now();
          final events = <GameEvent>[];

          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();

              // 1. 自分が作成者のイベントは除外（認証済みユーザーのみ）
              if (currentUserId != null && data['createdBy'] == currentUserId) {
                continue;
              }

              // 2. 自分が管理者のイベントは除外（認証済みユーザーのみ）
              final managerIds = data['managerIds'] as List?;
              if (currentUserId != null && managerIds != null && managerIds.contains(currentUserId)) {
                continue;
              }

              // 3. 申込期限が過ぎているイベントは除外
              final registrationDeadline = (data['registrationDeadline'] as Timestamp?)?.toDate();
              if (registrationDeadline != null && registrationDeadline.isBefore(now)) {
                continue;
              }

              // 4. イベント開始時刻が過ぎているイベントも除外
              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              if (startDate != null && startDate.isBefore(now)) {
                continue;
              }

              // 公開イベントのみを処理
              if (data['status'] == 'published' && data['visibility'] == 'public') {
                final event = Event.fromFirestore(doc);
                final gameEvent = await EventConverter.eventToGameEvent(event);
                events.add(gameEvent);
              }
            } catch (e) {
              // 個別イベントの処理エラーは無視して続行
              continue;
            }
          }

          // NGユーザーのイベントを除外（認証済みユーザーのみ）
          final filteredEvents = currentUserId != null
              ? EventFilterService.filterBlockedUserEvents(events, currentUserId)
              : events;

          return filteredEvents;
        } catch (e) {
          // 処理中にエラーが発生した場合は空のリストを返す
          return <GameEvent>[];
        }
      });
    } catch (e, stackTrace) {
      // 全体的なエラーの場合は空のリストを返す
      yield [];
    }
  }

  /// 「もっと見る」画面用のおすすめイベント（多めに取得）
  static Stream<List<GameEvent>> getMoreRecommendedEvents(String userId) async* {
    try {
      // ユーザーIDが空の場合は人気のイベントのみを返す
      if (userId.isEmpty) {
        yield* _getPopularEvents();
        return;
      }

      // お気に入りゲームのイベントを多めに取得
      final favoriteGameEventsStream = _getFavoriteGameEventsForMore(userId);

      await for (final favoriteEvents in favoriteGameEventsStream) {
        yield favoriteEvents;
        return; // 最初のストリームデータのみ使用
      }
    } catch (e) {
      yield [];
    }
  }

  /// 「もっと見る」用のお気に入りゲームイベント取得（多めに取得）
  static Stream<List<GameEvent>> _getFavoriteGameEventsForMore(String gameIds) async* {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userDoc = await _firestore.collection('users').doc(gameIds).get();

      if (!userDoc.exists) {
        yield* _getPopularEvents();
        return;
      }

      final userData = UserData.fromFirestore(userDoc);
      final favoriteGameIds = userData.favoriteGameIds;

      if (favoriteGameIds.isEmpty) {
        yield* _getPopularEvents();
        return;
      }

      // より多くのイベントを取得
      final eventsQuery = _firestore
          .collection('events')
          .where('gameId', whereIn: favoriteGameIds)
          .limit(50); // より多くのイベントを取得

      yield* eventsQuery.snapshots().asyncMap((snapshot) async {
        final currentUserId = currentUser?.uid;
        final now = DateTime.now();

        final events = <GameEvent>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();

          // 自分が作成したイベントは除外
          if (currentUserId != null && data['createdBy'] == currentUserId) {
            continue;
          }

          // 参加申し込み締切が過ぎているイベントは除外
          final registrationDeadline = (data['registrationDeadline'] as Timestamp?)?.toDate();
          if (registrationDeadline != null && registrationDeadline.isBefore(now)) {
            continue;
          }

          // イベント開始時刻が過ぎているイベントも除外
          final startDate = (data['startDate'] as Timestamp?)?.toDate();
          if (startDate != null && startDate.isBefore(now)) {
            continue;
          }

          if (data['status'] == 'published' || data['status'] == 'scheduled') {
            final event = Event.fromFirestore(doc);
            final gameEvent = await EventConverter.eventToGameEvent(event);
            events.add(gameEvent);
          }
        }

        // 開催日時順にソート
        events.sort((a, b) => a.startDate.compareTo(b.startDate));

        // NGユーザーのイベントを除外
        final filteredEvents = EventFilterService.filterBlockedUserEvents(events, currentUserId);
        return filteredEvents;
      });
    } catch (e) {
      yield [];
    }
  }

  /// 複合的なおすすめイベントを取得（お気に入りゲーム + フレンドのイベント）
  static Stream<List<GameEvent>> getCombinedRecommendations(String userId) async* {
    try {
      // ユーザーIDが空の場合は人気のイベントのみを返す
      if (userId.isEmpty) {
        yield* _getPopularEvents();
        return;
      }

      final favoriteGameEventsStream = getRecommendedEvents(userId);
      final friendEventsStream = getFriendEvents(userId);

      await for (final favoriteEvents in favoriteGameEventsStream) {
        await for (final friendEvents in friendEventsStream) {
          final combinedEvents = <GameEvent>[];
          final eventIds = <String>{};

          // フレンドのイベントを優先で追加
          for (final event in friendEvents.take(5)) {
            if (!eventIds.contains(event.id)) {
              combinedEvents.add(event);
              eventIds.add(event.id);
            }
          }

          // お気に入りゲームのイベントを追加
          for (final event in favoriteEvents.take(10)) {
            if (!eventIds.contains(event.id) && combinedEvents.length < 15) {
              combinedEvents.add(event);
              eventIds.add(event.id);
            }
          }

          // 開催日時順にソート
          combinedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

          yield combinedEvents;
          return; // 最初のストリームデータのみ使用
        }
        return; // 最初のストリームデータのみ使用
      }
    } catch (e) {
      yield [];
    }
  }

  /// ユーザーが運営するイベントを取得（作成者または管理者）
  /// includeCompletedがtrueの場合、終了したイベントも含める
  static Stream<List<GameEvent>> getManagedEvents(String firebaseUid, {bool includeCompleted = false}) async* {
    try {

      if (firebaseUid.isEmpty) {
        yield [];
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        yield [];
        return;
      }


      // eventsコレクションとgameEventsコレクションの両方から取得
      final eventsQuery = _firestore
          .collection('events')
          .where('createdBy', isEqualTo: firebaseUid)
          .orderBy('startDate', descending: false);

      final managersQuery = _firestore
          .collection('events')
          .where('managerIds', arrayContains: firebaseUid)
          .orderBy('startDate', descending: false);

      final gameEventsQuery = _firestore
          .collection('gameEvents')
          .where('createdBy', isEqualTo: firebaseUid)
          .orderBy('startDate', descending: false);

      yield* eventsQuery.snapshots().asyncMap((snapshot) async {

        final now = DateTime.now();
        final events = <GameEvent>[];
        final eventIds = <String>{};

        // 作成者として作成したイベント
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();

            // includeCompletedがfalseの場合、未来のイベントのみを対象とする
            final startDate = (data['startDate'] as Timestamp?)?.toDate();

            if (includeCompleted || (startDate != null && startDate.isAfter(now.subtract(const Duration(hours: 24))))) {
              final event = Event.fromFirestore(doc);
              final gameEvent = await EventConverter.eventToGameEvent(event);

              if (!eventIds.contains(gameEvent.id)) {
                events.add(gameEvent);
                eventIds.add(gameEvent.id);
              } else {
              }
            } else {
            }
          } catch (e) {
          }
        }

        // 管理者として参加しているイベント
        try {
          final managersSnapshot = await managersQuery.get();
          for (final doc in managersSnapshot.docs) {
            try {
              final data = doc.data();

              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              if (includeCompleted || (startDate != null && startDate.isAfter(now.subtract(const Duration(hours: 24))))) {
                final event = Event.fromFirestore(doc);
                final gameEvent = await EventConverter.eventToGameEvent(event);

                if (!eventIds.contains(gameEvent.id)) {
                  events.add(gameEvent);
                  eventIds.add(gameEvent.id);
                }
              }
            } catch (e) {
              // エラーは無視して続行
            }
          }
        } catch (e) {
          // 管理者クエリエラーは無視
        }

        // gameEventsコレクションからも取得
        try {
          final gameEventsSnapshot = await gameEventsQuery.get();

          for (final doc in gameEventsSnapshot.docs) {
            try {
              final data = doc.data();

              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              if (includeCompleted || (startDate != null && startDate.isAfter(now.subtract(const Duration(hours: 24))))) {
                final gameEvent = GameEvent.fromFirestore(data, doc.id);

                if (!eventIds.contains(gameEvent.id)) {
                  events.add(gameEvent);
                  eventIds.add(gameEvent.id);
                }
              }
            } catch (e) {
            }
          }
        } catch (e) {
        }

        // 開催日時順にソート
        events.sort((a, b) => a.startDate.compareTo(b.startDate));

        for (final event in events) {
        }

        return events;
      });
    } catch (e) {
      yield [];
    }
  }
}

/// RecommendationServiceのプロバイダー
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

/// おすすめイベントプロバイダー
final recommendedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, firebaseUid) {
  try {
    final stream = RecommendationService.getRecommendedEvents(firebaseUid);
    return stream;
  } catch (e, stackTrace) {
    rethrow;
  }
});

/// フレンドイベントプロバイダー
final friendEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return RecommendationService.getFriendEvents(userId);
});

/// 運営者イベントプロバイダー（ユーザーが運営するイベント）
final managedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, firebaseUid) {
  return RecommendationService.getManagedEvents(firebaseUid);
});

/// 運営者イベント全件プロバイダー（終了したイベントも含む）
final allManagedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, firebaseUid) {
  return RecommendationService.getManagedEvents(firebaseUid, includeCompleted: true);
});