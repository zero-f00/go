import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../providers/auth_provider.dart';
import 'app_drawer.dart';
import 'user_avatar.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final bool showMenuButton;
  final bool showUserIcon;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onMenuPressed,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.showUserIcon = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final displayName = ref.watch(displayNameProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXL,
        vertical: AppDimensions.spacingL,
      ),
      child: Row(
        children: [
          // 左側のアイコン
          if (showUserIcon)
            _buildUserIcon(context, ref, isSignedIn, displayName)
          else if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: Container(
                width: AppDimensions.headerButtonSize,
                height: AppDimensions.headerButtonSize,
                decoration: BoxDecoration(
                  color: AppColors.overlayLight,
                  borderRadius: BorderRadius.circular(AppDimensions.headerButtonSize / 2),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textOnPrimary,
                  size: AppDimensions.iconM,
                ),
              ),
            )
          else
            SizedBox(width: AppDimensions.headerButtonSize),

          // 中央のタイトル
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: AppDimensions.fontSizeXXL,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // 右側のアクションまたはメニューボタン
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            )
          else if (showMenuButton && !showUserIcon)
            GestureDetector(
              onTap: onMenuPressed,
              child: Container(
                width: AppDimensions.headerButtonSize,
                height: AppDimensions.headerButtonSize,
                decoration: BoxDecoration(
                  color: AppColors.overlayLight,
                  borderRadius: BorderRadius.circular(AppDimensions.headerButtonSize / 2),
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: AppColors.textOnPrimary,
                  size: AppDimensions.iconM,
                ),
              ),
            )
          else
            SizedBox(width: AppDimensions.headerButtonSize),
        ],
      ),
    );
  }

  Widget _buildUserIcon(BuildContext context, WidgetRef ref, bool isSignedIn, String displayName) {
    final userPhotoUrl = ref.watch(userPhotoUrlProvider);

    return UserAvatar(
      size: AppDimensions.headerButtonSize,
      avatarUrl: userPhotoUrl,
      onTap: () => _handleUserIconTap(context, ref, isSignedIn),
      backgroundColor: AppColors.overlayLight,
      iconColor: AppColors.textOnPrimary,
      borderColor: isSignedIn ? AppColors.accent.withValues(alpha: 0.5) : null,
      borderWidth: isSignedIn ? 1 : 0,
    );
  }

  Future<void> _handleUserIconTap(BuildContext context, WidgetRef ref, bool isSignedIn) async {
    // ヘッダーアイコンタップで常にサイドメニュー（AppDrawer）を表示
    Scaffold.of(context).openDrawer();
  }
}