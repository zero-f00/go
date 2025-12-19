import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/services/match_report_service.dart';
import '../../../data/models/match_result_model.dart';

/// 試合報告詳細ダイアログ
class MatchReportDetailDialog extends StatelessWidget {
  final MatchReport report;
  final MatchResult? matchResult;
  final String eventId;
  final String eventName;
  final VoidCallback onStatusUpdate;

  const MatchReportDetailDialog({
    super.key,
    required this.report,
    this.matchResult,
    required this.eventId,
    required this.eventName,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              Row(
                children: [
                  Icon(
                    Icons.report,
                    color: AppColors.primary,
                    size: AppDimensions.iconL,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  const Text(
                    '報告詳細',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const Divider(height: AppDimensions.spacingXL),

              // ステータス
              _buildInfoSection(
                icon: _getStatusIcon(report.status),
                label: 'ステータス',
                content: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    report.status.displayName,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(report.status),
                    ),
                  ),
                ),
              ),

              // 試合情報
              if (matchResult != null) ...[
                _buildInfoSection(
                  icon: Icons.sports_esports,
                  label: '試合名',
                  content: Text(
                    matchResult!.matchName,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],

              // 問題の種類
              _buildInfoSection(
                icon: Icons.warning_amber,
                label: '問題の種類',
                content: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    report.issueType,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ),

              // 報告日時
              _buildInfoSection(
                icon: Icons.access_time,
                label: '報告日時',
                content: Text(
                  _formatFullDateTime(report.createdAt),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
              ),

              // 詳細説明
              _buildInfoSection(
                icon: Icons.description,
                label: '詳細説明',
                content: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    report.description,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ),

              // 管理者の対応
              if (report.adminResponse != null) ...[
                _buildInfoSection(
                  icon: Icons.admin_panel_settings,
                  label: '運営からの回答',
                  content: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.adminResponse!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textDark,
                            height: 1.5,
                          ),
                        ),
                        if (report.updatedAt.isAfter(report.createdAt)) ...[
                          const SizedBox(height: AppDimensions.spacingS),
                          Text(
                            '対応日時: ${_formatFullDateTime(report.updatedAt)}',
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppDimensions.spacingXL),

              // アクションボタン
              Row(
                children: [
                  // キャンセルボタン
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingM,
                        ),
                      ),
                      child: const Text(
                        '閉じる',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  // 対応ボタン（未対応の場合のみ表示）
                  if (report.status != MatchReportStatus.resolved &&
                      report.status != MatchReportStatus.rejected) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onStatusUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                        ),
                        child: const Text(
                          '対応する',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 情報セクション
  Widget _buildInfoSection({
    required IconData icon,
    required String label,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          content,
        ],
      ),
    );
  }

  /// ステータスの色を取得
  Color _getStatusColor(MatchReportStatus status) {
    switch (status) {
      case MatchReportStatus.submitted:
        return AppColors.warning;
      case MatchReportStatus.reviewing:
        return AppColors.info;
      case MatchReportStatus.resolved:
        return AppColors.success;
      case MatchReportStatus.rejected:
        return AppColors.textSecondary;
    }
  }

  /// ステータスアイコンを取得
  IconData _getStatusIcon(MatchReportStatus status) {
    switch (status) {
      case MatchReportStatus.submitted:
        return Icons.report_outlined;
      case MatchReportStatus.reviewing:
        return Icons.visibility;
      case MatchReportStatus.resolved:
        return Icons.check_circle;
      case MatchReportStatus.rejected:
        return Icons.cancel;
    }
  }

  /// 完全な日時フォーマット
  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}