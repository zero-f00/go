import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/services/event_cancellation_service.dart';
import '../../../shared/widgets/app_text_field.dart';

/// イベント中止確認ダイアログ
class EventCancellationDialog extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventCancellationDialog({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventCancellationDialog> createState() => _EventCancellationDialogState();
}

class _EventCancellationDialogState extends State<EventCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  int? _selectedReasonIndex;

  /// 定型的な中止理由リストを取得
  List<String> _getPredefinedReasons(L10n l10n) {
    return [
      l10n.eventCancellationReasonOrganizerConvenience,
      l10n.eventCancellationReasonLackOfParticipants,
      l10n.eventCancellationReasonServerNetworkTrouble,
      l10n.eventCancellationReasonGameMaintenance,
      l10n.eventCancellationReasonEmergency,
      l10n.eventCancellationReasonOther,
    ];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(l10n),
                const SizedBox(height: AppDimensions.spacingL),
                _buildWarningMessage(l10n),
                const SizedBox(height: AppDimensions.spacingL),
                _buildReasonSelection(l10n),
                const SizedBox(height: AppDimensions.spacingL),
                _buildCustomReasonInput(l10n),
                const SizedBox(height: AppDimensions.spacingXL),
                _buildActionButtons(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分
  Widget _buildHeader(L10n l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.warning,
            color: AppColors.error,
            size: AppDimensions.iconL,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.eventCancellationDialogTitle,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                widget.eventName,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 警告メッセージ
  Widget _buildWarningMessage(L10n l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.eventCancellationImportantNotice,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.eventCancellationDescription,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.eventCancellationNoticeList,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 中止理由選択
  Widget _buildReasonSelection(L10n l10n) {
    final reasons = _getPredefinedReasons(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.eventCancellationReasonRequired,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: reasons.asMap().entries.map((entry) {
              final index = entry.key;
              final reason = entry.value;
              return RadioListTile<int>(
                title: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
                value: index,
                groupValue: _selectedReasonIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedReasonIndex = value;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// カスタム理由入力
  Widget _buildCustomReasonInput(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.eventCancellationDetailLabel,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AppTextFieldMultiline(
          controller: _reasonController,
          hintText: l10n.eventCancellationDetailHint,
          maxLines: 4,
          maxLength: 500,
          doneButtonText: l10n.doneButtonLabel,
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActionButtons(L10n l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: _isLoading ? l10n.eventCancellationProcessing : l10n.eventCancellationConfirmButton,
            onPressed: _canConfirmCancellation() ? () => _confirmCancellation(l10n) : null,
            type: AppButtonType.danger,
            isEnabled: _canConfirmCancellation() && !_isLoading,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: l10n.cancel,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            type: AppButtonType.secondary,
            isEnabled: !_isLoading,
          ),
        ),
      ],
    );
  }

  /// 中止確認が可能かチェック
  bool _canConfirmCancellation() {
    return _selectedReasonIndex != null;
  }

  /// イベント中止を実行
  Future<void> _confirmCancellation(L10n l10n) async {
    if (!_canConfirmCancellation() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final reasons = _getPredefinedReasons(l10n);
      final selectedReason = reasons[_selectedReasonIndex!];
      final customReason = _reasonController.text.trim();
      final fullReason = customReason.isEmpty
        ? selectedReason
        : '$selectedReason\n\n$customReason';

      final success = await EventCancellationService.cancelEvent(
        eventId: widget.eventId,
        reason: fullReason,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.eventCancellationSuccessMessage),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.eventCancellationFailedMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.eventCancellationErrorMessage(e.toString())),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}