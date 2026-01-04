import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import 'user_avatar.dart';
import 'ad_banner.dart';

class AppHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;
  final bool showMenuButton;
  final bool showUserIcon;
  final List<Widget>? actions;
  final bool showAd;

  const AppHeader({
    super.key,
    required this.title,
    this.onBackPressed,
    this.onMenuPressed,
    this.showBackButton = true,
    this.showMenuButton = false,
    this.showUserIcon = false,
    this.actions,
    this.showAd = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final displayName = ref.watch(displayNameProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
                      borderRadius: BorderRadius.circular(
                        AppDimensions.headerButtonSize / 2,
                      ),
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
                  child: GestureDetector(
                    onTap: () => _showFullTitle(context),
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: _getResponsiveFontSize(title),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              // 右側のアクションまたはメニューボタン
              if (actions != null && actions!.isNotEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else if (showMenuButton && !showUserIcon)
                GestureDetector(
                  onTap: onMenuPressed,
                  child: Container(
                    width: AppDimensions.headerButtonSize,
                    height: AppDimensions.headerButtonSize,
                    decoration: BoxDecoration(
                      color: AppColors.overlayLight,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.headerButtonSize / 2,
                      ),
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
        ),
        if (showAd) const AdBanner(),
      ],
    );
  }

  Widget _buildUserIcon(
    BuildContext context,
    WidgetRef ref,
    bool isSignedIn,
    String displayName,
  ) {
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

  Future<void> _handleUserIconTap(
    BuildContext context,
    WidgetRef ref,
    bool isSignedIn,
  ) async {
    // ヘッダーアイコンタップで常にサイドメニュー（AppDrawer）を表示
    Scaffold.of(context).openDrawer();
  }

  /// レスポンシブフォントサイズを計算
  double _getResponsiveFontSize(String title) {
    // 基本フォントサイズ
    const double baseSize = AppDimensions.fontSizeXXL;

    // タイトル長に応じてフォントサイズを調整
    if (title.length <= 10) {
      return baseSize; // 20.0
    } else if (title.length <= 20) {
      return AppDimensions.fontSizeXL; // 18.0
    } else if (title.length <= 30) {
      return AppDimensions.fontSizeL; // 16.0
    } else {
      return AppDimensions.fontSizeM; // 14.0
    }
  }

  /// 全文タイトル表示ダイアログ
  void _showFullTitle(BuildContext context) {
    // 短いタイトルの場合は何もしない
    if (title.length <= 15) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Icon(
              Icons.event,
              color: AppColors.accent,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              L10n.of(context).eventTitle,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              L10n.of(context).closeButton,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
