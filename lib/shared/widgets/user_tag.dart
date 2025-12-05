import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/user_model.dart';
import '../utils/withdrawn_user_helper.dart';
import 'user_avatar.dart';

class UserTag extends StatelessWidget {
  final UserData user;
  final VoidCallback? onRemove;
  final bool showRemoveButton;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSelected;

  const UserTag({
    super.key,
    required this.user,
    this.onRemove,
    this.showRemoveButton = true,
    this.size,
    this.backgroundColor,
    this.textColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final double tagSize = size ?? AppDimensions.iconL;
    final Color bgColor = backgroundColor ??
        (isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight);
    final Color txtColor = textColor ??
        (isSelected ? AppColors.accent : AppColors.textDark);

    return Container(
      margin: const EdgeInsets.only(
        right: AppDimensions.spacingS,
        bottom: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(tagSize * 0.6),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(tagSize * 0.15),
              child: UserAvatar(
                size: tagSize * 0.7,
                avatarUrl: WithdrawnUserHelper.getDisplayAvatarUrl(user),
                backgroundColor: AppColors.overlayMedium,
                iconColor: AppColors.textSecondary,
                borderColor: AppColors.accent.withValues(alpha: 0.3),
                borderWidth: 0.5,
              ),
            ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: tagSize * 0.2,
                  horizontal: tagSize * 0.1,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WithdrawnUserHelper.getDisplayUsername(user),
                      style: TextStyle(
                        fontSize: tagSize * 0.35,
                        fontWeight: FontWeight.w600,
                        color: txtColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${WithdrawnUserHelper.getDisplayUserId(user)}',
                      style: TextStyle(
                        fontSize: tagSize * 0.25,
                        color: txtColor.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (showRemoveButton && onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  margin: EdgeInsets.all(tagSize * 0.1),
                  padding: EdgeInsets.all(tagSize * 0.1),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: tagSize * 0.35,
                    color: AppColors.error,
                  ),
                ),
              )
            else
              SizedBox(width: tagSize * 0.15),
          ],
        ),
      ),
    );
  }
}

class UserTagsList extends StatelessWidget {
  final List<UserData> users;
  final Function(UserData)? onUserRemove;
  final String? emptyMessage;
  final bool showRemoveButtons;
  final double? tagSize;
  final int? maxDisplayCount;

  const UserTagsList({
    super.key,
    required this.users,
    this.onUserRemove,
    this.emptyMessage,
    this.showRemoveButtons = true,
    this.tagSize,
    this.maxDisplayCount,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty && emptyMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline,
              color: AppColors.textSecondary,
              size: AppDimensions.iconL,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              emptyMessage!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppDimensions.fontSizeM,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final displayUsers = maxDisplayCount != null && users.length > maxDisplayCount!
        ? users.take(maxDisplayCount!).toList()
        : users;

    final remainingCount = maxDisplayCount != null && users.length > maxDisplayCount!
        ? users.length - maxDisplayCount!
        : 0;

    return Wrap(
      children: [
        ...displayUsers.map((user) => UserTag(
          user: user,
          onRemove: showRemoveButtons && onUserRemove != null
              ? () => onUserRemove!(user)
              : null,
          showRemoveButton: showRemoveButtons,
          size: tagSize,
        )).toList(),
        if (remainingCount > 0)
          Container(
            margin: const EdgeInsets.only(
              right: AppDimensions.spacingS,
              bottom: AppDimensions.spacingS,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.overlayMedium,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '+$remainingCount',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}