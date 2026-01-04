import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/services/match_report_service.dart';
import '../../../data/models/match_result_model.dart';
import '../../../l10n/app_localizations.dart';

/// 試合報告ステータス更新ダイアログ
class MatchReportStatusDialog extends StatefulWidget {
  final MatchReport report;
  final MatchResult? matchResult;
  final String adminId;

  const MatchReportStatusDialog({
    super.key,
    required this.report,
    this.matchResult,
    required this.adminId,
  });

  @override
  State<MatchReportStatusDialog> createState() => _MatchReportStatusDialogState();
}

class _MatchReportStatusDialogState extends State<MatchReportStatusDialog> {
  final MatchReportService _reportService = MatchReportService();
  final TextEditingController _responseController = TextEditingController();

  MatchReportStatus _selectedStatus = MatchReportStatus.reviewing;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 現在のステータスに応じて初期値を設定
    if (widget.report.status == MatchReportStatus.submitted) {
      _selectedStatus = MatchReportStatus.reviewing;
    } else if (widget.report.status == MatchReportStatus.reviewing) {
      _selectedStatus = MatchReportStatus.resolved;
    } else {
      _selectedStatus = widget.report.status;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  /// ステータス更新を実行
  Future<void> _updateStatus() async {
    final l10n = L10n.of(context);
    // バリデーション
    if (_selectedStatus == widget.report.status) {
      setState(() {
        _errorMessage = l10n.pleaseChangeStatus;
      });
      return;
    }

    // 解決済み・却下の場合はコメント必須
    if ((_selectedStatus == MatchReportStatus.resolved ||
            _selectedStatus == MatchReportStatus.rejected) &&
        _responseController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = l10n.pleaseEnterResponse;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _reportService.updateReportStatus(
        reportId: widget.report.id!,
        status: _selectedStatus,
        adminId: widget.adminId,
        adminResponse: _responseController.text.trim().isNotEmpty
            ? _responseController.text.trim()
            : null,
      );

      if (mounted) {
        // 成功時はダイアログを閉じる
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.statusUpdatedMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n.updateFailedMessage(e.toString());
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
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
                    Icons.edit_note,
                    color: AppColors.primary,
                    size: AppDimensions.iconL,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Text(
                    l10n.reportResponseTitle,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (!_isProcessing)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const Divider(height: AppDimensions.spacingXL),

              // 試合情報
              if (widget.matchResult != null) ...[
                _buildInfoRow(
                  icon: Icons.sports_esports,
                  label: l10n.matchLabel,
                  value: widget.matchResult!.matchName,
                ),
                const SizedBox(height: AppDimensions.spacingM),
              ],

              // 問題の種類
              _buildInfoRow(
                icon: Icons.warning_amber,
                label: l10n.problemLabel,
                value: widget.report.issueType,
              ),
              const SizedBox(height: AppDimensions.spacingXL),

              // ステータス選択
              Text(
                l10n.statusChangeTitle,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildStatusOptions(),

              const SizedBox(height: AppDimensions.spacingXL),

              // 対応内容入力
              Text(
                l10n.responseContentLabel,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                _selectedStatus == MatchReportStatus.resolved ||
                        _selectedStatus == MatchReportStatus.rejected
                    ? l10n.requiredMark
                    : l10n.optionalMark,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: _responseController,
                maxLines: 4,
                enabled: !_isProcessing,
                decoration: InputDecoration(
                  hintText: l10n.responseContentHint,
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              // エラーメッセージ
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: AppDimensions.iconS,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
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
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingM,
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: _isProcessing
                              ? AppColors.textLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  // 更新ボタン
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _updateStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.updateButton,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 情報行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  /// ステータスオプション
  Widget _buildStatusOptions() {
    return Column(
      children: [
        // 確認中
        _buildStatusOption(
          status: MatchReportStatus.reviewing,
          icon: Icons.visibility,
          color: AppColors.info,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // 解決済み
        _buildStatusOption(
          status: MatchReportStatus.resolved,
          icon: Icons.check_circle,
          color: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // 却下
        _buildStatusOption(
          status: MatchReportStatus.rejected,
          icon: Icons.cancel,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  /// ステータスオプション単体
  Widget _buildStatusOption({
    required MatchReportStatus status,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == status;
    final isCurrent = widget.report.status == status;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing || isCurrent ? null : () {
          setState(() {
            _selectedStatus = status;
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconM,
                color: isCurrent
                    ? AppColors.textLight
                    : (isSelected ? color : AppColors.textSecondary),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.getDisplayName(context),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.textLight
                            : (isSelected ? color : AppColors.textDark),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        L10n.of(context).currentStatusLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: AppDimensions.iconM,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}