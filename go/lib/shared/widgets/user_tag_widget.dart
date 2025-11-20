import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

/// ユーザータグウィジェット
/// プロフィールアイコンとユーザー名を表示し、タップでプロフィール画面に遷移
class UserTagWidget extends ConsumerStatefulWidget {
  final String userId;
  final double? avatarSize;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool showFullName;

  const UserTagWidget({
    super.key,
    required this.userId,
    this.avatarSize,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.showFullName = true,
  });

  @override
  ConsumerState<UserTagWidget> createState() => _UserTagWidgetState();
}

class _UserTagWidgetState extends ConsumerState<UserTagWidget> {
  final UserRepository _userRepository = UserRepository();
  UserData? _userData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final userData = await _userRepository.getUserByCustomId(widget.userId);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
          _hasError = userData == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingTag();
    }

    if (_hasError || _userData == null) {
      return _buildErrorTag();
    }

    return _buildUserTag(_userData!);
  }

  /// 読み込み中のタグ
  Widget _buildLoadingTag() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.avatarSize ?? AppDimensions.iconM,
            height: widget.avatarSize ?? AppDimensions.iconM,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            '読み込み中...',
            style: widget.textStyle ?? TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// エラー時のタグ
  Widget _buildErrorTag() {
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.avatarSize ?? AppDimensions.iconM,
            height: widget.avatarSize ?? AppDimensions.iconM,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: (widget.avatarSize ?? AppDimensions.iconM) * 0.6,
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            'ユーザー不明',
            style: widget.textStyle ?? TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// ユーザータグ
  Widget _buildUserTag(UserData userData) {
    final displayName = widget.showFullName
        ? (userData.displayName ?? userData.userId)
        : userData.displayName?.split(' ').first ?? userData.userId;

    return InkWell(
      onTap: () => _navigateToUserProfile(userData.id),
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingXS,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: (widget.avatarSize ?? AppDimensions.iconM) / 2,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              backgroundImage: userData.photoUrl != null
                  ? NetworkImage(userData.photoUrl!)
                  : null,
              child: userData.photoUrl == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: (widget.avatarSize ?? AppDimensions.iconM) * 0.4,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Flexible(
              child: Text(
                displayName,
                style: widget.textStyle ?? TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Icon(
              Icons.open_in_new,
              size: AppDimensions.iconS * 0.8,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// ユーザープロフィール画面に遷移
  void _navigateToUserProfile(String userId) {
    Navigator.of(context).pushNamed(
      '/user_profile',
      arguments: userId,
    );
  }
}

/// 複数のユーザータグを表示するウィジェット
class UserTagsWidget extends StatelessWidget {
  final List<String> userIds;
  final double? avatarSize;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool showFullName;
  final int? maxTags;
  final WrapAlignment alignment;

  const UserTagsWidget({
    super.key,
    required this.userIds,
    this.avatarSize,
    this.textStyle,
    this.backgroundColor,
    this.padding,
    this.showFullName = false,
    this.maxTags,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (userIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Text(
          'なし',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final displayUserIds = maxTags != null
        ? userIds.take(maxTags!).toList()
        : userIds;

    final hiddenCount = maxTags != null && userIds.length > maxTags!
        ? userIds.length - maxTags!
        : 0;

    return Wrap(
      alignment: alignment,
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      children: [
        ...displayUserIds.map((userId) => UserTagWidget(
          userId: userId,
          avatarSize: avatarSize,
          textStyle: textStyle,
          backgroundColor: backgroundColor,
          padding: padding,
          showFullName: showFullName,
        )),
        if (hiddenCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              '+$hiddenCount',
              style: textStyle ?? TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}