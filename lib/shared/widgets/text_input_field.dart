import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// テキスト入力フィールドウィジェット
class TextInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function(String)? onSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isRequired;

  const TextInputField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.autofocus = false,
    this.focusNode,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label! + (isRequired ? ' *' : ''),
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.textDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onSubmitted,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: enabled ? AppColors.textDark : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            prefixText: prefixText,
            suffixText: suffixText,
            filled: true,
            fillColor: enabled
                ? AppColors.backgroundWhite
                : AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingM,
            ),
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeM,
            ),
            helperStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeS,
            ),
            errorStyle: const TextStyle(
              color: AppColors.error,
              fontSize: AppDimensions.fontSizeS,
            ),
          ),
        ),
      ],
    );
  }
}