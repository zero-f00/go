import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception('ユーザー情報が取得できません');
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
          const SnackBar(
            content: Text('異議申立を提出しました。運営からの回答をお待ちください。'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
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
                  const Text(
                    '異議申立',
                    style: TextStyle(
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
                                      const Text(
                                        '違反記録',
                                        style: TextStyle(
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
                        '異議申立の理由 *',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      TextFormField(
                        controller: _appealTextController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: '違反報告に対する異議の理由を詳しく記載してください\n\n例：\n・状況についての説明\n・誤解があった場合の詳細\n・証拠となる情報\n・その他関連する事実',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '異議申立の理由を入力してください';
                          }
                          if (value.trim().length < 20) {
                            return '20文字以上で詳細な理由を記載してください';
                          }
                          return null;
                        },
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
                                const Text(
                                  '異議申立について',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeS,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.info,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingS),
                            Text(
                              '• 運営チームが内容を審査し、回答いたします\n'
                              '• 審査には数日かかる場合があります\n'
                              '• 虚偽の申立は新たな違反行為とみなされます\n'
                              '• 一度提出した異議申立は取り消しできません',
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
                    child: const Text('キャンセル'),
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
                        : const Text(
                            '異議申立を提出',
                            style: TextStyle(color: Colors.white),
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