import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import 'user_avatar.dart';

/// ユーザーIDからユーザー情報を取得してアイコンを表示するウィジェット
class UserAvatarFromId extends ConsumerStatefulWidget {
  final String? userId;
  final double size;
  final VoidCallback? onTap;
  final Widget? overlayIcon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatarFromId({
    super.key,
    required this.userId,
    required this.size,
    this.onTap,
    this.overlayIcon,
    this.backgroundColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  ConsumerState<UserAvatarFromId> createState() => _UserAvatarFromIdState();
}

class _UserAvatarFromIdState extends ConsumerState<UserAvatarFromId> {
  UserData? _userData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(UserAvatarFromId oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      // ユーザーIDが無効でもデフォルトアイコンを表示するため、nullをセット
      if (mounted) {
        setState(() {
          _userData = null;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRepository = UserRepository();
      final userData = await userRepository.getUserByCustomId(widget.userId!);

      if (mounted) {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data for ID ${widget.userId}: $e');
      if (mounted) {
        setState(() {
          _userData = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.overlayLight,
          shape: BoxShape.circle,
          border: widget.borderWidth > 0 && widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
              : null,
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.iconColor ?? AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }

    // ユーザーIDが無効な場合やユーザーデータが取得できない場合でも
    // UserAvatarコンポーネントがデフォルトアイコンを表示する
    return UserAvatar(
      size: widget.size,
      avatarUrl: _userData?.photoUrl,
      onTap: widget.onTap,
      overlayIcon: widget.overlayIcon,
      backgroundColor: widget.backgroundColor,
      iconColor: widget.iconColor,
      borderColor: widget.borderColor,
      borderWidth: widget.borderWidth,
    );
  }
}