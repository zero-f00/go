import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'app_text_field.dart';

/// 異議申立処理ダイアログ
class AppealProcessDialog extends ConsumerStatefulWidget {
  final ViolationRecord violation;
  final String eventName;

  const AppealProcessDialog({
    super.key,
    required this.violation,
    required this.eventName,
  });

  @override
  ConsumerState<AppealProcessDialog> createState() => _AppealProcessDialogState();
}

class _AppealProcessDialogState extends ConsumerState<AppealProcessDialog> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  AppealStatus _selectedStatus = AppealStatus.rejected;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _processAppeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final l10n = L10n.of(context);
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception(l10n.userInfoNotAvailable);
      }

      final violationService = ref.read(violationServiceProvider);
      final notificationService = NotificationService.instance;

      // 異議申立を処理
      await violationService.processAppeal(
        violationId: widget.violation.id!,
        appealStatus: _selectedStatus,
        appealResponse: _responseController.text.trim(),
        processorUserId: currentUser.uid,
      );

      // 違反者に処理完了通知を送信
      await notificationService.sendAppealProcessedNotification(
        violatedUserId: widget.violation.violatedUserId,
        eventId: widget.violation.eventId,
        eventName: widget.eventName,
        violationId: widget.violation.id!,
        appealStatus: _selectedStatus.name,
        appealResponse: _responseController.text.trim(),
        processorUserId: currentUser.uid,
      );

      if (mounted && context.mounted) {
        final statusText = _selectedStatus == AppealStatus.approved
            ? l10n.appealApproved
            : l10n.appealRejected;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appealProcessedSuccess(statusText)),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        final l10nError = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nError.errorFormatted(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final maxDialogHeight = screenHeight - keyboardHeight - 100;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: maxDialogHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 固定ヘッダー
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusL),
                  topRight: Radius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.appealProcessDialogTitle,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // スクロール可能なコンテンツ
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 違反記録情報
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.report, color: AppColors.error),
                                const SizedBox(width: AppDimensions.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.violationRecordSectionLabel,
                                        style: const TextStyle(
                                          fontSize: AppDimensions.fontSizeXS,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        widget.violation.violationType.displayName,
                                        style: const TextStyle(
                                          fontSize: AppDimensions.fontSizeM,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingM),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spacingM),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                widget.violation.description,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontSizeM,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 異議申立内容
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.help_outline,
                                  color: AppColors.info,
                                  size: AppDimensions.iconM,
                                ),
                                const SizedBox(width: AppDimensions.spacingM),
                                Text(
                                  l10n.appealContentLabel,
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontSizeM,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingM),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.spacingM),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                border: Border.all(color: AppColors.borderLight),
                              ),
                              child: Text(
                                widget.violation.appealText ?? '',
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontSizeM,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 処理結果選択
                      Text(
                        l10n.processingResultLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(
                                color: _selectedStatus == AppealStatus.approved
                                    ? AppColors.success
                                    : AppColors.borderLight,
                                width: _selectedStatus == AppealStatus.approved ? 2 : 1,
                              ),
                              color: _selectedStatus == AppealStatus.approved
                                  ? AppColors.success.withValues(alpha: 0.05)
                                  : Colors.transparent,
                            ),
                            child: RadioListTile<AppealStatus>(
                              title: Text(
                                l10n.approveLabel,
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimensions.fontSizeM,
                                ),
                              ),
                              subtitle: Text(
                                l10n.approveDescription,
                                style: const TextStyle(fontSize: AppDimensions.fontSizeS),
                              ),
                              value: AppealStatus.approved,
                              groupValue: _selectedStatus,
                              activeColor: AppColors.success,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(
                                color: _selectedStatus == AppealStatus.rejected
                                    ? AppColors.error
                                    : AppColors.borderLight,
                                width: _selectedStatus == AppealStatus.rejected ? 2 : 1,
                              ),
                              color: _selectedStatus == AppealStatus.rejected
                                  ? AppColors.error.withValues(alpha: 0.05)
                                  : Colors.transparent,
                            ),
                            child: RadioListTile<AppealStatus>(
                              title: Text(
                                l10n.rejectLabelDialog,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimensions.fontSizeM,
                                ),
                              ),
                              subtitle: Text(
                                l10n.rejectDescription,
                                style: const TextStyle(fontSize: AppDimensions.fontSizeS),
                              ),
                              value: AppealStatus.rejected,
                              groupValue: _selectedStatus,
                              activeColor: AppColors.error,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 運営者回答
                      Text(
                        l10n.responseToAppellantLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      AppTextFieldMultiline(
                        controller: _responseController,
                        label: l10n.responseToAppellantLabel,
                        hintText: l10n.responseToAppellantHint,
                        isRequired: true,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.enterResponseError;
                          }
                          if (value.trim().length < 10) {
                            return l10n.minCharsResponseError(10);
                          }
                          return null;
                        },
                        doneButtonText: l10n.doneButtonText,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 固定ボタンエリア
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusL),
                  bottomRight: Radius.circular(AppDimensions.radiusL),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancelButtonText),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _processAppeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedStatus == AppealStatus.approved
                          ? AppColors.success
                          : AppColors.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingL,
                        vertical: AppDimensions.spacingM,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _selectedStatus == AppealStatus.approved
                                ? l10n.approveButton
                                : l10n.rejectButton,
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}