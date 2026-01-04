import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';

/// 複数行入力対応のテキストフィールド
/// 改行機能とキーボードツールバー（閉じるボタン）を提供
class MultilineTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final String? Function(String?)? validator;

  const MultilineTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 3,
    this.validator,
  });

  @override
  State<MultilineTextField> createState() => _MultilineTextFieldState();
}

class _MultilineTextFieldState extends State<MultilineTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildTextFieldWithToolbar(),
      ],
    );
  }

  Widget _buildTextFieldWithToolbar() {
    return KeyboardListener(
      focusNode: _focusNode,
      child: TextFormField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        textInputAction: TextInputAction.newline, // 改行を可能にする
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: AppColors.textLight,
            fontSize: AppDimensions.fontSizeM,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
          // iOS/Androidのキーボードツールバーを設定
          suffixIcon: _buildKeyboardToolbar(),
        ),
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
        ),
        validator: widget.validator ?? (widget.isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return L10n.of(context).requiredFieldError(widget.label);
                }
                return null;
              }
            : null),
        // iOS用のキーボードツールバーを設定
        toolbarOptions: const ToolbarOptions(
          copy: true,
          cut: true,
          paste: true,
          selectAll: true,
        ),
        // iOS用のコンテキストメニューボタンビルダー
        contextMenuBuilder: (context, editableTextState) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: <ContextMenuButtonItem>[
              ...editableTextState.contextMenuButtonItems,
              ContextMenuButtonItem(
                label: L10n.of(context).hideKeyboard,
                onPressed: () {
                  _hideKeyboard();
                  ContextMenuController.removeAny();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildKeyboardToolbar() {
    // Android用のキーボード操作ボタン
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: const Icon(
          Icons.keyboard_hide,
          size: 20,
          color: AppColors.textSecondary,
        ),
        onPressed: _hideKeyboard,
        tooltip: L10n.of(context).hideKeyboard,
      ),
    );
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}

/// アクセサリビューとしてキーボード上部に表示するツールバー
class KeyboardToolbar extends StatelessWidget {
  final VoidCallback? onDone;
  final String? doneText;

  const KeyboardToolbar({
    super.key,
    this.onDone,
    this.doneText,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = doneText ?? L10n.of(context).doneButtonLabel;
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onDone ?? () => FocusScope.of(context).unfocus(),
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}