import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// ローディングオーバーレイウィジェット
/// 全画面にローディング表示を行う
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final Color? backgroundColor;
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    indicatorColor ?? AppColors.primary,
                  ),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  message!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}