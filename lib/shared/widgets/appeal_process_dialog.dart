import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

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
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception('ユーザー情報が取得できません');
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
        final statusText = _selectedStatus == AppealStatus.approved ? '承認' : '却下';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('異議申立を${statusText}しました。申立者に通知されます。'),
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
                    '異議申立処理',
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
                                const Text(
                                  '異議申立内容',
                                  style: TextStyle(
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
                        '処理結果 *',
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
                                '承認',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimensions.fontSizeM,
                                ),
                              ),
                              subtitle: const Text(
                                '異議申立を認め、違反記録を取り消します',
                                style: TextStyle(fontSize: AppDimensions.fontSizeS),
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
                                '却下',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimensions.fontSizeM,
                                ),
                              ),
                              subtitle: const Text(
                                '異議申立を却下し、違反記録を維持します',
                                style: TextStyle(fontSize: AppDimensions.fontSizeS),
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
                        '申立者への回答 *',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      TextFormField(
                        controller: _responseController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '処理結果の理由や詳細を申立者に説明してください',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '申立者への回答を入力してください';
                          }
                          if (value.trim().length < 10) {
                            return '10文字以上で詳細な回答を記載してください';
                          }
                          return null;
                        },
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
                            _selectedStatus == AppealStatus.approved ? '承認する' : '却下する',
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