import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/in_app_review_service.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = L10n.of(context);
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
          Text(
            l10n.rateAppTitle,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      content: Text(
        l10n.rateAppMessage,
        style: const TextStyle(
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
              text: l10n.rateWithStars,
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
              text: l10n.writeReview,
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
              child: Text(
                l10n.later,
                style: const TextStyle(
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
