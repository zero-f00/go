import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// バッジ付きアイコンウィジェット
class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final bool showBadge;
  final int? badgeCount;
  final String? badgeText;

  const BadgeIcon({
    super.key,
    required this.icon,
    this.iconSize = AppDimensions.iconM,
    this.iconColor = AppColors.textSecondary,
    this.showBadge = false,
    this.badgeCount,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
        if (showBadge)
          Positioned(
            right: -6,
            top: -6,
            child: _buildBadge(),
          ),
      ],
    );
  }

  Widget _buildBadge() {
    // バッジに表示するテキストを決定
    String displayText;
    if (badgeText != null) {
      displayText = badgeText!;
    } else if (badgeCount != null) {
      displayText = badgeCount! > 99 ? '99+' : badgeCount.toString();
    } else {
      displayText = '';
    }

    // テキストが空の場合は小さな点を表示
    if (displayText.isEmpty) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
      );
    }

    // 数字やテキストがある場合はバッジを表示
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.cardBackground,
          width: 1.5,
        ),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: AppColors.textOnPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}