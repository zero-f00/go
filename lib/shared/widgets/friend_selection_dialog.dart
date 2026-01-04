import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../widgets/user_avatar.dart';
import '../services/social_stats_service.dart';
import '../providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../l10n/app_localizations.dart';

/// 相互フォロー選択ダイアログ
class FriendSelectionDialog extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final Function(UserData) onFriendSelected;
  final List<UserData> excludedUsers;

  const FriendSelectionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onFriendSelected,
    this.excludedUsers = const [],
  });

  /// ダイアログを表示
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required Function(UserData) onFriendSelected,
    List<UserData> excludedUsers = const [],
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FriendSelectionDialog(
        title: title,
        description: description,
        onFriendSelected: onFriendSelected,
        excludedUsers: excludedUsers,
      ),
    );
  }

  @override
  ConsumerState<FriendSelectionDialog> createState() => _FriendSelectionDialogState();
}

class _FriendSelectionDialogState extends ConsumerState<FriendSelectionDialog> {
  List<UserData> _friends = [];
  List<UserData> _availableFriends = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final l10n = L10n.of(context);
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser != null) {
        final socialStatsService = SocialStatsService.instance;
        final friends = await socialStatsService.getFriendsList(currentUser.userId);

        // 除外ユーザーを取り除いてフィルタリング
        final excludedIds = widget.excludedUsers.map((user) => user.id).toSet();
        final availableFriends = friends
            .where((friend) => !excludedIds.contains(friend.id))
            .toList();

        setState(() {
          _friends = friends;
          _availableFriends = availableFriends;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = l10n.mutualFollowLoadingError;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = L10n.of(context).mutualFollowFetchError(e.toString());
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _buildContent(),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people,
            color: AppColors.backgroundLight,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.backgroundLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.backgroundLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.backgroundLight,
              size: AppDimensions.iconM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_friends.isEmpty) {
      return _buildNoFriendsState();
    }

    if (_availableFriends.isEmpty) {
      return _buildAllFriendsSelectedState();
    }

    return _buildFriendsList();
  }

  Widget _buildLoadingState() {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.mutualFollowLoading,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              ElevatedButton(
                onPressed: _loadFriends,
                child: Text(l10n.retryText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFriendsState() {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.iconXL * 2,
              height: AppDimensions.iconXL * 2,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.people_outline,
                size: AppDimensions.iconXL,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              l10n.noMutualFollows,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.noMutualFollowsHint,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllFriendsSelectedState() {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.iconXL * 2,
              height: AppDimensions.iconXL * 2,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                size: AppDimensions.iconXL,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              l10n.allMutualFollowsSelected,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.noSelectableMutualFollows,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      itemCount: _availableFriends.length,
      itemBuilder: (context, index) {
        return _buildFriendCard(_availableFriends[index]);
      },
    );
  }

  Widget _buildFriendCard(UserData friend) {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: () => _selectFriend(friend),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: friend.photoUrl,
                  size: 50,
                  backgroundColor: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.username,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '@${friend.userId}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (friend.bio?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          friend.bio!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    l10n.selectText,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.backgroundLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: AppDimensions.iconS,
            color: AppColors.textLight,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.availableMutualFollowsCount(_availableFriends.length),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectFriend(UserData friend) {
    widget.onFriendSelected(friend);
    Navigator.of(context).pop();
  }
}