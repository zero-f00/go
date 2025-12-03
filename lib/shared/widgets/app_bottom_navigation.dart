import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_dimensions.dart';
import 'notification_tab_icon.dart';

class AppBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, -AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: AppDimensions.fontSizeXS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppDimensions.fontSizeXS,
          fontWeight: FontWeight.w400,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              size: AppDimensions.iconM,
            ),
            activeIcon: Icon(
              Icons.home,
              size: AppDimensions.iconM,
            ),
            label: AppStrings.homeTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.search_outlined,
              size: AppDimensions.iconM,
            ),
            activeIcon: Icon(
              Icons.search,
              size: AppDimensions.iconM,
            ),
            label: AppStrings.searchTab,
          ),
          BottomNavigationBarItem(
            icon: NotificationTabIcon(isActive: false),
            activeIcon: NotificationTabIcon(isActive: true),
            label: AppStrings.notificationTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard_outlined,
              size: AppDimensions.iconM,
            ),
            activeIcon: Icon(
              Icons.dashboard,
              size: AppDimensions.iconM,
            ),
            label: AppStrings.manageTab,
          ),
        ],
      ),
    );
  }
}