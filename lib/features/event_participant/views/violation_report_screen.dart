import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/widgets/user_selection_violation_modal.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

/// 参加者用違反報告画面
class ViolationReportScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ViolationReportScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ViolationReportScreen> createState() =>
      _ViolationReportScreenState();
}

class _ViolationReportScreenState extends ConsumerState<ViolationReportScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final l10n = L10n.of(context);

    if (currentUser == null) {
      return Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: l10n.violationReport,
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      l10n.homeLoginRequiredShort,
                      style: const TextStyle(
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
                title: l10n.violationReport,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                iconData: Icons.report_problem,
                iconColor: AppColors.warning,
              ),
              Expanded(
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingL),
                        child: Row(
                          children: [
                            Icon(
                              Icons.report_problem,
                              color: AppColors.warning,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text(
                              l10n.violationReport,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppDimensions.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInformationSection(),
                              const SizedBox(height: AppDimensions.spacingL),
                              _buildReportSection(),
                              const SizedBox(height: AppDimensions.spacingL),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildInformationSection() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aboutViolationReport,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.importantNotesForProperUse,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportPrecautions,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '• ${l10n.violationReportPrecaution1}\n'
                  '• ${l10n.violationReportPrecaution2}\n'
                  '• ${l10n.violationReportPrecaution3}\n'
                  '• ${l10n.violationReportPrecaution4}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.report_problem,
                  color: AppColors.warning,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.createViolationReport,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.selectParticipantToReport,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showViolationReportModal(),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_note,
                        color: AppColors.warning,
                        size: AppDimensions.iconM,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        l10n.startViolationReport,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showViolationReportModal() {
    UserSelectionViolationModal.show(
      context: context,
      eventId: widget.eventId,
      eventName: widget.eventName,
      onViolationReported: () {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.violationReportSubmitted),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }
}