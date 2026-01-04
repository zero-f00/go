import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'keyboard_overlay_widget.dart';

/// アプリ共通のテキストフィールドコンポーネント
/// 単一行・複数行両方に対応、自動的にキーボードツールバーを提供
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool showKeyboardToolbar;
  final bool forceShowKeyboardToolbar; // 単一行でも強制的にツールバーを表示（数字キーボード用）
  final String? doneButtonText;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.showKeyboardToolbar = true,
    this.forceShowKeyboardToolbar = false,
    this.doneButtonText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _shouldDisposeNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _shouldDisposeNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void dispose() {
    if (_shouldDisposeNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          _buildLabel(),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        _buildTextField(),
      ],
    );
  }

  Widget _buildLabel() {
    return Row(
      children: [
        Text(
          widget.label!,
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
    );
  }

  Widget _buildTextField() {
    final textField = TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      keyboardType: _getKeyboardType(),
      textInputAction: _getTextInputAction(),
      inputFormatters: widget.inputFormatters,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      decoration: _buildInputDecoration(),
      style: _buildTextStyle(),
      validator: _buildValidator(),
    );

    // キーボードツールバーが必要な場合は包む
    // 単一行入力の場合は、TextInputAction.nextで次フィールドに移動できるため
    // 「完了」ツールバーは不要（iOS/Androidのベストプラクティスに準拠）
    // 複数行入力の場合は、改行キーと閉じる機能を分離するためツールバーが必要
    // ただし、数字キーボードなど特殊なケースではforceShowKeyboardToolbarで強制表示可能
    final shouldShowToolbar = widget.showKeyboardToolbar &&
        (_isMultiline() || widget.forceShowKeyboardToolbar);

    if (shouldShowToolbar) {
      return KeyboardOverlayWidget(
        doneText: widget.doneButtonText ?? L10n.of(context).doneButtonLabel,
        focusNode: _focusNode, // FocusNodeを渡して正確にフォーカス状態を監視
        child: textField,
      );
    }

    return textField;
  }

  TextInputType _getKeyboardType() {
    if (_isMultiline()) {
      return TextInputType.multiline;
    }
    return widget.keyboardType;
  }

  TextInputAction? _getTextInputAction() {
    if (widget.textInputAction != null) {
      return widget.textInputAction;
    }

    if (_isMultiline()) {
      return TextInputAction.newline;
    }

    return TextInputAction.next;
  }

  bool _isMultiline() {
    return widget.maxLines > 1;
  }

  InputDecoration _buildInputDecoration() {
    return InputDecoration(
      hintText: widget.hintText,
      errorText: widget.errorText,
      hintStyle: const TextStyle(
        color: AppColors.textLight,
        fontSize: AppDimensions.fontSizeM,
      ),
      filled: true,
      fillColor: widget.enabled ? AppColors.backgroundLight : AppColors.backgroundDark,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
      suffixIcon: widget.suffixIcon,
      prefixIcon: widget.prefixIcon,
      counterText: widget.maxLength != null ? null : '', // 文字数カウンターを非表示
    );
  }

  TextStyle _buildTextStyle() {
    return TextStyle(
      fontSize: AppDimensions.fontSizeM,
      color: widget.enabled ? AppColors.textDark : AppColors.textLight,
    );
  }

  String? Function(String?)? _buildValidator() {
    if (widget.validator != null) {
      return widget.validator;
    }
    if (widget.isRequired) {
      final l10n = L10n.of(context);
      return (value) {
        if (value == null || value.trim().isEmpty) {
          final fieldName = widget.label ?? l10n.validationFieldRequiredDefault;
          return l10n.validationFieldRequired(fieldName);
        }
        return null;
      };
    }
    return null;
  }
}

/// 旧コンポーネントとの互換性を保つためのラッパー
/// 既存のEnhancedMultilineTextFieldを段階的に移行するために使用
@Deprecated('Use AppTextField instead')
class EnhancedMultilineTextField extends StatelessWidget {
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
    this.doneButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hint,
      isRequired: isRequired,
      maxLines: maxLines,
      validator: validator,
      doneButtonText: doneButtonText,
    );
  }
}

/// 単一行入力専用のショートハンド
class AppTextFieldSingle extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const AppTextFieldSingle({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.obscureText = false,
    this.validator,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      maxLines: 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      enabled: enabled,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      showKeyboardToolbar: false, // 単一行では不要
    );
  }
}

/// 複数行入力専用のショートハンド
class AppTextFieldMultiline extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? doneButtonText;
  final void Function(String)? onChanged;

  const AppTextFieldMultiline({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.maxLines = 3,
    this.minLines,
    this.maxLength,
    this.validator,
    this.enabled = true,
    this.doneButtonText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      validator: validator,
      enabled: enabled,
      doneButtonText: doneButtonText,
      keyboardType: TextInputType.multiline,
      onChanged: onChanged,
    );
  }
}

/// 数字入力専用のショートハンド
class AppTextFieldNumber extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final bool isRequired;
  final String? Function(String?)? validator;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool allowDecimal;
  final bool allowNegative;
  final int? maxLength;

  const AppTextFieldNumber({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.isRequired = false,
    this.validator,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      maxLines: 1,
      maxLength: maxLength,
      keyboardType: allowDecimal
          ? TextInputType.numberWithOptions(decimal: true, signed: allowNegative)
          : TextInputType.number,
      inputFormatters: _getInputFormatters(),
      validator: validator ?? _buildDefaultValidator(context),
      enabled: enabled,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      forceShowKeyboardToolbar: true, // iOSの数字キーボードには「完了」がないため強制表示
      textInputAction: TextInputAction.next,
    );
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (allowDecimal) {
      if (allowNegative) {
        // 小数点と負の数を許可
        return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];
      } else {
        // 小数点のみを許可
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      }
    } else {
      if (allowNegative) {
        // 負の整数を許可
        return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))];
      } else {
        // 正の整数のみ
        return [FilteringTextInputFormatter.digitsOnly];
      }
    }
  }

  String? Function(String?)? _buildDefaultValidator(BuildContext context) {
    if (!isRequired) return null;

    final l10n = L10n.of(context);
    return (value) {
      if (value == null || value.trim().isEmpty) {
        final fieldName = label ?? l10n.validationFieldRequiredDefault;
        return l10n.validationFieldRequired(fieldName);
      }

      final numValue = allowDecimal
          ? double.tryParse(value.trim())
          : int.tryParse(value.trim());

      if (numValue == null) {
        return allowDecimal
            ? l10n.validationEnterValidNumber
            : l10n.validationEnterValidInteger;
      }

      if (!allowNegative && numValue < 0) {
        return l10n.validationPositiveNumberRequired;
      }

      return null;
    };
  }
}