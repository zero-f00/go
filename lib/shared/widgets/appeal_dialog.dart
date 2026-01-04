import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';
import 'app_text_field.dart';

/// 異議申立ダイアログ
class AppealDialog extends ConsumerStatefulWidget {
  final ViolationRecord violation;
  final String eventName;

  const AppealDialog({
    super.key,
    required this.violation,
    required this.eventName,
  });

  @override
  ConsumerState<AppealDialog> createState() => _AppealDialogState();
}

class _AppealDialogState extends ConsumerState<AppealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _appealTextController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _appealTextController.dispose();
    super.dispose();
  }

  Future<void> _submitAppeal() async {
    final l10n = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception(l10n.cannotGetUserInfo);
      }

      final violationService = ref.read(violationServiceProvider);
      final notificationService = NotificationService.instance;

      // 異議申立を提出
      await violationService.submitAppeal(
        violationId: widget.violation.id!,
        appealText: _appealTextController.text.trim(),
        appellantUserId: currentUser.uid,
      );

      // 運営者に通知を送信
      await notificationService.sendAppealSubmittedNotification(
        eventId: widget.violation.eventId,
        eventName: widget.eventName,
        violationId: widget.violation.id!,
        appealText: _appealTextController.text.trim(),
        appellantUserId: currentUser.uid,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.appealSubmittedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithDetails(e.toString())),
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
                    l10n.appealDialogTitle,
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
                                        l10n.violationRecordLabel,
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

                      // 異議申立理由
                      Text(
                        l10n.appealReasonLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      AppTextFieldMultiline(
                        controller: _appealTextController,
                        label: l10n.appealReasonLabel,
                        hintText: l10n.appealReasonHint,
                        isRequired: true,
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.appealReasonRequired;
                          }
                          if (value.trim().length < 20) {
                            return l10n.appealReasonMinLength;
                          }
                          return null;
                        },
                        doneButtonText: l10n.done,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 注意事項
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
                                  Icons.info_outline,
                                  color: AppColors.info,
                                  size: AppDimensions.iconS,
                                ),
                                const SizedBox(width: AppDimensions.spacingS),
                                Text(
                                  l10n.aboutAppeal,
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontSizeS,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingS),
                            Text(
                              '• ${l10n.appealNote1}\n'
                              '• ${l10n.appealNote2}\n'
                              '• ${l10n.appealNote3}\n'
                              '• ${l10n.appealNote4}',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
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
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAppeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                            l10n.submitAppeal,
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