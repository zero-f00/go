import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.quickActionButtonVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.overlayLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppColors.textOnPrimary,
              size: AppDimensions.iconL,
            ),
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? AppColors.textOnPrimary,
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}