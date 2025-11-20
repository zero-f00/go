import 'package:flutter/material.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabLabels = [
    AppStrings.hostEventTab,
    AppStrings.participantEventTab,
  ];

  // イベント数のキャッシュ
  Map<EventManagementType, int> _eventCounts = {};
  Map<EventManagementType, int> _activeEventCounts = {};
  bool _isLoadingCounts = false;
  DateTime? _lastCountsLoadTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabLabels.length,
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
      print('🔍 ManagementScreen: _loadEventCounts開始');

      // 現在のユーザーを取得
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        print('❌ ManagementScreen: ユーザー情報が取得できませんでした');
        setState(() {
          _isLoadingCounts = false;
        });
        return;
      }

      print('✅ ManagementScreen: ユーザー情報取得成功 - ID: ${currentUser.id}');

      // ユーザーのすべてのイベントを取得
      print('🔍 ManagementScreen: EventService.getUserCreatedEventsを呼び出し中...');
      final userEvents = await EventService.getUserCreatedEvents(currentUser.id);
      print('✅ ManagementScreen: イベント取得成功 - 件数: ${userEvents.length}');

      // 各イベントのゲーム情報を詳細ログ
      for (int i = 0; i < userEvents.length; i++) {
        final event = userEvents[i];
        print('📊 ManagementScreen: Event $i - ID: ${event.id}');
        print('📊 ManagementScreen: Event $i - Name: ${event.name}');
        print('🎮 ManagementScreen: Event $i - GameId: ${event.gameId}');
        print('🎮 ManagementScreen: Event $i - GameName: ${event.gameName}');
        print('🎮 ManagementScreen: Event $i - Platforms: ${event.platforms}');
      }

      // 各タイプ別にイベント数をカウント
      final Map<EventManagementType, int> counts = {};
      final Map<EventManagementType, int> activeCounts = {};

      for (final eventType in EventManagementType.values) {
        print('🔍 ManagementScreen: ${eventType.name}のフィルタリング開始');
        final filteredEvents = await converter.EventConverter.filterEventsByManagementType(
          userEvents,
          currentUser.id,
          eventType,
        );

        counts[eventType] = filteredEvents.length;
        print('📊 ManagementScreen: ${eventType.name} - 合計: ${filteredEvents.length}件');

        // アクティブなイベント数をカウント（開催中または開催予定）
        final activeEvents = filteredEvents.where((event) =>
          event.status == GameEventStatus.active ||
          event.status == GameEventStatus.upcoming
        ).length;

        activeCounts[eventType] = activeEvents;
        print('📊 ManagementScreen: ${eventType.name} - アクティブ: $activeEvents件');
      }

      setState(() {
        _eventCounts = counts;
        _activeEventCounts = activeCounts;
        _lastCountsLoadTime = DateTime.now();
        _isLoadingCounts = false;
      });
    } catch (e, stackTrace) {
      print('❌ ManagementScreen: _loadEventCounts エラー: $e');
      print('📋 ManagementScreen: スタックトレース: $stackTrace');

      // エラーが発生した場合はデフォルト値を設定
      setState(() {
        _eventCounts = {
          for (final eventType in EventManagementType.values)
            eventType: 0
        };
        _activeEventCounts = {
          for (final eventType in EventManagementType.values)
            eventType: 0
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

    print('🏗️ ManagementScreen Build:');
    print('   - isSignedIn: $isSignedIn');
    print('   - needsInitialSetup: $needsInitialSetup');
    print('   - currentUser: ${currentUser?.email}');
    print('   - userDataAsync state: ${userDataAsync.runtimeType}');

    // サインインしていない場合、サインインダイアログを表示
    if (!isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSignInDialog();
      });
      return _buildAuthRequiredScreen('サインインが必要です', 'サインインして管理機能を使用してください');
    }

    // ユーザーデータがローディング中の場合は待機画面を表示
    if (userDataAsync is AsyncLoading) {
      print('🔄 ManagementScreen: User data is loading - showing loading screen');
      return _buildLoadingScreen();
    }

    // サインイン済みだが初回設定が未完了の場合、初回設定ダイアログを表示
    // ただし、userDataがローディング中でない場合のみ
    if (needsInitialSetup && currentUser != null) {
      print('⚠️ ManagementScreen: Showing initial setup dialog');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitialSetupDialog();
      });
      return _buildAuthRequiredScreen('初回設定が必要です', '初回設定を完了して管理機能を使用してください');
    }

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: AppStrings.manageTab,
                showBackButton: false,
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
                  children: [
                    _buildHostEventTab(),
                    _buildParticipantEventTab(),
                  ],
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
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildQuickActionsSection(),
          const SizedBox(height: AppDimensions.spacingM),
          Expanded(
            child: _buildManagementOptionsSection(),
          ),
        ],
      ),
    );
  }

  // 参加イベント管理タブ
  Widget _buildParticipantEventTab() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildParticipationStatsSection(),
          const SizedBox(height: AppDimensions.spacingL),
          Expanded(
            child: _buildParticipatingEventsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
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
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildActionButton(
                  title: '前回のイベントをコピー',
                  icon: Icons.content_copy,
                  color: AppColors.info,
                  onTap: () {
                    // TODO: 前回のイベントをコピーして作成画面へ遷移
                  },
                ),
              ),
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
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: AppDimensions.iconL,
              ),
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
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
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
                Icon(
                  icon,
                  size: 12,
                  color: color,
                ),
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
                  activeCount: _activeEventCounts[EventManagementType.createdEvents],
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
                  count: _eventCounts[EventManagementType.collaborativeEvents] ?? 0,
                  activeCount: _activeEventCounts[EventManagementType.collaborativeEvents],
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
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
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
                    Row(
                      children: [
                        _buildStatusChip(
                          '合計',
                          count.toString(),
                          Icons.event,
                          AppColors.info,
                          _isLoadingCounts,
                        ),
                        if (activeCount != null) ...[
                          const SizedBox(width: AppDimensions.spacingXS),
                          _buildStatusChip(
                            '公開中',
                            activeCount.toString(),
                            Icons.public,
                            AppColors.success,
                            _isLoadingCounts,
                          ),
                        ],
                        const SizedBox(width: AppDimensions.spacingXS),
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


  Widget _buildParticipationStatsSection() {
    return Container(
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
              Icon(
                Icons.analytics,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '参加状況',
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
                child: _buildStatCard(
                  title: '参加中',
                  value: '8',
                  subtitle: 'イベント',
                  icon: Icons.event_available,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildStatCard(
                  title: '完了',
                  value: '24',
                  subtitle: 'イベント',
                  icon: Icons.check_circle,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: '獲得報酬',
                  value: '1,250',
                  subtitle: 'ポイント',
                  icon: Icons.stars,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildStatCard(
                  title: '達成率',
                  value: '92.5',
                  subtitle: '%',
                  icon: Icons.trending_up,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingXS / 2),
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS / 2),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticipatingEventsSection() {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    color: AppColors.accent,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Text(
                    '参加イベント',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: 全参加イベント一覧へ遷移
                },
                child: const Text(
                  'すべて見る',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Expanded(
            child: ListView(
              children: [
                _buildEventCard(
                  title: 'ウィークリーチャレンジ',
                  status: '参加中',
                  statusColor: AppColors.success,
                  progress: 0.75,
                  reward: 'コイン x100',
                  deadline: '3日後',
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildEventCard(
                  title: 'スペシャルミッション',
                  status: '参加中',
                  statusColor: AppColors.success,
                  progress: 0.45,
                  reward: 'ジェム x50',
                  deadline: '7日後',
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildEventCard(
                  title: 'シーズンイベント',
                  status: '完了',
                  statusColor: AppColors.statusCompleted,
                  progress: 1.0,
                  reward: 'トロフィー x1',
                  deadline: '完了済み',
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.more_horiz,
                        size: AppDimensions.iconL,
                        color: AppColors.overlayMedium,
                      ),
                      SizedBox(height: AppDimensions.spacingS),
                      Text(
                        'さらに多くのイベント',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '「すべて見る」で全参加イベントを確認',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String status,
    required Color statusColor,
    required double progress,
    required String reward,
    required String deadline,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
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
                  vertical: AppDimensions.spacingXS / 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '進捗',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.backgroundDark,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 4,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.redeem,
                    size: AppDimensions.iconS,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(
                    reward,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: AppDimensions.iconS,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(
                    deadline,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToEventCreation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventCreationScreen(),
      ),
    ).then((_) {
      // イベント作成後にカウントを強制再読み込み
      _loadEventCounts(forceRefresh: true);
    });
  }

  Future<void> _navigateToEventList(BuildContext context, EventManagementType eventType) async {
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
          final userEvents = await EventService.getUserCreatedEvents(currentUser.id);
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
    final result = await AuthDialog.show(context);
    if (result == true) {
      // サインイン成功後、状態が更新されるまで待機
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  /// 初回設定ダイアログを表示
  Future<void> _showInitialSetupDialog() async {
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
  }

  /// ローディング状態を示す画面を構築
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: AppStrings.manageTab,
                showBackButton: false,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXL),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: AppDimensions.cardElevation,
                            offset: const Offset(0, AppDimensions.shadowOffsetY),
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
              AppHeader(
                title: AppStrings.manageTab,
                showBackButton: false,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXL),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: AppDimensions.cardElevation,
                            offset: const Offset(0, AppDimensions.shadowOffsetY),
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
}