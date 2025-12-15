import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../services/event_service.dart';
import 'auth_provider.dart';

/// 参加イベントデータのキャッシュ管理
class ParticipationEventCache {
  final List<Event> upcomingEvents;
  final List<Event> pastEvents;
  final DateTime lastUpdated;

  const ParticipationEventCache({
    required this.upcomingEvents,
    required this.pastEvents,
    required this.lastUpdated,
  });

  /// キャッシュが有効か（5分間有効）
  bool get isValid {
    final age = DateTime.now().difference(lastUpdated);
    return age.inMinutes < 5;
  }
}

/// 参加イベントキャッシュ管理Notifier
class ParticipationEventsNotifier extends Notifier<AsyncValue<ParticipationEventCache?>> {
  DateTime? _lastRefreshTime;

  @override
  AsyncValue<ParticipationEventCache?> build() {
    // 初期状態では何も読み込まない
    return const AsyncValue.data(null);
  }

  /// 参加イベントデータを強制再読み込み（過度な更新防止付き）
  Future<void> forceRefresh() async {
    // 最後の強制更新から30秒以内の場合は無視
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh.inSeconds < 30) {
        return; // 30秒以内の連続更新は無視
      }
    }

    _lastRefreshTime = DateTime.now();
    await _loadData(forceRefresh: true);
  }

  /// 参加イベントデータを読み込み（キャッシュ考慮）
  Future<void> loadIfNeeded() async {
    final current = state;
    if (current is AsyncData<ParticipationEventCache?>) {
      final cache = current.value;
      if (cache != null && cache.isValid) {
        // 有効なキャッシュがある場合は読み込みをスキップ
        return;
      }
    }

    await _loadData(forceRefresh: false);
  }

  /// 内部データ読み込み処理
  Future<void> _loadData({required bool forceRefresh}) async {
    final currentUser = ref.read(currentUserDataProvider).value;
    if (currentUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();

    try {
      // 参加予定と過去のイベントを並行取得
      final results = await Future.wait([
        EventService.getUserParticipationEvents(
          currentUser.id,
          upcomingOnly: true,
          limit: 50,
        ),
        EventService.getUserParticipationEvents(
          currentUser.id,
          pastOnly: true,
          limit: 50,
        ),
      ]);

      final cache = ParticipationEventCache(
        upcomingEvents: results[0],
        pastEvents: results[1],
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(cache);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 新しいイベント参加時にキャッシュを無効化
  void invalidateCache() {
    state = const AsyncValue.data(null);
  }
}

/// 参加イベント管理用プロバイダー
final participationEventsProvider = NotifierProvider<ParticipationEventsNotifier, AsyncValue<ParticipationEventCache?>>(() {
  return ParticipationEventsNotifier();
});

/// 参加予定イベント一覧プロバイダー
final upcomingParticipationEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final cacheAsync = ref.watch(participationEventsProvider);

  return cacheAsync.when(
    data: (cache) => AsyncValue.data(cache?.upcomingEvents ?? []),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// 過去の参加イベント一覧プロバイダー
final pastParticipationEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final cacheAsync = ref.watch(participationEventsProvider);

  return cacheAsync.when(
    data: (cache) => AsyncValue.data(cache?.pastEvents ?? []),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// 全参加イベント一覧プロバイダー（カレンダー表示用）
final allParticipationEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final cacheAsync = ref.watch(participationEventsProvider);

  return cacheAsync.when(
    data: (cache) {
      if (cache == null) return const AsyncValue.data([]);

      final allEvents = [...cache.upcomingEvents, ...cache.pastEvents];
      // 開催日降順でソート
      allEvents.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return AsyncValue.data(allEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// データ自動読み込み用プロバイダー
/// 認証状態変更時に自動的にデータを読み込む
final participationEventsAutoLoaderProvider = Provider<void>((ref) {
  final currentUser = ref.watch(currentUserDataProvider);

  currentUser.whenData((user) {
    if (user != null) {
      // ログイン時は必要に応じてデータを読み込み
      Future.microtask(() {
        ref.read(participationEventsProvider.notifier).loadIfNeeded();
      });
    } else {
      // ログアウト時はキャッシュをクリア
      Future.microtask(() {
        ref.read(participationEventsProvider.notifier).invalidateCache();
      });
    }
  });
});