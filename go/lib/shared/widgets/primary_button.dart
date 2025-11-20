import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// プライマリボタンウィジェット
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isButtonDisabled = isDisabled || isLoading || onPressed == null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonDisabled
              ? AppColors.textSecondary.withValues(alpha: 0.3)
              : AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: isButtonDisabled ? 0 : 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}