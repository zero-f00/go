import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// アプリ共通のボタンコンポーネント
/// CLAUDE.mdルールに従い、色とスタイルを一元管理
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final IconData? icon;
  final bool isEnabled;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  });

  const AppButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.primary;

  const AppButton.secondary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.secondary;

  const AppButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.outline;

  const AppButton.accent({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.accent;

  const AppButton.white({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.white;

  const AppButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.padding,
    this.icon,
    this.isEnabled = true,
  }) : type = AppButtonType.danger;

  @override
  Widget build(BuildContext context) {
    Widget button;

    switch (type) {
      case AppButtonType.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textOnPrimary,
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            elevation: 2,
          ),
          child: _buildButtonContent(),
        );
        break;

      case AppButtonType.secondary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textSecondary,
            foregroundColor: AppColors.textOnPrimary,
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            elevation: 1,
          ),
          child: _buildButtonContent(),
        );
        break;

      case AppButtonType.outline:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.textSecondary),
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: _buildButtonContent(),
        );
        break;

      case AppButtonType.accent:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: _buildButtonContent(),
        );
        break;

      case AppButtonType.white:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textWhite,
            side: const BorderSide(color: AppColors.textWhite),
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: _buildButtonContent(),
        );
        break;

      case AppButtonType.danger:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            elevation: 1,
          ),
          child: _buildButtonContent(),
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: (type == AppButtonType.primary || type == AppButtonType.danger)
                    ? AppDimensions.fontSizeL
                    : AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: (type == AppButtonType.primary || type == AppButtonType.danger)
            ? AppDimensions.fontSizeL
            : AppDimensions.fontSizeM,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

enum AppButtonType {
  primary,
  secondary,
  outline,
  accent,
  white,
  danger,
}