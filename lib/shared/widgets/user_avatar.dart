import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final File? avatarFile;
  final VoidCallback? onTap;
  final Widget? overlayIcon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.avatarFile,
    this.onTap,
    this.overlayIcon,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.overlayLight,
              shape: BoxShape.circle,
              border: borderWidth > 0 && borderColor != null
                  ? Border.all(color: borderColor!, width: borderWidth)
                  : null,
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
            ),
          ),
          if (overlayIcon != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: overlayIcon!,
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // ローカルファイルから画像を表示
    if (avatarFile != null) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.overlayLight,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.file(
            avatarFile!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                color: iconColor ?? AppColors.textOnPrimary,
                size: size * 0.6,
              );
            },
          ),
        ),
      );
    }

    // Firebase StorageのURLから画像を表示
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.overlayLight,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Image.network(
            avatarUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      iconColor ?? AppColors.textOnPrimary,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                color: iconColor ?? AppColors.textOnPrimary,
                size: size * 0.6,
              );
            },
          ),
        ),
      );
    }

    // デフォルトアイコン
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.overlayLight,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: iconColor ?? AppColors.textOnPrimary,
        size: size * 0.6,
      ),
    );
  }
}