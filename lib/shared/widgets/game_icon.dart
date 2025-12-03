import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// ゲームアイコンの表示コンポーネント
class GameIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;
  final String? gameName;
  final BorderRadius? borderRadius;

  const GameIcon({
    super.key,
    this.iconUrl,
    this.size = 50,
    this.gameName,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppDimensions.radiusS);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.overlayMedium,
          borderRadius: radius,
        ),
        child: iconUrl != null && iconUrl!.isNotEmpty
            ? Image.network(
                iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              )
            : _buildFallbackIcon(),
      ),
    );
  }

  /// フォールバックアイコン（画像読み込み失敗時・URLなしの場合）
  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.overlayMedium,
        borderRadius: borderRadius ?? BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        Icons.videogame_asset,
        color: AppColors.textSecondary,
        size: size * 0.5,
      ),
    );
  }
}