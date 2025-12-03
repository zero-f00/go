import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_tab_bar.dart';
import '../../../shared/widgets/auth_dialog.dart';
import '../../../shared/widgets/user_settings_dialog.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/constants/event_management_types.dart';
import '../../event_creation/views/event_creation_screen.dart';
import '../../../shared/widgets/generic_event_list_screen.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/utils/event_converter.dart' as converter;
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../shared/widgets/past_events_selection_dialog.dart';
import '../../../shared/services/participation_service.dart';
import '../../calendar/views/event_calendar_screen.dart';
import '../../calendar/views/host_event_calendar_screen.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../shared/services/game_service.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  final bool shouldNavigateToEventCreation;
  final VoidCallback? onEventCreationNavigated;

  const ManagementScreen({
    super.key,
    this.shouldNavigateToEventCreation = false,
    this.onEventCreationNavigated,
  });

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with TickerProviderStateMixin {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _participantTabController = TabController(
      length: 2, // 参加予定と過去のイベント
      vsync: this,
    );

    // イベント数を読み込み（初回のため強制読み込み）
    _loadEventCounts(forceRefresh: true);

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

    setState(() {
      _isLoadingCounts = true;
    });

    try {
      // 現在のユーザーを取得
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        setState(() {
          _isLoadingCounts = false;
        });
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

      setState(() {
        _eventCounts = counts;
        _activeEventCounts = activeCounts;
        _lastCountsLoadTime = DateTime.now();
        _isLoadingCounts = false;
      });
    } catch (e) {
      // エラーが発生した場合はデフォルト値を設定
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

  @override
  Widget build(BuildContext context) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final needsInitialSetup = ref.watch(needsInitialSetupProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);

    // サインインしていない場合、サインインダイアログを表示
    if (!isSignedIn) {
      if (!_isDialogShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDialogShowing && mounted) {
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
    // ただし、userDataがローディング中でない場合のみ
    if (needsInitialSetup && currentUser != null) {
      if (!_isDialogShowing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDialogShowing && mounted) {
            _showInitialSetupDialog();
          }
        });
      }
      return _buildAuthRequiredScreen('初回設定が必要です', '初回設定を完了して管理機能を使用してください');
    }

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(title: AppStrings.manageTab, showBackButton: false),
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
    return Container(
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
            _buildQuickActionsSection(),
            const SizedBox(height: AppDimensions.spacingM),
            Expanded(child: _buildManagementOptionsSection()),
          ],
        ),
      ),
    );
  }

  // 参加イベント管理タブ
  Widget _buildParticipantEventTab() {
    return Container(
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
    );
  }

  /// 参加イベント用タブバーとカレンダー表示ボタン
  Widget _buildParticipationTabBar() {
    if (_participantTabController == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        // カレンダー表示ボタン
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: ElevatedButton.icon(
            onPressed: _navigateToCalendar,
            icon: const Icon(Icons.calendar_month, size: 20),
            label: const Text('カレンダー表示'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
        // タブバー
        Container(
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
        ),
      ],
    );
  }

  /// 参加予定のイベントタブ
  Widget _buildUpcomingEventsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: FutureBuilder<UserData?>(
        future: ref.read(currentUserDataProvider.future),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = userSnapshot.data!;
          return FutureBuilder<List<ParticipationApplication>>(
            future: ParticipationService.getUserApplications(currentUser.id),
            builder: (context, applicationSnapshot) {
              if (applicationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!applicationSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allApplications = applicationSnapshot.data!;
              final approvedApplications = allApplications
                  .where((app) => app.status == ParticipationStatus.approved)
                  .toList();

              if (approvedApplications.isEmpty) {
                return _buildEmptyParticipantState(
                  '参加予定のイベントがありません',
                  '新しいイベントに参加してみませんか？',
                  Icons.event_available,
                );
              }
              return FutureBuilder<List<Event>>(
                future: _getEventsFromApplications(
                  approvedApplications,
                  isUpcoming: true,
                ),
                builder: (context, eventsSnapshot) {
                  if (eventsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final upcomingEvents = eventsSnapshot.data ?? [];
                  if (upcomingEvents.isEmpty) {
                    return _buildEmptyParticipantState(
                      '参加予定のイベントがありません',
                      '新しいイベントに参加してみませんか？',
                      Icons.event_available,
                    );
                  }

                  return _buildEventList(upcomingEvents);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 過去のイベントタブ
  Widget _buildPastEventsTab() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: FutureBuilder<UserData?>(
        future: ref.read(currentUserDataProvider.future),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = userSnapshot.data!;
          return FutureBuilder<List<ParticipationApplication>>(
            future: ParticipationService.getUserApplications(currentUser.id),
            builder: (context, applicationSnapshot) {
              if (applicationSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!applicationSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allApplications = applicationSnapshot.data!;
              final approvedApplications = allApplications
                  .where((app) => app.status == ParticipationStatus.approved)
                  .toList();

              if (approvedApplications.isEmpty) {
                return _buildEmptyParticipantState(
                  '参加した過去のイベントがありません',
                  'イベントに参加して実績を積み重ねましょう',
                  Icons.history,
                );
              }
              return FutureBuilder<List<Event>>(
                future: _getEventsFromApplications(
                  approvedApplications,
                  isUpcoming: false,
                ),
                builder: (context, eventsSnapshot) {
                  if (eventsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pastEvents = eventsSnapshot.data ?? [];
                  if (pastEvents.isEmpty) {
                    return _buildEmptyParticipantState(
                      '参加した過去のイベントがありません',
                      'イベントに参加して実績を積み重ねましょう',
                      Icons.history,
                    );
                  }

                  return _buildEventList(pastEvents);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 参加申請からイベントを取得
  Future<List<Event>> _getEventsFromApplications(
    List<ParticipationApplication> applications, {
    required bool isUpcoming,
  }) async {
    final List<Event> events = [];
    final now = DateTime.now();

    for (final application in applications) {
      try {
        final event = await EventService.getEventById(application.eventId);
        if (event != null) {
          // 参加イベントの状態判定
          // - 参加予定：開催日が現在時刻より未来
          // - 過去のイベント：開催日が現在時刻より過去
          // - 申込期限は参加承認後は関係なし

          // 日付比較（時間も含む）
          final currentTime = DateTime.now();
          final isEventInFuture = event.eventDate.isAfter(currentTime);


          if (isUpcoming == isEventInFuture) {
            events.add(event);
          }
        }
      } catch (e) {
        // イベント取得エラーは無視
        print('Debug: Error loading event ${application.eventId}: $e');
      }
    }

    // 参加予定は開催日昇順、過去は開催日降順でソート
    events.sort((a, b) {
      return isUpcoming
          ? a.eventDate.compareTo(b.eventDate)
          : b.eventDate.compareTo(a.eventDate);
    });

    return events;
  }

  /// イベントリスト表示
  Widget _buildEventList(List<Event> events) {
    return ListView.builder(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
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

  /// カレンダー画面に遷移
  void _navigateToCalendar() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null) return;

    try {
      // 現在のユーザーの参加申請を取得
      final applications = await ParticipationService.getUserApplications(
        currentUser.id,
      );

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EventCalendarScreen(applications: applications),
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
    final now = DateTime.now();
    if (event.eventDate.isAfter(now)) {
      return AppColors.info; // 開催予定
    } else {
      return AppColors.textSecondary; // 終了
    }
  }

  /// イベントステータステキストを取得
  String _getEventStatusText(Event event) {
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
          Expanded(
            child: ListView(
              children: [
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
                        _buildStatusChip(
                          '下書き',
                          '0', // TODO: 実際の下書き数を計算
                          Icons.drafts,
                          AppColors.warning,
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
    ).then((_) {
      // イベント作成後にカウントを強制再読み込み
      _loadEventCounts(forceRefresh: true);
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
        ).then((_) {
          // イベント作成後にカウントを強制再読み込み
          _loadEventCounts(forceRefresh: true);
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GenericEventListScreen(
            title: eventType.title,
            events: events,
            isManagementMode: true, // 管理者モードを有効化
            onEventTap: (event) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
            },
            emptyTitle: errorMessage ?? eventType.emptyMessage,
            emptyMessage: errorMessage ?? eventType.emptyDetailMessage,
            searchHint: '${eventType.title}を検索...',
          ),
        ),
      );

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
