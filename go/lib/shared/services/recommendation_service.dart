import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../../data/models/user_model.dart';
import '../../data/models/event_model.dart';
import '../utils/event_converter.dart';

/// パーソナライズされたイベントレコメンデーションサービス
class RecommendationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーのお気に入りゲームに基づくおすすめイベントを取得
  static Stream<List<GameEvent>> getRecommendedEvents(String firebaseUid) async* {
    try {
      print('🔍 RecommendationService: Getting recommended events for Firebase UID: $firebaseUid');

      // 権限デバッグ: 認証状態を確認
      print('🔐 RecommendationService: Checking auth state for Firestore access');

      // Firebase Auth の現在の状態を確認
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔐 RecommendationService: Current Firebase Auth user: ${currentUser?.uid}');
      print('🔐 RecommendationService: Is authenticated: ${currentUser != null}');
      print('🔐 RecommendationService: Is anonymous: ${currentUser?.isAnonymous}');

      if (currentUser == null) {
        print('❌ RecommendationService: User not authenticated, falling back to popular events');
        yield* _getPopularEvents();
        return;
      }

      // Firebase UIDを使ってユーザー情報を取得
      final userDoc = await _firestore.collection('users').doc(firebaseUid).get();
      if (!userDoc.exists) {
        print('❌ RecommendationService: User document does not exist for Firebase UID: $firebaseUid');
        print('⚠️ RecommendationService: User needs to complete onboarding before getting recommendations');
        print('⚠️ RecommendationService: Falling back to popular events due to missing user document');
        yield* _getPopularEvents();
        return;
      }

      final userData = UserData.fromFirestore(userDoc);
      final favoriteGameIds = userData.favoriteGameIds;
      print('🎮 RecommendationService: User favorite game IDs: $favoriteGameIds');

      if (favoriteGameIds.isEmpty) {
        print('⚠️ RecommendationService: No favorite games set, falling back to popular events');
        // お気に入りゲームが設定されていない場合は人気のイベントを返す
        yield* _getPopularEvents();
        return;
      }

      print('🔍 RecommendationService: Searching for events with favorite game IDs');
      // お気に入りゲームに関連するイベントを取得
      yield* _getFavoriteGameEvents(favoriteGameIds);
    } on FirebaseException catch (e) {
      print('❌ RecommendationService Firebase Error: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        print('🔒 Permission denied when accessing users collection. Checking Firestore rules.');
        print('🔍 Attempted to access: users/$firebaseUid');
      }
      // 権限エラーの場合は人気イベントにフォールバック
      yield* _getPopularEvents();
    } catch (e) {
      print('❌ RecommendationService General Error: $e');
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

      yield allEvents;
    } catch (e) {
      print('RecommendationService Error in getFriendEvents: $e');
      yield [];
    }
  }

  /// お気に入りゲームに関連するイベントを取得
  static Stream<List<GameEvent>> _getFavoriteGameEvents(List<String> gameIds) async* {
    try {
      print('🔎 _getFavoriteGameEvents: Searching for events with gameIds: $gameIds');

      // まず、単純にgameIdだけで検索してみる
      final eventsQuery = _firestore
          .collection('events')
          .where('gameId', whereIn: gameIds)
          .limit(15);

      yield* eventsQuery.snapshots().asyncMap((snapshot) async {
        print('📊 _getFavoriteGameEvents: Found ${snapshot.docs.length} documents matching query');

        final events = <GameEvent>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          print('📄 Document: ${doc.id}, gameId: ${data['gameId']}, status: ${data['status']}, name: ${data['name']}');

          // ステータスが published または scheduled のもののみを処理
          if (data['status'] == 'published' || data['status'] == 'scheduled') {
            final event = Event.fromFirestore(doc);
            final gameEvent = await EventConverter.eventToGameEvent(event);
            events.add(gameEvent);
            print('✅ Added event: ${gameEvent.name}');
          } else {
            print('⏭️ Skipped event with status: ${data['status']}');
          }
        }

        print('✅ _getFavoriteGameEvents: Successfully converted ${events.length} events');

        // 開催日時順にソート
        events.sort((a, b) => a.startDate.compareTo(b.startDate));
        return events;
      });
    } catch (e) {
      print('❌ RecommendationService Error in _getFavoriteGameEvents: $e');
      yield [];
    }
  }

  /// 人気のイベントを取得（お気に入りゲームが設定されていない場合のフォールバック）
  static Stream<List<GameEvent>> _getPopularEvents() async* {
    try {
      print('🔥 _getPopularEvents: Getting popular events as fallback');

      // 認証状態を再確認
      final currentUser = FirebaseAuth.instance.currentUser;
      print('🔐 _getPopularEvents: Current user: ${currentUser?.uid}');
      print('🔐 _getPopularEvents: Is authenticated: ${currentUser != null}');

      if (currentUser == null) {
        print('❌ _getPopularEvents: User not authenticated, returning empty list');
        yield [];
        return;
      }

      print('🔍 _getPopularEvents: Creating Firestore query for events collection');
      final eventsQuery = _firestore
          .collection('events')
          .where('status', whereIn: ['published', 'scheduled'])
          .limit(10);

      print('🔍 _getPopularEvents: Executing query...');

      yield* eventsQuery.snapshots().asyncMap((snapshot) async {
        print('📊 _getPopularEvents: Found ${snapshot.docs.length} popular events');

        final events = <GameEvent>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          print('📄 Popular Event: ${doc.id}, status: ${data['status']}, name: ${data['name']}, participants: ${data['participantCount']}');

          // ステータスが published または scheduled のもののみを処理
          if (data['status'] == 'published' || data['status'] == 'scheduled') {
            final event = Event.fromFirestore(doc);
            final gameEvent = await EventConverter.eventToGameEvent(event);
            events.add(gameEvent);
            print('✅ Added popular event: ${gameEvent.name}');
          } else {
            print('⏭️ Skipped popular event with status: ${data['status']}');
          }
        }

        print('✅ _getPopularEvents: Successfully converted ${events.length} popular events');
        return events;
      });
    } catch (e) {
      print('❌ RecommendationService Error in _getPopularEvents: $e');
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
      print('RecommendationService Error in getCombinedRecommendations: $e');
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
  return RecommendationService.getRecommendedEvents(firebaseUid);
});

/// フレンドイベントプロバイダー
final friendEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return RecommendationService.getFriendEvents(userId);
});