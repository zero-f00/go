import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/event_deletion_service.dart';
import '../../../data/models/event_model.dart';
import '../widgets/event_cancellation_dialog.dart';
import '../widgets/event_deletion_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// イベント運営ダッシュボード画面
class EventOperationsDashboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool shouldNavigateToParticipantManagement;
  final bool fromParticipantManagement;

  const EventOperationsDashboardScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.shouldNavigateToParticipantManagement = false,
    this.fromParticipantManagement = false,
  });

  @override
  ConsumerState<EventOperationsDashboardScreen> createState() =>
      _EventOperationsDashboardScreenState();
}

class _EventOperationsDashboardScreenState
    extends ConsumerState<EventOperationsDashboardScreen> {
  Event? _event;
  bool _isLoading = true;
  EventDeletionCheck? _deletionCheck;

  @override
  void initState() {
    super.initState();
    _loadEventData();

    // 通知画面から参加者管理への遷移フラグがある場合、
    // 画面描画後に参加者管理画面に遷移する
    if (widget.shouldNavigateToParticipantManagement) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToParticipantManagement();
      });
    }
  }

  /// イベントデータを読み込み
  Future<void> _loadEventData() async {
    try {
      final event = await EventService.getEventById(widget.eventId);
      if (event != null && mounted) {
        // 削除可否チェックを実行
        final deletionCheck =
            await EventDeletionService.canDeleteEvent(widget.eventId);
        setState(() {
          _event = event;
          _deletionCheck = deletionCheck;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 戻るボタンの処理
  void _handleBackPressed() {
    if (widget.fromParticipantManagement) {
      // 参加者管理画面からの遷移の場合はイベント詳細画面に置き換え
      Navigator.of(context).pushReplacementNamed(
        '/event_detail',
        arguments: widget.eventId, // EventDetailWrapperはStringのeventIdを期待
      );
    } else {
      // 通常の戻る動作
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: L10n.of(context).operationsDashboard,
                showBackButton: true,
                onBackPressed: () => _handleBackPressed(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventInfo(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildQuickActions(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildManagementSections(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// イベント情報カード
  Widget _buildEventInfo() {
    return Container(
      width: double.infinity,
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
                Icons.event,
                color: AppColors.accent,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  widget.eventName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.accent,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  L10n.of(context).operationsMode,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// クイックアクション
  Widget _buildQuickActions() {
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
              Text(
                L10n.of(context).quickActions,
                style: const TextStyle(
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
                child: _buildQuickActionCard(
                  icon: Icons.group_add,
                  title: L10n.of(context).dashboardParticipants,
                  subtitle: L10n.of(context).dashboardApproveReject,
                  color: AppColors.success,
                  onTap: () => _navigateToParticipantManagement(),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.groups,
                  title: L10n.of(context).dashboardGroupAssignment,
                  subtitle: L10n.of(context).dashboardRoomAllocation,
                  color: AppColors.info,
                  onTap: () => _navigateToGroupManagement(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildCancellationActionCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// クイックアクションカード
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
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

  /// 管理セクション
  Widget _buildManagementSections() {
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
              Text(
                L10n.of(context).dashboardManagementMenu,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildManagementCard(
            icon: Icons.people_alt,
            title: L10n.of(context).dashboardParticipantsTitle,
            subtitle: L10n.of(context).dashboardParticipantsDesc,
            onTap: () => _navigateToParticipantManagement(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementCard(
            icon: Icons.group_work,
            title: L10n.of(context).dashboardGroupTitle,
            subtitle: L10n.of(context).dashboardGroupDesc,
            onTap: () => _navigateToGroupManagement(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementCard(
            icon: Icons.leaderboard,
            title: L10n.of(context).dashboardResultsTitle,
            subtitle: L10n.of(context).dashboardResultsDesc,
            onTap: () => _navigateToResultManagement(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementCard(
            icon: Icons.report_problem,
            title: L10n.of(context).dashboardViolationTitle,
            subtitle: L10n.of(context).dashboardViolationDesc,
            onTap: () => _navigateToViolationManagement(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildManagementCard(
            icon: Icons.person_search,
            title: L10n.of(context).dashboardUserDetailTitle,
            subtitle: L10n.of(context).dashboardUserDetailDesc,
            onTap: () => _navigateToUserDetailManagement(),
          ),
          // TODO: 参加費管理機能はリリース後にアップデートで対応予定
          // const SizedBox(height: AppDimensions.spacingM),
          // _buildManagementCard(
          //   icon: Icons.payment,
          //   title: '参加費管理',
          //   subtitle: '支払い状況確認、証跡管理、収支管理',
          //   onTap: () => _navigateToPaymentManagement(),
          // ),
        ],
      ),
    );
  }

  /// 管理カード
  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
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

  /// 画面遷移メソッド群
  void _navigateToParticipantManagement() {
    Navigator.of(context).pushNamed(
      '/event_participants_management',
      arguments: {'eventId': widget.eventId, 'eventName': widget.eventName},
    );
  }

  void _navigateToGroupManagement() {
    Navigator.of(context).pushNamed(
      '/group_management',
      arguments: {'eventId': widget.eventId, 'eventName': widget.eventName},
    );
  }

  void _navigateToResultManagement() {
    Navigator.of(context).pushNamed(
      '/result_management',
      arguments: {'eventId': widget.eventId, 'eventName': widget.eventName},
    );
  }

  void _navigateToViolationManagement() {
    Navigator.of(context).pushNamed(
      '/violation_management',
      arguments: {'eventId': widget.eventId, 'eventName': widget.eventName},
    );
  }

  void _navigateToUserDetailManagement() {
    Navigator.of(context).pushNamed(
      '/user_detail_management',
      arguments: {'eventId': widget.eventId, 'eventName': widget.eventName},
    );
  }



  /// イベント削除/中止アクションカード
  Widget _buildCancellationActionCard() {
    if (_isLoading || _event == null) {
      return _buildQuickActionCard(
        icon: Icons.more_horiz,
        title: L10n.of(context).dashboardLoading,
        subtitle: '',
        color: AppColors.textLight,
        onTap: () {},
      );
    }

    final isCancelled = _event!.status == EventStatus.cancelled;
    final isCompleted = _event!.status == EventStatus.completed;

    // 中止済みまたは完了済みの場合は操作不可
    if (isCancelled) {
      return _buildQuickActionCard(
        icon: Icons.cancel_outlined,
        title: L10n.of(context).dashboardCancelled,
        subtitle: '',
        color: AppColors.textSecondary,
        onTap: () {},
      );
    }

    if (isCompleted) {
      return _buildQuickActionCard(
        icon: Icons.check_circle_outline,
        title: L10n.of(context).dashboardCompleted,
        subtitle: '',
        color: AppColors.textSecondary,
        onTap: () {},
      );
    }

    // 削除可能な場合（下書き or 参加申込者0人の公開イベント）
    if (_deletionCheck?.canDelete == true) {
      return _buildQuickActionCard(
        icon: Icons.delete_forever,
        title: L10n.of(context).dashboardDeleteEvent,
        subtitle: '',
        color: AppColors.error,
        onTap: () => _showEventDeletionDialog(),
      );
    }

    // 削除不可（参加申込者がいる公開イベント）は中止を表示
    return _buildQuickActionCard(
      icon: Icons.cancel,
      title: L10n.of(context).dashboardCancelEvent,
      subtitle: '',
      color: AppColors.error,
      onTap: () => _showEventCancellationDialog(),
    );
  }

  /// イベント中止確認ダイアログを表示
  void _showEventCancellationDialog() {
    showDialog(
      context: context,
      builder: (context) => EventCancellationDialog(
        eventId: widget.eventId,
        eventName: widget.eventName,
      ),
    );
  }

  /// イベント削除確認ダイアログを表示
  void _showEventDeletionDialog() async {
    final isDraft = _deletionCheck?.isDraft ?? false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EventDeletionDialog(
        eventId: widget.eventId,
        eventName: widget.eventName,
        isDraft: isDraft,
      ),
    );

    // 削除が成功した場合、画面を閉じてイベント一覧に戻る
    if (result == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
