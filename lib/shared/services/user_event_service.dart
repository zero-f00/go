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

  /// ユーザーが過去に参加したイベントを取得
  static Stream<List<GameEvent>> getUserParticipatedEvents(String userId) {
    return _firestore
        .collection('events')
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: [GameEventStatus.completed.name, GameEventStatus.expired.name])
        .orderBy('endDate', descending: true)
        .limit(10) // 最新10件まで表示
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameEvent.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// ユーザーが管理者（主催者または共同編集者）として関わるイベントを取得
  static Stream<List<GameEvent>> getUserManagedEvents(String userId) {
    // managerIds配列にユーザーのFirebase UIDが含まれるイベントを取得
    // 注: createdByとは別。主催者が自分をmanagerIdsに追加している場合のみ表示される
    return _firestore
        .collection('events')
        .where('managerIds', arrayContains: userId)
        .orderBy('startDate', descending: true)
        .limit(10) // 最新10件まで表示
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameEvent.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  /// ユーザーが主催者または共同編集者として関わるすべてのイベントを取得
  static Stream<List<GameEvent>> getUserAllManagedEvents(String userId) async* {
    // Firestoreの仕様上、OR条件での検索ができないため、
    // createdByとmanagerIdsを別々に取得してマージ
    try {
      // 両方のコレクションをチェック（eventsとgameEvents）
      final allEvents = <String, GameEvent>{};

      // まず、managerIds配列にユーザーIDが含まれるイベントを直接取得
      // 1. eventsコレクションからmanagerIds配列を検索
      try {
        final eventsWhereManagerQuery = await _firestore
            .collection('events')
            .where('managerIds', arrayContains: userId)
            .limit(20)
            .get();

        for (final doc in eventsWhereManagerQuery.docs) {
          try {
            final event = GameEvent.fromFirestore(doc.data(), doc.id);
            allEvents[event.id] = event;
          } catch (e) {
            // 変換エラーは無視して続行
          }
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 2. eventsコレクションから主催者イベントを取得（createdByでも検索）
      try {
        final eventsHostedQuery = await _firestore
            .collection('events')
            .where('createdBy', isEqualTo: userId)
            .limit(20)
            .get();

        for (final doc in eventsHostedQuery.docs) {
          final event = GameEvent.fromFirestore(doc.data(), doc.id);
          allEvents[event.id] = event;
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 3. gameEventsコレクションから主催者イベントを取得
      try {
        final gameEventsHostedQuery = await _firestore
            .collection('gameEvents')
            .where('createdBy', isEqualTo: userId)
            .limit(20)
            .get();

        for (final doc in gameEventsHostedQuery.docs) {
          final event = GameEvent.fromFirestore(doc.data(), doc.id);
          allEvents[event.id] = event;
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 4. eventsコレクションから共同編集者イベントを取得（重複排除のため再度実行）
      // すでに上記で取得済みのため、この処理は不要だが念のため残す
      // ※実際は上記の処理と重複するため、将来的に削除を検討

      // 5. gameEventsコレクションから共同編集者イベントを取得
      try {
        final gameEventsManagedQuery = await _firestore
            .collection('gameEvents')
            .where('managerIds', arrayContains: userId)
            .limit(20)
            .get();

        for (final doc in gameEventsManagedQuery.docs) {
          final event = GameEvent.fromFirestore(doc.data(), doc.id);
          allEvents[event.id] = event;
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 6. 日付順でソートして上位10件を返す
      final sortedEvents = allEvents.values.toList()
        ..sort((a, b) => (b.startDate).compareTo(a.startDate));

      yield sortedEvents.take(10).toList();
    } catch (e) {
      yield [];
    }
  }

  /// カスタムユーザーIDからFirebase UIDを取得
  static Future<String?> _getFirebaseUidFromCustomUserId(String customUserId) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: customUserId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id; // ドキュメントIDがFirebase UID
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 特定ユーザーの公開設定に基づいて主催イベントを取得
  static Stream<List<GameEvent>> getPublicHostedEvents(
    String userId,
    bool showHostedEvents,
  ) async* {
    if (!showHostedEvents) {
      yield [];
      return;
    }

    final firebaseUid = await _getFirebaseUidFromCustomUserId(userId);
    if (firebaseUid == null) {
      yield [];
      return;
    }

    yield* getUserHostedEvents(firebaseUid);
  }

  /// 特定ユーザーの公開設定に基づいて参加予定イベントを取得
  static Stream<List<GameEvent>> getPublicParticipatingEvents(
    String userId,
    bool showParticipatingEvents,
  ) async* {
    if (!showParticipatingEvents) {
      yield [];
      return;
    }

    // カスタムユーザーIDをFirebase UIDに変換
    final firebaseUid = await _getFirebaseUidFromCustomUserId(userId);
    if (firebaseUid == null) {
      yield [];
      return;
    }

    yield* _getPublicOnlyParticipatingEvents(firebaseUid);
  }

  /// 特定ユーザーの公開設定に基づいて過去参加済みイベントを取得
  static Stream<List<GameEvent>> getPublicParticipatedEvents(
    String userId,
    bool showParticipatedEvents,
  ) async* {
    if (!showParticipatedEvents) {
      yield [];
      return;
    }

    // カスタムユーザーIDをFirebase UIDに変換
    final firebaseUid = await _getFirebaseUidFromCustomUserId(userId);
    if (firebaseUid == null) {
      yield [];
      return;
    }

    yield* _getPublicOnlyParticipatedEvents(firebaseUid);
  }

  /// 特定ユーザーの公開設定に基づいて管理イベント（主催+共同編集）を取得
  static Stream<List<GameEvent>> getPublicManagedEvents(
    String userId,
    bool showManagedEvents,
  ) async* {
    if (!showManagedEvents) {
      yield [];
      return;
    }

    // パブリック表示専用：下書きやプライベートイベントを除外
    yield* _getPublicOnlyManagedEvents(userId);
  }

  /// パブリック表示専用の管理イベント取得（下書きとプライベートを除外）
  static Stream<List<GameEvent>> _getPublicOnlyManagedEvents(String userId) async* {
    try {
      final allEvents = <String, GameEvent>{};

      // 1. eventsコレクションからmanagerIds配列を検索（公開済みのみ）
      try {
        final eventsWhereManagerQuery = await _firestore
            .collection('events')
            .where('managerIds', arrayContains: userId)
            .where('status', isEqualTo: 'published')
            .where('visibility', isEqualTo: 'public')
            .limit(20)
            .get();

        for (final doc in eventsWhereManagerQuery.docs) {
          try {
            final event = GameEvent.fromFirestore(doc.data(), doc.id);
            allEvents[event.id] = event;
          } catch (e) {
            // 変換エラーは無視して続行
          }
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 2. eventsコレクションから主催者イベントを取得（公開済みのみ）
      try {
        final eventsHostedQuery = await _firestore
            .collection('events')
            .where('createdBy', isEqualTo: userId)
            .where('status', isEqualTo: 'published')
            .where('visibility', isEqualTo: 'public')
            .limit(20)
            .get();

        for (final doc in eventsHostedQuery.docs) {
          final event = GameEvent.fromFirestore(doc.data(), doc.id);
          allEvents[event.id] = event;
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // 3. gameEventsコレクションから主催者イベントを取得（アクティブのみ）
      try {
        final gameEventsHostedQuery = await _firestore
            .collection('gameEvents')
            .where('createdBy', isEqualTo: userId)
            .where('status', isEqualTo: 'active')
            .limit(20)
            .get();

        for (final doc in gameEventsHostedQuery.docs) {
          final event = GameEvent.fromFirestore(doc.data(), doc.id);
          allEvents[event.id] = event;
        }
      } catch (e) {
        // クエリエラーは無視して続行
      }

      // IDでソートして返す
      final events = allEvents.values.toList();
      events.sort((a, b) => b.startDate.compareTo(a.startDate));
      yield events;

    } catch (e) {
      yield [];
    }
  }

  /// パブリック表示専用の参加予定イベント取得（下書きとプライベートを除外）
  static Stream<List<GameEvent>> _getPublicOnlyParticipatingEvents(String userId) async* {
    try {
      final now = DateTime.now();
      final events = <GameEvent>[];

      // eventsコレクションから公開中のイベントのみ取得
      final eventsQuery = await _firestore
          .collection('events')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'published')
          .where('visibility', isEqualTo: 'public')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(20)
          .get();

      for (final doc in eventsQuery.docs) {
        try {
          final gameEvent = GameEvent.fromFirestore(doc.data(), doc.id);
          events.add(gameEvent);
        } catch (e) {
          // 変換エラーは無視して続行
        }
      }

      // gameEventsコレクションからアクティブなイベントのみ取得
      final gameEventsQuery = await _firestore
          .collection('gameEvents')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .limit(20)
          .get();

      for (final doc in gameEventsQuery.docs) {
        try {
          final gameEvent = GameEvent.fromFirestore(doc.data(), doc.id);
          events.add(gameEvent);
        } catch (e) {
          // 変換エラーは無視して続行
        }
      }

      // 日付でソート
      events.sort((a, b) => a.startDate.compareTo(b.startDate));
      yield events;

    } catch (e) {
      yield [];
    }
  }

  /// パブリック表示専用の参加済みイベント取得（下書きとプライベートを除外）
  static Stream<List<GameEvent>> _getPublicOnlyParticipatedEvents(String userId) async* {
    try {
      final now = DateTime.now();
      final events = <GameEvent>[];

      // eventsコレクションから公開中の過去イベントのみ取得
      final eventsQuery = await _firestore
          .collection('events')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'published')
          .where('visibility', isEqualTo: 'public')
          .where('startDate', isLessThan: Timestamp.fromDate(now))
          .limit(20)
          .get();

      for (final doc in eventsQuery.docs) {
        try {
          final gameEvent = GameEvent.fromFirestore(doc.data(), doc.id);
          events.add(gameEvent);
        } catch (e) {
          // 変換エラーは無視して続行
        }
      }

      // gameEventsコレクションから完了した過去イベントのみ取得
      final gameEventsQuery = await _firestore
          .collection('gameEvents')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .limit(20)
          .get();

      for (final doc in gameEventsQuery.docs) {
        try {
          final gameEvent = GameEvent.fromFirestore(doc.data(), doc.id);
          events.add(gameEvent);
        } catch (e) {
          // 変換エラーは無視して続行
        }
      }

      // 日付でソート（新しい順）
      events.sort((a, b) => b.startDate.compareTo(a.startDate));
      yield events;

    } catch (e) {
      yield [];
    }
  }

  /// ユーザーのアクティビティ統計を取得
  static Future<Map<String, int>> getUserActivityStats(String userId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // 今月の統計を取得
      final stats = <String, int>{};

      // 運営者として携わったイベント数を計算するためのセット（重複除去）
      final managedEventIds = <String>{};

      // 1. 主催イベント数を取得（createdBy）
      final hostedEventsQuery = await _firestore
          .collection('events')
          .where('createdBy', isEqualTo: userId)
          .get();

      final gameEventsHostedQuery = await _firestore
          .collection('gameEvents')
          .where('createdBy', isEqualTo: userId)
          .get();

      // 主催イベントIDを追加
      for (final doc in hostedEventsQuery.docs) {
        managedEventIds.add(doc.id);
      }
      for (final doc in gameEventsHostedQuery.docs) {
        managedEventIds.add(doc.id);
      }

      // 2. 管理者として携わったイベント（managerIds）を取得
      try {
        final managedEventsQuery = await _firestore
            .collection('events')
            .where('managerIds', arrayContains: userId)
            .get();

        for (final doc in managedEventsQuery.docs) {
          managedEventIds.add(doc.id);
        }
      } catch (e) {
        // managerIds フィールドが存在しない可能性があるため、エラーを無視
      }

      try {
        final gameEventsManagedQuery = await _firestore
            .collection('gameEvents')
            .where('managerIds', arrayContains: userId)
            .get();

        for (final doc in gameEventsManagedQuery.docs) {
          managedEventIds.add(doc.id);
        }
      } catch (e) {
        // managerIds フィールドが存在しない可能性があるため、エラーを無視
      }

      // 3. スポンサーとして携わったイベント（sponsors）を取得
      try {
        final sponsoredEventsQuery = await _firestore
            .collection('events')
            .where('sponsors', arrayContains: userId)
            .get();

        for (final doc in sponsoredEventsQuery.docs) {
          managedEventIds.add(doc.id);
        }
      } catch (e) {
        // sponsors フィールドが存在しない可能性があるため、エラーを無視
      }

      try {
        final gameEventsSponsoredQuery = await _firestore
            .collection('gameEvents')
            .where('sponsors', arrayContains: userId)
            .get();

        for (final doc in gameEventsSponsoredQuery.docs) {
          managedEventIds.add(doc.id);
        }
      } catch (e) {
        // sponsors フィールドが存在しない可能性があるため、エラーを無視
      }

      // 運営者として携わったイベントの総数
      stats['totalManagedEvents'] = managedEventIds.length;
      // 後方互換性のため、従来のフィールドも保持
      stats['totalHostedEvents'] = hostedEventsQuery.docs.length + gameEventsHostedQuery.docs.length;

      // 今月の運営イベント数を計算（すべてのイベントを再取得して日付チェック）
      int thisMonthManagedCount = 0;

      // managedEventIdsから今月のイベント数を計算
      for (final eventId in managedEventIds) {
        try {
          // eventsコレクションから検索
          var doc = await _firestore.collection('events').doc(eventId).get();
          if (doc.exists) {
            final data = doc.data()!;
            final startDate = (data['startDate'] as Timestamp?)?.toDate();
            if (startDate != null && startDate.isAfter(startOfMonth)) {
              thisMonthManagedCount++;
              continue;
            }
          }

          // gameEventsコレクションから検索
          doc = await _firestore.collection('gameEvents').doc(eventId).get();
          if (doc.exists) {
            final data = doc.data()!;
            final startDate = (data['startDate'] as Timestamp?)?.toDate();
            if (startDate != null && startDate.isAfter(startOfMonth)) {
              thisMonthManagedCount++;
            }
          }
        } catch (e) {
          // 個別のイベント取得エラーは無視
        }
      }

      stats['thisMonthManagedEvents'] = thisMonthManagedCount;

      // 今月の主催イベント数（後方互換性のため保持）
      final thisMonthHosted = hostedEventsQuery.docs.where((doc) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        return startDate != null && startDate.isAfter(startOfMonth);
      }).length;

      final thisMonthGameEventsHosted = gameEventsHostedQuery.docs.where((doc) {
        final data = doc.data();
        final startDate = (data['startDate'] as Timestamp?)?.toDate();
        return startDate != null && startDate.isAfter(startOfMonth);
      }).length;

      stats['thisMonthHostedEvents'] = thisMonthHosted + thisMonthGameEventsHosted;

      return stats;
    } catch (e) {
      return {
        'totalManagedEvents': 0,
        'totalHostedEvents': 0,
        'thisMonthManagedEvents': 0,
        'thisMonthHostedEvents': 0,
      };
    }
  }

  /// ユーザーの参加統計を取得（ParticipationServiceと組み合わせて使用）
  static Map<String, int> calculateParticipationStats(List<dynamic> applications) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final stats = <String, int>{};

    // 総申し込み数
    stats['totalApplications'] = applications.length;

    // 承認済み数
    final approvedApplications = applications.where((app) =>
        app.status.toString() == 'ParticipationStatus.approved'
    ).toList();
    stats['approvedApplications'] = approvedApplications.length;

    // 申し込み中数
    final pendingApplications = applications.where((app) =>
        app.status.toString() == 'ParticipationStatus.pending'
    ).toList();
    stats['pendingApplications'] = pendingApplications.length;

    // 今月の申し込み数
    final thisMonthApplications = applications.where((app) {
      return app.appliedAt.isAfter(startOfMonth);
    }).toList();
    stats['thisMonthApplications'] = thisMonthApplications.length;

    // 今月の承認済み数
    final thisMonthApproved = thisMonthApplications.where((app) =>
        app.status.toString() == 'ParticipationStatus.approved'
    ).toList();
    stats['thisMonthApprovedApplications'] = thisMonthApproved.length;

    return stats;
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

/// ユーザーの過去参加済みイベント一覧プロバイダー
final userParticipatedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return UserEventService.getUserParticipatedEvents(userId);
});

/// プロフィール表示用の主催イベント一覧プロバイダー（公開設定考慮）
final publicHostedEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showHostedEvents})>((ref, params) {
  return UserEventService.getPublicHostedEvents(params.userId, params.showHostedEvents);
});

/// プロフィール表示用の参加予定イベント一覧プロバイダー（公開設定考慮）
final publicParticipatingEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showParticipatingEvents})>((ref, params) {
  return UserEventService.getPublicParticipatingEvents(params.userId, params.showParticipatingEvents);
});

/// プロフィール表示用の過去参加済みイベント一覧プロバイダー（公開設定考慮）
final publicParticipatedEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showParticipatedEvents})>((ref, params) {
  return UserEventService.getPublicParticipatedEvents(params.userId, params.showParticipatedEvents);
});

/// ユーザーの共同編集者イベント一覧プロバイダー
final userManagedEventsProvider = StreamProvider.family<List<GameEvent>, String>((ref, userId) {
  return UserEventService.getUserManagedEvents(userId);
});

/// プロフィール表示用の共同編集者イベント一覧プロバイダー（公開設定考慮）
final publicManagedEventsProvider = StreamProvider.family<List<GameEvent>, ({String userId, bool showManagedEvents})>((ref, params) {
  return UserEventService.getPublicManagedEvents(params.userId, params.showManagedEvents);
});

