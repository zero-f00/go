import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabLabels;
  final Color? indicatorColor;
  final Color? backgroundColor;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabLabels,
    this.indicatorColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.tabBarHorizontalMargin),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.overlayLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: indicatorColor ?? AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.backgroundTransparent,
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.overlayMedium,
        labelStyle: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w600,
        ),
        tabs: tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

class AppSecondaryTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabLabels;

  const AppSecondaryTabBar({
    super.key,
    required this.controller,
    required this.tabLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.tabBarHorizontalMargin,
        vertical: AppDimensions.tabBarVerticalMargin,
      ),
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.overlayMedium,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.backgroundTransparent,
        labelColor: AppColors.textOnPrimary,
        unselectedLabelColor: AppColors.overlayMedium,
        labelStyle: const TextStyle(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w600,
        ),
        tabs: tabLabels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}