import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/violation_record_model.dart';
import '../services/violation_service.dart';
import '../providers/auth_provider.dart';
import 'app_text_field.dart';

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

  Future<void> _submitReport(L10n l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception(l10n.violationReportUserNotFound);
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
          SnackBar(
            content: Text(l10n.violationReportSuccessMessage),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // 成功を示すtrueを返す
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorOccurred}: $e'),
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
                  Text(
                    l10n.violationReportDialogTitle,
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
                                  Text(
                                    l10n.violationReportTargetLabel,
                                    style: const TextStyle(
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
                        '${l10n.violationReportTypeLabel} *',
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
                              _getViolationTypeDisplayName(l10n, type),
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
                        '${l10n.violationReportSeverityLabel} *',
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
                              _getViolationSeverityDisplayName(l10n, severity),
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
                      AppTextFieldMultiline(
                        controller: _descriptionController,
                        label: l10n.violationReportDescriptionLabel,
                        hintText: l10n.violationReportDescriptionHint,
                        isRequired: true,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.violationReportDescriptionRequired;
                          }
                          if (value.trim().length < 10) {
                            return l10n.violationReportDescriptionMinLength;
                          }
                          return null;
                        },
                        doneButtonText: l10n.doneButtonLabel,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),

                      // メモ（任意）
                      AppTextFieldMultiline(
                        controller: _notesController,
                        label: l10n.violationReportNotesLabel,
                        hintText: l10n.violationReportNotesHint,
                        maxLines: 3,
                        doneButtonText: l10n.doneButtonLabel,
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
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitReport(l10n),
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
                        : Text(
                            l10n.violationReportSubmitButton,
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

  /// 違反タイプのローカライズされた表示名を取得
  String _getViolationTypeDisplayName(L10n l10n, ViolationType type) {
    switch (type) {
      case ViolationType.harassment:
        return l10n.violationTypeHarassment;
      case ViolationType.cheating:
        return l10n.violationTypeCheating;
      case ViolationType.spam:
        return l10n.violationTypeSpam;
      case ViolationType.abusiveLanguage:
        return l10n.violationTypeAbusiveLanguage;
      case ViolationType.noShow:
        return l10n.violationTypeNoShow;
      case ViolationType.disruptiveBehavior:
        return l10n.violationTypeDisruptiveBehavior;
      case ViolationType.ruleViolation:
        return l10n.violationTypeRuleViolation;
      case ViolationType.other:
        return l10n.violationTypeOther;
    }
  }

  /// 重要度のローカライズされた表示名を取得
  String _getViolationSeverityDisplayName(L10n l10n, ViolationSeverity severity) {
    switch (severity) {
      case ViolationSeverity.minor:
        return l10n.violationSeverityMinor;
      case ViolationSeverity.moderate:
        return l10n.violationSeverityModerate;
      case ViolationSeverity.severe:
        return l10n.violationSeveritySevere;
    }
  }
}