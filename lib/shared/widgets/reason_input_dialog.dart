import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';

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
  factory ReasonInputDialog.removal() {
    return const ReasonInputDialog(
      title: '参加者の除名',
      description: 'この参加者をイベントから除名しますか？\n除名理由を入力してください。',
      confirmButtonText: '除名',
      confirmButtonType: AppButtonType.danger,
      hintText: '除名理由を入力（任意）',
      isRequired: false,
    );
  }

  /// 拒否用のファクトリコンストラクタ
  factory ReasonInputDialog.rejection() {
    return const ReasonInputDialog(
      title: '参加申請の拒否',
      description: 'この申請を拒否しますか？\n拒否理由を入力してください。',
      confirmButtonText: '拒否',
      confirmButtonType: AppButtonType.danger,
      hintText: '拒否理由を入力（任意）',
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
            TextField(
              controller: _reasonController,
              maxLines: 4,
              maxLength: widget.maxLength,
              onChanged: (_) => _validateInput(),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppDimensions.fontSizeM,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide(
                    color: _isValid ? AppColors.borderLight : AppColors.error,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide(
                    color: _isValid ? AppColors.borderLight : AppColors.error,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide(
                    color: _isValid ? AppColors.primary : AppColors.error,
                    width: 2.0,
                  ),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
              ),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
            ),
            if (!_isValid && widget.isRequired) ...[
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                '理由の入力は必須です',
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
                text: 'キャンセル',
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