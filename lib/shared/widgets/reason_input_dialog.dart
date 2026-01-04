import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// 理由入力ダイアログ
class ReasonInputDialog extends StatefulWidget {
  /// ダイアログのタイトル
  final String title;

  /// 説明文
  final String description;

  /// 確認ボタンのテキスト
  final String confirmButtonText;

  /// 確認ボタンの色（デフォルトはprimary）
  final AppButtonType confirmButtonType;

  /// 理由入力のヒントテキスト
  final String? hintText;

  /// 理由の最大文字数
  final int maxLength;

  /// 理由入力が必須かどうか
  final bool isRequired;

  const ReasonInputDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmButtonText,
    this.confirmButtonType = AppButtonType.primary,
    this.hintText,
    this.maxLength = 500,
    this.isRequired = false,
  });

  /// 除名用のファクトリコンストラクタ
  static ReasonInputDialog removal(BuildContext context) {
    final l10n = L10n.of(context);
    return ReasonInputDialog(
      title: l10n.removalDialogTitle,
      description: l10n.removalDialogDescription,
      confirmButtonText: l10n.removalButtonText,
      confirmButtonType: AppButtonType.danger,
      hintText: l10n.removalReasonHint,
      isRequired: false,
    );
  }

  /// 拒否用のファクトリコンストラクタ
  static ReasonInputDialog rejection(BuildContext context) {
    final l10n = L10n.of(context);
    return ReasonInputDialog(
      title: l10n.rejectionDialogTitle,
      description: l10n.rejectionDialogDescription,
      confirmButtonText: l10n.rejectionButtonText,
      confirmButtonType: AppButtonType.danger,
      hintText: l10n.rejectionReasonHint,
      isRequired: false,
    );
  }

  @override
  State<ReasonInputDialog> createState() => _ReasonInputDialogState();
}

class _ReasonInputDialogState extends State<ReasonInputDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isValid = true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      if (widget.isRequired) {
        _isValid = _reasonController.text.trim().isNotEmpty;
      } else {
        _isValid = true;
      }
    });
  }

  void _onConfirm() {
    _validateInput();
    if (_isValid) {
      Navigator.of(context).pop(_reasonController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            AppTextFieldMultiline(
              controller: _reasonController,
              hintText: widget.hintText,
              isRequired: widget.isRequired,
              maxLines: 4,
              maxLength: widget.maxLength,
              onChanged: (_) => _validateInput(),
              doneButtonText: l10n.doneButtonText,
            ),
            if (!_isValid && widget.isRequired) ...[
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.reasonRequiredError,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: l10n.cancelButtonText,
                onPressed: () => Navigator.of(context).pop(),
                type: AppButtonType.secondary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: AppButton(
                text: widget.confirmButtonText,
                onPressed: _onConfirm,
                type: widget.confirmButtonType,
              ),
            ),
          ],
        ),
      ],
    );
  }
}