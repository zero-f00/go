import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game_event_management/models/game_event.dart';

/// ユーザーのイベント関連操作を管理するサービス
class UserEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ユーザーが主催するイベントを取得
  static Stream<List<GameEvent>> getUserHostedEvents(String userId) {
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(10) // 最新10件まで表示
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameEvent.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// ユーザーが参加予定のイベントを取得
  static Stream<List<GameEvent>> getUserParticipatingEvents(String userId) {
    return _firestore
        .collection('events')
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: [GameEventStatus.upcoming.name, GameEventStatus.active.name])
        .orderBy('startDate', descending: false)
        .limit(10) // 最新10件まで表示
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameEvent.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// 特定ユーザーの公開設定に基づいて主催イベントを取得
  static Stream<List<GameEvent>> getPublicHostedEvents(
    String userId,
    bool showHostedEvents,
  ) {
    if (!showHostedEvents) {
      return Stream.value([]);
    }
    return getUserHostedEvents(userId);
  }

  /// 特定ユーザーの公開設定に基づいて参加予定イベントを取得
  static Stream<List<GameEvent>> getPublicParticipatingEvents(
    String userId,
    bool showParticipatingEvents,
  ) {
    if (!showParticipatingEvents) {
      return Stream.value([]);
    }
    return getUserParticipatingEvents(userId);
  }
}

/// UserEventService のプロバイダー
final userEventServiceProvider = Provider<UserEventService>((ref) {
  return UserEventService();
});

/// ユーザーの主催イベント一覧プロバイダー
final userHostedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return UserEventService.getUserHostedEvents(userId);
});

/// ユーザーの参加予定イベント一覧プロバイダー
final userParticipatingEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return UserEventService.getUserParticipatingEvents(userId);
});

/// プロフィール表示用の主催イベント一覧プロバイダー（公開設定考慮）
final publicHostedEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showHostedEvents})>((ref, params) {
  return UserEventService.getPublicHostedEvents(params.userId, params.showHostedEvents);
});

/// プロフィール表示用の参加予定イベント一覧プロバイダー（公開設定考慮）
final publicParticipatingEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showParticipatingEvents})>((ref, params) {
  return UserEventService.getPublicParticipatingEvents(params.userId, params.showParticipatingEvents);
});