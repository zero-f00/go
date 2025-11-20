import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';

/// イベント運営ダッシュボード画面
class EventOperationsDashboardScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const EventOperationsDashboardScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<EventOperationsDashboardScreen> createState() =>
      _EventOperationsDashboardScreenState();
}

class _EventOperationsDashboardScreenState
    extends ConsumerState<EventOperationsDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '運営ダッシュボード',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
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
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
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
                  '運営モード',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.group_add,
                title: '参加者管理',
                subtitle: '承認・拒否',
                color: AppColors.success,
                onTap: () => _navigateToParticipantManagement(),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.groups,
                title: 'グループ分け',
                subtitle: '部屋割り当て',
                color: AppColors.info,
                onTap: () => _navigateToGroupManagement(),
              ),
            ),
          ],
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 管理セクション
  Widget _buildManagementSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '運営管理メニュー',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.people_alt,
          title: '参加者管理',
          subtitle: '参加申請の承認・拒否、参加者一覧',
          onTap: () => _navigateToParticipantManagement(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.group_work,
          title: 'グループ・部屋管理',
          subtitle: 'チーム分け、通話ツール部屋割り当て',
          onTap: () => _navigateToGroupManagement(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.leaderboard,
          title: '戦績・結果管理',
          subtitle: '試合結果入力、順位管理、統計',
          onTap: () => _navigateToResultManagement(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.report_problem,
          title: '違反管理',
          subtitle: '違反記録、警告管理、ペナルティ',
          onTap: () => _navigateToViolationManagement(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.person_search,
          title: 'ユーザー詳細管理',
          subtitle: '参加履歴、詳細情報、総合評価',
          onTap: () => _navigateToUserDetailManagement(),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildManagementCard(
          icon: Icons.payment,
          title: '参加費管理',
          subtitle: '支払い状況確認、証跡管理、収支管理',
          onTap: () => _navigateToPaymentManagement(),
        ),
      ],
    );
  }

  /// 管理カード
  Widget _buildManagementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
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
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ],
        ),
      ),
    );
  }

  /// 画面遷移メソッド群
  void _navigateToParticipantManagement() {
    Navigator.of(context).pushNamed(
      '/event_participants_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  void _navigateToGroupManagement() {
    Navigator.of(context).pushNamed(
      '/group_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  void _navigateToResultManagement() {
    Navigator.of(context).pushNamed(
      '/result_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  void _navigateToViolationManagement() {
    Navigator.of(context).pushNamed(
      '/violation_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  void _navigateToUserDetailManagement() {
    Navigator.of(context).pushNamed(
      '/user_detail_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  void _navigateToPaymentManagement() {
    Navigator.of(context).pushNamed(
      '/payment_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }
}