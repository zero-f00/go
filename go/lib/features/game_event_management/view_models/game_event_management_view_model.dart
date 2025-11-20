import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_event.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/providers/auth_provider.dart';

// State class for game event management
class GameEventManagementState {
  final List<GameEvent> events;
  final bool isLoading;
  final String? errorMessage;
  final GameEventType? selectedEventType;

  const GameEventManagementState({
    this.events = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedEventType,
  });

  GameEventManagementState copyWith({
    List<GameEvent>? events,
    bool? isLoading,
    String? errorMessage,
    GameEventType? selectedEventType,
  }) {
    return GameEventManagementState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedEventType: selectedEventType ?? this.selectedEventType,
    );
  }
}

// ViewModel for game event management
class GameEventManagementViewModel extends StateNotifier<GameEventManagementState> {
  GameEventManagementViewModel(this._ref) : super(const GameEventManagementState()) {
    print('🏗️ GameEventManagementViewModel: Constructor called');
    _loadRecommendedEvents();
  }

  final Ref _ref;
  bool _disposed = false;

  /// パーソナライズされたおすすめイベントを読み込み
  Future<void> _loadRecommendedEvents() async {
    print('🚀 _loadRecommendedEvents: Starting event loading process');
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 _loadRecommendedEvents: Set loading state to true');

      // 現在のユーザーを取得
      print('👤 _loadRecommendedEvents: Getting current user');
      final currentUser = await _ref.read(currentUserDataProvider.future);
      print('👤 _loadRecommendedEvents: Current user: ${currentUser?.userId ?? "null"}');

      if (currentUser == null) {
        print('⚠️ _loadRecommendedEvents: No user logged in, getting popular events');
        // ユーザーが未ログインの場合は人気のイベントを表示
        _subscribeToRecommendedEvents('');
        return;
      }

      print('🔍 _loadRecommendedEvents: Getting recommended events for user: ${currentUser.userId}');
      // おすすめイベントを取得
      _subscribeToRecommendedEvents(currentUser.userId);
    } catch (e) {
      print('Error in _loadRecommendedEvents: $e');
      // エラー時は空のイベントリストを表示
      if (!_disposed) {
        state = state.copyWith(
          events: [],
          isLoading: false,
          errorMessage: 'イベントの取得中にエラーが発生しました',
        );
      }
    }
  }


  // Get events by type
  List<GameEvent> getEventsByType(GameEventType type) {
    return state.events.where((event) => event.type == type).toList();
  }

  // Get analytics data
  int get activeEventCount {
    return state.events.where((event) => event.status == GameEventStatus.active).length;
  }

  int get totalParticipants {
    return state.events.fold<int>(0, (sum, event) => sum + event.participantCount);
  }

  double get averageCompletionRate {
    if (state.events.isEmpty) return 0.0;
    final total = state.events.fold<double>(0, (sum, event) => sum + event.completionRate);
    return total / state.events.length;
  }

  /// おすすめイベントのStreamを監視
  void _subscribeToRecommendedEvents(String userId) {
    print('🔔 _subscribeToRecommendedEvents: Setting up stream subscription for userId: $userId');

    // StreamProviderから実際のStreamを取得
    final stream = RecommendationService.getCombinedRecommendations(userId);

    stream.listen(
      (events) {
        print('📨 _subscribeToRecommendedEvents: Received ${events.length} events');
        if (!_disposed) {
          state = state.copyWith(
            events: events,
            isLoading: false,
            errorMessage: null,
          );
          print('✅ _subscribeToRecommendedEvents: Updated state with ${events.length} events');
        }
      },
      onError: (error) {
        print('❌ _subscribeToRecommendedEvents: Stream error: $error');
        if (!_disposed) {
          state = state.copyWith(
            events: [],
            isLoading: false,
            errorMessage: 'イベントの取得に失敗しました',
          );
        }
      },
    );
  }

  // Get events by type for analytics
  List<GameEvent> getEventsByTypeForAnalytics(GameEventType type) {
    return state.events.where((event) => event.type == type).toList();
  }

  // Calculate average participation for a type
  double getAverageParticipationForType(GameEventType type) {
    final typeEvents = getEventsByTypeForAnalytics(type);
    if (typeEvents.isEmpty) return 0.0;
    final totalParticipants = typeEvents.fold<int>(0, (sum, event) => sum + event.participantCount);
    return totalParticipants / typeEvents.length;
  }


  // Actions
  void createEvent() {
    // TODO: Implement event creation
  }

  void copyLastEvent() {
    // 最新のイベントをコピーして編集状態で開く
    final events = state.events;
    if (events.isNotEmpty) {
      // 最新のイベント（作成日時ベース）を取得
      final sortedEvents = List<GameEvent>.from(events)
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      final lastEvent = sortedEvents.first;

      // TODO: コピーしたイベントデータを使ってイベント作成画面に遷移
      // Navigator.pushNamed(context, '/event-creation', arguments: lastEvent.copyForTemplate());
    }
  }

  void editEvent(String eventId) {
    // TODO: Implement event editing
  }

  void refreshEvents() {
    state = state.copyWith(isLoading: true);
    // リアルデータを再読み込み
    _loadRecommendedEvents();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// Provider for the view model
final gameEventManagementViewModelProvider = StateNotifierProvider<GameEventManagementViewModel, GameEventManagementState>(
  (ref) => GameEventManagementViewModel(ref),
);