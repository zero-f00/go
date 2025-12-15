import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_tab_bar.dart';
import '../../../shared/widgets/auth_dialog.dart';
import '../../../shared/widgets/user_settings_dialog.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/event_management_types.dart';
import '../../event_creation/views/event_creation_screen.dart';
import '../../../shared/widgets/event_list_screen.dart';
import '../../../shared/widgets/enhanced_past_events_screen.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/utils/event_converter.dart' as converter;
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../shared/widgets/past_events_selection_dialog.dart';
import '../../calendar/views/host_event_calendar_screen.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../shared/widgets/unified_calendar_widget.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../../shared/providers/participation_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  final bool shouldNavigateToEventCreation;
  final VoidCallback? onEventCreationNavigated;
  final bool isActive;

  const ManagementScreen({
    super.key,
    this.shouldNavigateToEventCreation = false,
    this.onEventCreationNavigated,
    this.isActive = true,
  });

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with TickerProviderStateMixin {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  TabController? _participantTabController;

  final List<String> _tabLabels = [
    AppStrings.hostEventTab,
    AppStrings.participantEventTab,
  ];

  // イベント数のキャッシュ
  Map<EventManagementType, int> _eventCounts = {};
  Map<EventManagementType, int> _activeEventCounts = {};
  bool _isLoadingCounts = false;

  // ゲームアイコンのキャッシュ
  final Map<String, String?> _gameIconCache = {};
  DateTime? _lastCountsLoadTime;

  // ダイアログの重複表示を防ぐためのフラグ
  bool _isDialogShowing = false;

  // 参加イベントタブの表示モード: true=リスト, false=カレンダー
  bool _isParticipantListView = true;

  // 認証状態が確定してデータを読み込んだかどうか
  bool _hasInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _participantTabController = TabController(
      length: 2, // 参加予定と過去のイベント
      vsync: this,
    );

    // タブ切り替え時にUIを更新（ヘッダーのアクションボタン表示切り替え用）
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // 認証状態が確定するまでイベント数の読み込みを待機
    // buildメソッド内のref.listenで認証状態を監視してデータを読み込む

    // イベント作成画面への自動遷移処理
    if (widget.shouldNavigateToEventCreation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToEventCreation();
        widget.onEventCreationNavigated?.call();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _participantTabController?.dispose();
    super.dispose();
  }

  /// イベント数を読み込み
  Future<void> _loadEventCounts({bool forceRefresh = false}) async {
    // キャッシュが有効な場合は読み込みをスキップ（5分間有効）
    if (!forceRefresh && _lastCountsLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastCountsLoadTime!);
      if (cacheAge.inMinutes < 5 && _eventCounts.isNotEmpty) {
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingCounts = true;
      });
    }

    try {
      // 現在のユーザーを取得
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoadingCounts = false;
          });
        }
        return;
      }

      // ユーザーのすべてのイベントを取得
      final userEvents = await EventService.getUserCreatedEvents(
        currentUser.id,
      );

      // 各タイプ別にイベント数をカウント
      final Map<EventManagementType, int> counts = {};
      final Map<EventManagementType, int> activeCounts = {};

      for (final eventType in EventManagementType.values) {
        final filteredEvents =
            await converter.EventConverter.filterEventsByManagementType(
              userEvents,
              currentUser.id,
              eventType,
            );

        counts[eventType] = filteredEvents.length;

        // アクティブなイベント数をカウント（開催中または開催予定）
        final activeEvents = filteredEvents
            .where(
              (event) =>
                  event.status == GameEventStatus.active ||
                  event.status == GameEventStatus.upcoming,
            )
            .length;

        activeCounts[eventType] = activeEvents;
      }

      if (mounted) {
        setState(() {
          _eventCounts = counts;
          _activeEventCounts = activeCounts;
          _lastCountsLoadTime = DateTime.now();
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      // エラーが発生した場合はデフォルト値を設定
      if (mounted) {
        setState(() {
          _eventCounts = {
            for (final eventType in EventManagementType.values) eventType: 0,
          };
        _activeEventCounts = {
          for (final eventType in EventManagementType.values) eventType: 0,
        };
        _isLoadingCounts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final needsInitialSetup = ref.watch(needsInitialSetupProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);

    // 認証状態の変更を監視し、ログイン状態が確定したらデータを読み込む
    ref.listen<AsyncValue<UserData?>>(currentUserDataProvider, (previous, next) {
      next.whenData((userData) {
        if (userData != null && !_hasInitialDataLoaded) {
          _hasInitialDataLoaded = true;
          _loadEventCounts(forceRefresh: false);
        } else if (userData == null) {
          // ログアウト時はフラグをリセット
          _hasInitialDataLoaded = false;
          setState(() {
            _eventCounts = {};
            _activeEventCounts = {};
            _lastCountsLoadTime = null;
          });
        }
      });
    });

    // 初回ビルド時に既にログイン状態であればデータを読み込む
    if (!_hasInitialDataLoaded && userDataAsync.hasValue && userDataAsync.value != null) {
      _hasInitialDataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadEventCounts(forceRefresh: false);
        }
      });
    }

    // 認証状態がローディング中の場合は待機画面を表示（サインインダイアログを表示しない）
    if (authState.isLoading) {
      return _buildLoadingScreen();
    }

    // 認証状態が確定し、サインインしていない場合のみサインインダイアログを表示
    // ただし、この画面がアクティブな場合のみ
    final isSignedIn = authState.hasValue && authState.value != null;
    if (!isSignedIn) {
      if (!_isDialogShowing && widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDialogShowing && mounted && widget.isActive) {
            _showSignInDialog();
          }
        });
      }
      return _buildAuthRequiredScreen('サインインが必要です', 'サインインして管理機能を使用してください');
    }

    // ユーザーデータがローディング中の場合は待機画面を表示
    if (userDataAsync is AsyncLoading) {
      return _buildLoadingScreen();
    }

    // サインイン済みだが初回設定が未完了の場合、初回設定ダイアログを表示
    // ただし、userDataがローディング中でない場合かつ画面がアクティブな場合のみ
    if (needsInitialSetup && currentUser != null) {
      if (!_isDialogShowing && widget.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDialogShowing && mounted && widget.isActive) {
            _showInitialSetupDialog();
          }
        });
      }
      return _buildAuthRequiredScreen('初回設定が必要です', '初回設定を完了して管理機能を使用してください');
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: AppStrings.manageTab,
                showBackButton: false,
                showUserIcon: true,
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                // 参加イベントタブが選択されている場合のみ表示切り替えボタンを表示
                actions: _tabController.index == 1
                    ? [_buildViewToggleButton()]
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                ),
                child: AppTabBar(
                  controller: _tabController,
                  tabLabels: _tabLabels,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildHostEventTab(), _buildParticipantEventTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 主催イベント管理タブ
  Widget _buildHostEventTab() {
    return RefreshIndicator(
      onRefresh: () => _loadEventCounts(forceRefresh: true),
      color: AppColors.accent,
      backgroundColor: AppColors.cardBackground,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          margin: const EdgeInsets.all(AppDimensions.spacingL),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: AppDimensions.cardElevation,
                offset: const Offset(0, AppDimensions.shadowOffsetY),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              children: [
                _buildQuickActionsSection(),
                const SizedBox(height: AppDimensions.spacingM),
                _buildManagementOptionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 参加イベント管理タブ
  Widget _buildParticipantEventTab() {
    // カレンダー表示の場合
    if (!_isParticipantListView) {
      return RefreshIndicator(
        onRefresh: _refreshParticipationData,
        color: AppColors.accent,
        backgroundColor: AppColors.cardBackground,
        child: _buildParticipantCalendarView(),
      );
    }

    // リスト表示の場合
    return RefreshIndicator(
      onRefresh: _refreshParticipationData,
      color: AppColors.accent,
      backgroundColor: AppColors.cardBackground,
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: AppDimensions.cardElevation,
              offset: const Offset(0, AppDimensions.shadowOffsetY),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            children: [
              _buildParticipationTabBar(),
              Expanded(
                child: _participantTabController == null
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _participantTabController!,
                      children: [
                        _buildUpcomingEventsTab(),
                        _buildPastEventsTab(),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 参加イベント用タブバー（カレンダー表示ボタンは削除、ヘッダー右上に移動）
  Widget _buildParticipationTabBar() {
    if (_participantTabController == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: TabBar(
        controller: _participantTabController!,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textDark,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppDimensions.fontSizeM,
        ),
        tabs: const [
          Tab(text: '参加予定'),
          Tab(text: '過去のイベント'),
        ],
      ),
    );
  }

  /// 参加予定のイベントタブ
  Widget _buildUpcomingEventsTab() {
    // 自動データ読み込みを開始
    ref.read(participationEventsAutoLoaderProvider);

    return RefreshIndicator(
      onRefresh: _refreshParticipationData,
      color: AppColors.accent,
      backgroundColor: AppColors.cardBackground,
      child: Consumer(
        builder: (context, ref, child) {
          final upcomingEventsAsync = ref.watch(upcomingParticipationEventsProvider);

          return upcomingEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildScrollableEmptyState(
                  '参加予定のイベントがありません',
                  '新しいイベントに参加してみませんか？',
                  Icons.event_available,
                );
              }
              return _buildEventList(events);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _buildScrollableEmptyState(
              'データの取得に失敗しました',
              '再度お試しください',
              Icons.error_outline,
            ),
          );
        },
      ),
    );
  }

  /// 過去のイベントタブ
  Widget _buildPastEventsTab() {
    return RefreshIndicator(
      onRefresh: _refreshParticipationData,
      color: AppColors.accent,
      backgroundColor: AppColors.cardBackground,
      child: Consumer(
        builder: (context, ref, child) {
          final pastEventsAsync = ref.watch(pastParticipationEventsProvider);

          return pastEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildScrollableEmptyState(
                  '参加した過去のイベントがありません',
                  'イベントに参加して実績を積み重ねましょう',
                  Icons.history,
                );
              }
              return _buildEventList(events);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _buildScrollableEmptyState(
              'データの取得に失敗しました',
              '再度お試しください',
              Icons.error_outline,
            ),
          );
        },
      ),
    );
  }

  /// 参加データのリフレッシュ
  Future<void> _refreshParticipationData() async {
    await ref.read(participationEventsProvider.notifier).forceRefresh();
  }

  /// スクロール可能な空状態（RefreshIndicator用）
  Widget _buildScrollableEmptyState(String title, String subtitle, IconData icon) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: _buildEmptyParticipantState(title, subtitle, icon),
        ),
      ],
    );
  }

  /// イベントリスト表示
  Widget _buildEventList(List<Event> events) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: Material(
            color: AppColors.backgroundTransparent,
            child: InkWell(
              onTap: () => _navigateToEventDetail(event.id),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                decoration: BoxDecoration(
                  color: event.status == EventStatus.cancelled
                      ? AppColors.error.withValues(alpha: 0.05)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: event.status == EventStatus.cancelled
                      ? Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: AppDimensions.cardElevation,
                      offset: const Offset(0, AppDimensions.shadowOffsetY),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: event.status == EventStatus.cancelled
                                  ? AppColors.textSecondary
                                  : AppColors.textDark,
                              decoration: event.status == EventStatus.cancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingS,
                            vertical: AppDimensions.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: _getEventStatusColor(
                              event,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            _getEventStatusText(event),
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeXS,
                              color: _getEventStatusColor(event),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (event.gameName != null) ...[
                      const SizedBox(height: AppDimensions.spacingS),
                      Row(
                        children: [
                          FutureBuilder<String?>(
                            future: _getGameIconUrl(event.gameId),
                            builder: (context, snapshot) {
                              return GameIcon(
                                iconUrl: snapshot.data,
                                size: 32,
                                gameName: event.gameName,
                              );
                            },
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Expanded(
                            child: Text(
                              event.gameName!,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: AppDimensions.iconS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          _formatDate(event.eventDate),
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 空の状態表示
  Widget _buildEmptyParticipantState(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimensions.iconXXL, color: AppColors.textLight),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// イベント詳細画面に遷移
  void _navigateToEventDetail(String eventId) {
    Navigator.of(context).pushNamed('/event_detail', arguments: eventId);
  }

  /// 参加イベントタブ用の表示切り替えボタン（おすすめイベント画面と同じUI）
  Widget _buildViewToggleButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            icon: Icons.list,
            isSelected: _isParticipantListView,
            onTap: () => setState(() => _isParticipantListView = true),
            tooltip: 'リスト表示',
          ),
          _buildToggleItem(
            icon: Icons.calendar_month,
            isSelected: !_isParticipantListView,
            onTap: () => setState(() => _isParticipantListView = false),
            tooltip: 'カレンダー表示',
          ),
        ],
      ),
    );
  }

  /// トグルアイテム（おすすめイベント画面と同じUI）
  Widget _buildToggleItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.backgroundWhite
                : AppColors.backgroundTransparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconM,
            color: isSelected ? AppColors.primary : AppColors.textWhite,
          ),
        ),
      ),
    );
  }

  /// 参加イベントカレンダービュー（UnifiedCalendarWidgetを直接使用）
  Widget _buildParticipantCalendarView() {
    return UnifiedCalendarWidget(
      title: '参加予定カレンダー',
      onLoadEvents: _loadParticipationEventsForCalendar,
      onEventTap: _navigateToEventDetailFromCalendar,
      emptyMessage: 'この日は参加予定のイベントがありません',
      emptyIcon: Icons.event_busy,
      getEventStatusColor: (event) {
        switch (event.status) {
          case GameEventStatus.upcoming:
            return AppColors.info;
          case GameEventStatus.active:
          case GameEventStatus.published:
            return AppColors.success;
          default:
            return AppColors.textSecondary;
        }
      },
    );
  }

  /// カレンダー用の参加イベントデータを読み込み
  Future<Map<DateTime, List<GameEvent>>> _loadParticipationEventsForCalendar() async {
    final eventMap = <DateTime, List<GameEvent>>{};

    try {
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) return eventMap;

      // 効率的なプロバイダーからデータを取得
      final cacheAsync = ref.read(participationEventsProvider);
      final cache = cacheAsync.value;

      if (cache != null) {
        // キャッシュされたデータを使用
        final allEvents = [...cache.upcomingEvents, ...cache.pastEvents];

        for (final event in allEvents) {
          // EventをGameEventに変換
          final gameEvent = await converter.EventConverter.eventToGameEvent(event);

          final date = DateTime(
            gameEvent.startDate.year,
            gameEvent.startDate.month,
            gameEvent.startDate.day,
          );

          if (!eventMap.containsKey(date)) {
            eventMap[date] = [];
          }
          eventMap[date]!.add(gameEvent);
        }
      } else {
        // キャッシュがない場合は一括取得にフォールバック
        final participationEvents = await EventService.getUserParticipationEvents(currentUser.id);

        for (final event in participationEvents) {
          final gameEvent = await converter.EventConverter.eventToGameEvent(event);

          final date = DateTime(
            gameEvent.startDate.year,
            gameEvent.startDate.month,
            gameEvent.startDate.day,
          );

          if (!eventMap.containsKey(date)) {
            eventMap[date] = [];
          }
          eventMap[date]!.add(gameEvent);
        }
      }
    } catch (e) {
      // エラー時は空のマップを返す
    }

    return eventMap;
  }



  /// カレンダーからイベント詳細画面へ遷移
  void _navigateToEventDetailFromCalendar(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  /// 主催イベント用カレンダー画面に遷移
  void _navigateToHostCalendar() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null) return;

    try {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HostEventCalendarScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('カレンダーの読み込みに失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// イベントステータスの色を取得
  Color _getEventStatusColor(Event event) {
    // イベントが中止された場合
    if (event.status == EventStatus.cancelled) {
      return AppColors.error; // 中止
    }

    final now = DateTime.now();
    if (event.eventDate.isAfter(now)) {
      return AppColors.info; // 開催予定
    } else {
      return AppColors.textSecondary; // 終了
    }
  }

  /// イベントステータステキストを取得
  String _getEventStatusText(Event event) {
    // イベントが中止された場合
    if (event.status == EventStatus.cancelled) {
      return '中止';
    }

    final now = DateTime.now();
    if (event.eventDate.isAfter(now)) {
      return '開催予定';
    } else {
      return '終了';
    }
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'クイックアクション',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: AppStrings.createNew,
                  icon: Icons.add_circle,
                  color: AppColors.success,
                  onTap: () {
                    _navigateToEventCreation();
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: _buildActionButton(
                  title: 'カレンダー表示',
                  icon: Icons.calendar_month,
                  color: AppColors.primary,
                  onTap: () {
                    _navigateToHostCalendar();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  title: 'イベントをコピー',
                  icon: Icons.content_copy,
                  color: AppColors.info,
                  onTap: () {
                    _showPastEventsForCopy();
                  },
                ),
              ),
              const Expanded(child: SizedBox()), // 空のスペースで調整
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundTransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AppDimensions.iconL),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ステータスチップを構築
  Widget _buildStatusChip(
    String label,
    String count,
    IconData icon,
    Color color,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: isLoading
          ? SizedBox(
              width: 50,
              height: 14,
              child: LinearProgressIndicator(
                color: color,
                backgroundColor: AppColors.backgroundLight,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: AppDimensions.spacingXS / 2),
                Text(
                  '$label: $count',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildManagementOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '管理オプション',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildManagementOptionWithCount(
            title: '作成したイベント',
            subtitle: '自分が作成したイベントを管理',
            icon: Icons.event,
            count: _eventCounts[EventManagementType.createdEvents] ?? 0,
            activeCount:
                _activeEventCounts[EventManagementType.createdEvents],
            onTap: () {
              _navigateToEventList(
                context,
                EventManagementType.createdEvents,
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementOptionWithCount(
            title: '共同編集者のイベント',
            subtitle: '編集権限を持つイベントを管理',
            icon: Icons.group,
            count:
                _eventCounts[EventManagementType.collaborativeEvents] ??
                0,
            activeCount:
                _activeEventCounts[EventManagementType
                    .collaborativeEvents],
            onTap: () {
              _navigateToEventList(
                context,
                EventManagementType.collaborativeEvents,
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementOptionWithCount(
            title: '下書き保存されたイベント',
            subtitle: '一時保存されたイベントを管理',
            icon: Icons.drafts,
            count: _eventCounts[EventManagementType.draftEvents] ?? 0,
            activeCount: null,
            onTap: () {
              _navigateToEventList(
                context,
                EventManagementType.draftEvents,
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementOptionWithCount(
            title: '過去のイベント履歴',
            subtitle: '終了したイベントを閲覧・統計確認',
            icon: Icons.history,
            count: _eventCounts[EventManagementType.pastEvents] ?? 0,
            activeCount: null,
            onTap: () {
              _navigateToEventList(
                context,
                EventManagementType.pastEvents,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOptionWithCount({
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    int? activeCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.backgroundTransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Wrap(
                      spacing: AppDimensions.spacingXS,
                      runSpacing: AppDimensions.spacingXS,
                      children: [
                        _buildStatusChip(
                          '合計',
                          count.toString(),
                          Icons.event,
                          AppColors.info,
                          _isLoadingCounts,
                        ),
                        if (activeCount != null)
                          _buildStatusChip(
                            '公開中',
                            activeCount.toString(),
                            Icons.public,
                            AppColors.success,
                            _isLoadingCounts,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
                size: AppDimensions.iconM,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEventCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventCreationScreen()),
    ).then((result) {
      // イベント作成後にカウントを強制再読み込み
      _loadEventCounts(forceRefresh: true);

      // イベントが作成された場合（resultがeventId）、おすすめイベントを更新
      if (result != null) {
        final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
        if (firebaseUid != null) {
          ref.invalidate(recommendedEventsProvider(firebaseUid));
        }
      }
    });
  }

  /// 過去のイベント一覧を表示してコピー対象を選択
  Future<void> _showPastEventsForCopy() async {
    try {
      // 現在のユーザーを取得
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ユーザー情報の取得に失敗しました'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // ユーザーが運営者として関わった全イベントを取得
      final userEvents = await EventService.getUserCreatedEvents(
        currentUser.id,
        limit: 100,
      );

      if (userEvents.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('コピー可能なイベントがありません\nまず最初のイベントを作成してください'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 過去のイベント選択ダイアログを表示
      if (mounted) {
        final selectedEvent = await PastEventsSelectionDialog.show(
          context,
          pastEvents: userEvents,
          title: 'コピーするイベントを選択',
          emptyMessage: 'コピー可能なイベントがありません',
        );

        if (selectedEvent != null) {
          await _copySelectedEventAndNavigate(selectedEvent);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('イベント一覧の取得に失敗しました: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 選択されたイベントをコピーして作成画面へ遷移
  Future<void> _copySelectedEventAndNavigate(Event selectedEvent) async {
    try {
      // EventをGameEventに変換
      final gameEvent = await converter.EventConverter.eventToGameEvent(
        selectedEvent,
      );

      // コピー用のGameEventを作成（IDやタイムスタンプなどをクリア）
      final copiedGameEvent = GameEvent(
        id: '', // 新規作成なのでIDをクリア
        name: '${gameEvent.name}のコピー', // タイトルに「のコピー」を追加
        subtitle: gameEvent.subtitle,
        description: gameEvent.description,
        type: gameEvent.type,
        status: GameEventStatus.upcoming, // ステータスをリセット
        startDate: DateTime.now().add(const Duration(days: 7)), // 開催日を1週間後に設定
        endDate: DateTime.now().add(const Duration(days: 8)), // 終了日を8日後に設定
        participantCount: 0, // 参加者数をリセット
        maxParticipants: gameEvent.maxParticipants,
        completionRate: 0.0, // 完了率をリセット
        isPremium: gameEvent.isPremium,
        hasFee: gameEvent.hasFee,
        rewards: gameEvent.rewards,
        gameId: gameEvent.gameId,
        gameName: gameEvent.gameName,
        gameIconUrl: gameEvent.gameIconUrl,
        imageUrl: gameEvent.imageUrl, // コピー時は前回の画像URLを保持
        rules: gameEvent.rules,
        registrationDeadline: DateTime.now().add(
          const Duration(days: 6),
        ), // 申込期限を6日後に設定
        prizeContent: gameEvent.prizeContent,
        contactInfo: gameEvent.contactInfo,
        policy: gameEvent.policy,
        additionalInfo: gameEvent.additionalInfo,
        streamingUrls: gameEvent.streamingUrls,
        minAge: gameEvent.minAge,
        feeAmount: gameEvent.feeAmount,
        feeText: gameEvent.feeText,
        feeSupplement: gameEvent.feeSupplement,
        platforms: gameEvent.platforms,
        approvalMethod: gameEvent.approvalMethod,
        visibility: gameEvent.visibility,
        language: gameEvent.language,
        hasAgeRestriction: gameEvent.hasAgeRestriction,
        hasStreaming: gameEvent.hasStreaming,
        eventTags: gameEvent.eventTags,
        sponsors: gameEvent.sponsors,
        managers: gameEvent.managers,
        blockedUsers: gameEvent.blockedUsers,
        createdBy: gameEvent.createdBy,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EventCreationScreen(editingEvent: copiedGameEvent),
          ),
        ).then((result) {
          // イベント作成後にカウントを強制再読み込み
          _loadEventCounts(forceRefresh: true);

          // イベントが作成された場合、おすすめイベントを更新
          if (result != null) {
            final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
            if (firebaseUid != null) {
              ref.invalidate(recommendedEventsProvider(firebaseUid));
            }
          }
        });

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('「${selectedEvent.name}」をコピーしました'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('イベントのコピーに失敗しました: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _navigateToEventList(
    BuildContext context,
    EventManagementType eventType,
  ) async {
    // ユーザー情報の取得
    UserData? currentUser;
    try {
      currentUser = await ref.read(currentUserDataProvider.future);
    } catch (e) {
      // ユーザー情報の取得に失敗
    }

    if (currentUser == null) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報の取得に失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // イベント一覧を取得（エラーが発生しても空のリストで画面遷移）
    List<GameEvent> events = [];
    String? errorMessage;

    try {
      switch (eventType) {
        case EventManagementType.createdEvents:
        case EventManagementType.collaborativeEvents:
        case EventManagementType.draftEvents:
        case EventManagementType.pastEvents:
          // ユーザーが作成したイベントを取得
          final userEvents = await EventService.getUserCreatedEvents(
            currentUser.id,
          );
          // EventをGameEventに変換し、タイプ別にフィルタリング
          events = await converter.EventConverter.filterEventsByManagementType(
            userEvents,
            currentUser.id,
            eventType,
          );
          // イベント読み込み完了
          break;
      }
    } catch (e) {
      // エラーが発生した場合でも画面遷移は行い、空の状態を表示
      errorMessage = 'イベントの取得中にエラーが発生しました';
      events = []; // 空のリストで画面遷移
    }

    // 常に画面遷移を行う（イベントが0個でも空状態画面を表示）
    if (mounted && context.mounted) {
      // 過去のイベント履歴の場合は改善されたUIを使用
      if (eventType == EventManagementType.pastEvents) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnhancedPastEventsScreen(
              events: events,
              isManagementMode: true,
              onEventTap: (event) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(event: event),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventListScreen(
              title: eventType.title,
              headerIcon: eventType.icon,
              initialEvents: events,
              isManagementMode: true,
              showCalendarToggle: eventType != EventManagementType.draftEvents,
              emptyMessage: errorMessage ?? eventType.emptyMessage,
              emptySubMessage: errorMessage ?? eventType.emptyDetailMessage,
              emptyIcon: eventType.icon,
            ),
          ),
        );
      }

      // エラーメッセージがある場合は、画面遷移後に表示
      if (errorMessage != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage!),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    }
  }

  /// サインインダイアログを表示
  Future<void> _showSignInDialog() async {
    if (_isDialogShowing) return;

    _isDialogShowing = true;
    try {
      final result = await AuthDialog.show(context);
      if (result == true) {
        // サインイン成功後、状態が更新されるまで待機
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } finally {
      _isDialogShowing = false;
    }
  }

  /// 初回設定ダイアログを表示
  Future<void> _showInitialSetupDialog() async {
    if (_isDialogShowing) return;

    _isDialogShowing = true;
    try {
      final result = await UserSettingsDialog.show(
        context,
        isInitialSetup: true,
      );
      if (result == true) {
        // 初回設定完了後、状態が更新されるまで待機
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } finally {
      _isDialogShowing = false;
    }
  }

  /// ローディング状態を示す画面を構築
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(title: AppStrings.manageTab, showBackButton: false),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXL),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: AppDimensions.cardElevation,
                            offset: const Offset(
                              0,
                              AppDimensions.shadowOffsetY,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: AppDimensions.iconXXL,
                            height: AppDimensions.iconXXL,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 3.0,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingL),
                          const Text(
                            'データを読み込み中...',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          const Text(
                            'ユーザー情報を確認しています',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 認証が必要な状態を示す画面を構築
  Widget _buildAuthRequiredScreen(String title, String message) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(title: AppStrings.manageTab, showBackButton: false),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXL),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: AppDimensions.cardElevation,
                            offset: const Offset(
                              0,
                              AppDimensions.shadowOffsetY,
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: AppDimensions.iconXXL,
                            color: AppColors.warning,
                          ),
                          const SizedBox(height: AppDimensions.spacingL),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeXL,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ゲームIDからアイコンURLを取得（キャッシュ付き）
  Future<String?> _getGameIconUrl(String? gameId) async {
    if (gameId == null || gameId.isEmpty) {
      return null;
    }

    // キャッシュから確認
    if (_gameIconCache.containsKey(gameId)) {
      return _gameIconCache[gameId];
    }

    try {
      final game = await GameService.instance.getGameById(gameId);
      final iconUrl = game?.iconUrl;

      // キャッシュに保存
      _gameIconCache[gameId] = iconUrl;

      return iconUrl;
    } catch (e) {
      // エラーが発生した場合はnullを返してフォールバックアイコンを表示
      _gameIconCache[gameId] = null;
      return null;
    }
  }
}
