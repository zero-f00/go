import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'participant_group_view_screen.dart';
import 'participant_list_view_screen.dart';
import 'violation_report_screen.dart';

/// 参加者用メニュー画面
class ParticipantMenuScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ParticipantMenuScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ParticipantMenuScreen> createState() =>
      _ParticipantMenuScreenState();
}

class _ParticipantMenuScreenState extends ConsumerState<ParticipantMenuScreen> {

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentFirebaseUserProvider);

    if (currentUser == null) {
      return Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: L10n.of(context).participantMenuTitle,
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      L10n.of(context).loginRequired,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        color: AppColors.textSecondary,
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

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: L10n.of(context).participantMenuTitle,
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
                      _buildParticipantFeatures(),
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

  Widget _buildEventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventInfoCard(
          eventName: widget.eventName,
          eventId: widget.eventId,
          iconData: Icons.event,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person,
                color: AppColors.success,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                L10n.of(context).participantMode,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantFeatures() {
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
                Icons.menu,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                L10n.of(context).participantFeatures,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildFeatureCard(
            icon: Icons.group,
            title: L10n.of(context).groupInfoTitle,
            subtitle: L10n.of(context).groupInfoDescription,
            color: AppColors.info,
            onTap: () => _navigateToGroupView(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildFeatureCard(
            icon: Icons.people_alt,
            title: L10n.of(context).participantListTitle,
            subtitle: L10n.of(context).participantListDescription,
            color: AppColors.accent,
            onTap: () => _navigateToParticipantsList(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildFeatureCard(
            icon: Icons.report_problem,
            title: L10n.of(context).violationReportMenuTitle,
            subtitle: L10n.of(context).violationReportDescription,
            color: AppColors.warning,
            onTap: () => _navigateToViolationReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
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

  void _navigateToGroupView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantGroupViewScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }

  void _navigateToParticipantsList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantListViewScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }

  void _navigateToViolationReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ViolationReportScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }
}