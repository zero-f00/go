import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/in_app_review_service.dart';
import 'app_button.dart';

/// アプリ評価の選択ダイアログ
/// 「星で評価」（In-App Review）と「レビューを書く」（ストアページ）の2つの選択肢を提供
class ReviewDialog extends StatelessWidget {
  const ReviewDialog({super.key});

  /// ダイアログを表示
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      title: Row(
        children: [
          Icon(
            Icons.star_rate_rounded,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          const Text(
            'アプリを評価',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: const Text(
        'Goをご利用いただきありがとうございます！\nどちらの方法で評価しますか？',
        style: TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              text: '星で評価',
              icon: Icons.star_outline_rounded,
              onPressed: () {
                Navigator.pop(context);
                InAppReviewService.requestReview();
              },
              type: AppButtonType.primary,
              isFullWidth: true,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            AppButton(
              text: 'レビューを書く',
              icon: Icons.rate_review_outlined,
              onPressed: () {
                Navigator.pop(context);
                InAppReviewService.openStoreListing();
              },
              type: AppButtonType.outline,
              isFullWidth: true,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'あとで',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimensions.fontSizeM,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
