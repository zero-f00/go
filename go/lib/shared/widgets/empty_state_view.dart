import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 空状態表示ビューウィジェット
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppDimensions.spacingL),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingL,
                    vertical: AppDimensions.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}