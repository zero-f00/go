import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../services/violation_service.dart';
import '../providers/auth_provider.dart';
import 'app_text_field.dart';

/// 違反記録編集ダイアログ
class ViolationEditDialog extends ConsumerStatefulWidget {
  final ViolationRecord violation;

  const ViolationEditDialog({
    super.key,
    required this.violation,
  });

  @override
  ConsumerState<ViolationEditDialog> createState() =>
      _ViolationEditDialogState();
}

class _ViolationEditDialogState extends ConsumerState<ViolationEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  late ViolationType _selectedType;
  late ViolationSeverity _selectedSeverity;
  bool _isSubmitting = false;

  UserData? _violatedUserData;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.violation.violationType;
    _selectedSeverity = widget.violation.severity;
    _descriptionController.text = widget.violation.description;
    _notesController.text = widget.violation.notes ?? '';
    _loadViolatedUserData();
  }

  Future<void> _loadViolatedUserData() async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getUserById(widget.violation.violatedUserId) ??
          await userRepository.getUserByCustomId(widget.violation.violatedUserId);

      if (mounted) {
        setState(() {
          _violatedUserData = userData;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading violated user data: $e');
      if (mounted) {
        setState(() {
          _violatedUserData = null;
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateViolation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final violationService = ref.read(violationServiceProvider);

      await violationService.editViolation(
        violationId: widget.violation.id!,
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
            content: Text('違反記録を更新しました'),
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
                    '違反記録編集',
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
                      // 違反者情報（編集不可）
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                                  if (_isLoadingUserData)
                                    const Text(
                                      'ユーザー情報読み込み中...',
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontSizeM,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    Text(
                                      _violatedUserData?.displayName ?? '不明なユーザー',
                                      style: const TextStyle(
                                        fontSize: AppDimensions.fontSizeM,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (!_isLoadingUserData && _violatedUserData?.username != null && _violatedUserData!.username.isNotEmpty)
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
                                        'ID: @${_violatedUserData!.username}',
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
                      AppTextFieldMultiline(
                        controller: _descriptionController,
                        label: '違反内容の詳細',
                        hintText: '違反の具体的な内容を記載してください',
                        isRequired: true,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '違反内容を入力してください';
                          }
                          if (value.trim().length < 10) {
                            return '10文字以上で詳細を記載してください';
                          }
                          return null;
                        },
                        doneButtonText: '完了',
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
                      AppTextFieldMultiline(
                        controller: _notesController,
                        label: 'メモ（任意）',
                        hintText: '追加情報があれば記載してください',
                        maxLines: 3,
                        doneButtonText: '完了',
                      ),

                      // 変更不可な情報を表示
                      const SizedBox(height: AppDimensions.spacingL),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '変更不可な情報',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingS),
                            Text(
                              '報告日時: ${_formatDateTime(widget.violation.reportedAt)}',
                              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
                            ),
                            Text(
                              '報告者: ${widget.violation.reportedByUserName}',
                              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
                            ),
                            Text(
                              'ステータス: ${widget.violation.status.displayName}',
                              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
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
                    onPressed: _isSubmitting ? null : _updateViolation,
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
                            '更新',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}