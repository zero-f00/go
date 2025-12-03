import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../providers/auth_provider.dart';

/// 違反報告ダイアログ
class ViolationReportDialog extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final String violatedUserId;
  final String violatedUserName;
  final String? violatedUserGameUsername;

  const ViolationReportDialog({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.violatedUserId,
    required this.violatedUserName,
    this.violatedUserGameUsername,
  });

  @override
  ConsumerState<ViolationReportDialog> createState() =>
      _ViolationReportDialogState();
}

class _ViolationReportDialogState
    extends ConsumerState<ViolationReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  ViolationType _selectedType = ViolationType.other;
  ViolationSeverity _selectedSeverity = ViolationSeverity.minor;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
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

      await violationService.reportViolation(
        eventId: widget.eventId,
        eventName: widget.eventName,
        violatedUserId: widget.violatedUserId,
        reportedByUserId: currentUser.uid,
        violationType: _selectedType,
        description: _descriptionController.text.trim(),
        severity: _selectedSeverity,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('違反報告を送信しました'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // 成功を示すtrueを返す
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
    final maxDialogHeight = screenHeight - keyboardHeight - 100; // 画面上下に50pxずつマージン

    return Dialog(
      backgroundColor: AppColors.backgroundLight,
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
                color: AppColors.backgroundLight,
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
                    '違反報告',
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
              child: Container(
                color: AppColors.backgroundLight,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 報告対象ユーザー
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.textSecondary),
                            const SizedBox(width: AppDimensions.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '報告対象',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeXS,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    widget.violatedUserName,
                                    style: const TextStyle(
                                      fontSize: AppDimensions.fontSizeM,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.violatedUserGameUsername != null && widget.violatedUserGameUsername!.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: AppDimensions.spacingXS),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingS,
                                        vertical: AppDimensions.spacingXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        widget.violatedUserGameUsername!,
                                        style: TextStyle(
                                          fontSize: AppDimensions.fontSizeS,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 違反タイプ
                      Text(
                        '違反の種類 *',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      DropdownButtonFormField<ViolationType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                        items: ViolationType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 重要度
                      Text(
                        '重要度 *',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      DropdownButtonFormField<ViolationSeverity>(
                        value: _selectedSeverity,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingM,
                            vertical: AppDimensions.spacingM,
                          ),
                        ),
                        items: ViolationSeverity.values.map((severity) {
                          return DropdownMenuItem(
                            value: severity,
                            child: Text(
                              severity.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSeverity = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // 説明
                      Text(
                        '違反内容の詳細 *',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '違反の具体的な内容を記載してください',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '違反内容を入力してください';
                          }
                          if (value.trim().length < 10) {
                            return '10文字以上で詳細を記載してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // メモ（任意）
                      Text(
                        'メモ（任意）',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingS),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '追加情報があれば記載してください',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),

            // 固定ボタンエリア
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
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
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
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
                            '報告する',
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