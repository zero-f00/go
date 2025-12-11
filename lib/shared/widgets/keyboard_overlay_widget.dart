import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// キーボード上に表示するオーバーレイウィジェット
/// iOS・Android両対応でキーボードツールバーを提供
class KeyboardOverlayWidget extends StatefulWidget {
  final Widget child;
  final String? doneText;
  final VoidCallback? onDone;
  final bool showToolbar;
  final FocusNode? focusNode; // 監視対象のFocusNode

  const KeyboardOverlayWidget({
    super.key,
    required this.child,
    this.doneText = '完了',
    this.onDone,
    this.showToolbar = true,
    this.focusNode,
  });

  @override
  State<KeyboardOverlayWidget> createState() => _KeyboardOverlayWidgetState();
}

class _KeyboardOverlayWidgetState extends State<KeyboardOverlayWidget> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    // FocusNodeが渡されている場合はそれを監視
    widget.focusNode?.addListener(_onFocusNodeChange);
  }

  @override
  void didUpdateWidget(KeyboardOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusNodeChange);
      widget.focusNode?.addListener(_onFocusNodeChange);
    }
  }

  void _onFocusNodeChange() {
    if (!widget.showToolbar) return;

    final hasFocus = widget.focusNode?.hasFocus ?? false;
    if (hasFocus) {
      _showKeyboardToolbar();
    } else {
      _hideKeyboardToolbar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // FocusNodeが渡されている場合はFocusウィジェットを使わない
    if (widget.focusNode != null) {
      return CompositedTransformTarget(
        link: _layerLink,
        child: widget.child,
      );
    }

    // FocusNodeが渡されていない場合は従来のFocusウィジェットを使用（後方互換性）
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onFocusChange: _onFocusChange,
        child: widget.child,
      ),
    );
  }

  void _onFocusChange(bool hasFocus) {
    if (!widget.showToolbar) return;

    if (hasFocus) {
      _showKeyboardToolbar();
    } else {
      // フォーカスが外れた時は遅延を入れて確実にオーバーレイを削除
      // これによりフォーカス移動時のちらつきを防止しつつ、確実に非表示にする
      Future.microtask(() {
        if (mounted && _overlayEntry != null) {
          _hideKeyboardToolbar();
        }
      });
    }
  }

  void _showKeyboardToolbar() {
    _hideKeyboardToolbar(); // 既存のツールバーがあれば削除

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideKeyboardToolbar() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: _KeyboardToolbar(
          doneText: widget.doneText ?? '完了',
          onDone: () {
            widget.onDone?.call();
            _hideKeyboard();
            _hideKeyboardToolbar();
          },
        ),
      ),
    );
  }

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusNodeChange);
    _hideKeyboardToolbar();
    super.dispose();
  }
}

class _KeyboardToolbar extends StatelessWidget {
  final String doneText;
  final VoidCallback onDone;

  const _KeyboardToolbar({
    required this.doneText,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Platform.isIOS ? AppColors.backgroundLight : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Platform.isIOS ? AppColors.borderLight : AppColors.border,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (Platform.isAndroid) ...[
            // Android用：複数のツールボタン
            _buildToolbarButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: onDone,
              tooltip: 'キーボードを閉じる',
            ),
            const Spacer(),
          ],
          if (Platform.isIOS) ...[
            // iOS用：完了ボタンのみ
            const Spacer(),
          ],
          _buildDoneButton(),
          const SizedBox(width: AppDimensions.spacingM),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
      child: IconButton(
        icon: Icon(
          icon,
          size: 24,
          color: AppColors.textSecondary,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildDoneButton() {
    return TextButton(
      onPressed: onDone,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(60, 44),
      ),
      child: Text(
        doneText,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Enhanced TextField with integrated keyboard toolbar
class EnhancedMultilineTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isRequired;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? doneButtonText;

  const EnhancedMultilineTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.maxLines = 3,
    this.validator,
    this.doneButtonText = '完了',
  });

  @override
  State<EnhancedMultilineTextField> createState() =>
      _EnhancedMultilineTextFieldState();
}

class _EnhancedMultilineTextFieldState
    extends State<EnhancedMultilineTextField> {
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
        KeyboardOverlayWidget(
          doneText: widget.doneButtonText,
          focusNode: _focusNode, // FocusNodeを渡して正確にフォーカス状態を監視
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: widget.maxLines,
            textInputAction: TextInputAction.newline,
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
            ),
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
            ),
            validator: widget.validator ??
                (widget.isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '${widget.label}は必須項目です';
                        }
                        return null;
                      }
                    : null),
          ),
        ),
      ],
    );
  }
}