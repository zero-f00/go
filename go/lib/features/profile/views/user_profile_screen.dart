import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/services/friend_service.dart';
import '../../../shared/services/user_event_service.dart';
import '../../../shared/services/social_stats_service.dart';
import '../../../shared/models/game.dart';
import '../../../shared/widgets/event_card.dart';

/// ユーザープロフィール表示画面
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserData? _userData;
  List<Game> _favoriteGames = [];
  bool _isLoading = true;
  String? _errorMessage;
  FriendshipStatus _friendshipStatus = FriendshipStatus.none;
  bool _isProcessingFriendRequest = false;
  SocialStats _socialStats = const SocialStats(friendCount: 0, followerCount: 0, followingCount: 0);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ユーザーデータを読み込み
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getUserByCustomId(widget.userId);

      if (userData != null) {
        // お気に入りゲーム情報を取得
        final games = await GameService.instance.getGamesByIds(userData.favoriteGameIds);

        // ソーシャル統計を取得
        final socialStats = await SocialStatsService.instance.getSocialStats(userData.userId);

        // フレンドシップステータスを取得
        final currentUserAsync = await ref.read(currentUserDataProvider.future);
        if (currentUserAsync != null) {
          await _loadFriendshipStatus(currentUserAsync.userId, userData.userId);
        }

        setState(() {
          _userData = userData;
          _favoriteGames = games;
          _socialStats = socialStats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ユーザーが見つかりません';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ユーザー情報の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  /// フレンドシップステータスを読み込み
  Future<void> _loadFriendshipStatus(String currentUserId, String targetUserId) async {
    try {
      final status = await FriendService.instance.getFriendshipStatus(
        currentUserId,
        targetUserId,
      );
      if (mounted) {
        setState(() {
          _friendshipStatus = status;
        });
      }
    } catch (e) {
      // フレンドシップステータスの取得に失敗した場合はデフォルト状態を維持
      if (mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.none;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: AppStrings.userProfile,
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            'ユーザー情報を取得中...',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// エラー状態を構築
  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
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
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  /// メインコンテンツを構築
  Widget _buildContent() {
    if (_userData == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildProfileHeader(),
          _buildUserInfo(),
          _buildFriendActionButton(),
          _buildFavoriteGamesSection(),
          if (_userData != null) ...[
            _buildHostedEventsSection(),
            _buildParticipatingEventsSection(),
          ],
        ],
      ),
    );
  }

  /// プロフィールヘッダーを構築
  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(
                avatarUrl: _userData!.photoUrl,
                size: 80,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                iconColor: AppColors.accent,
                borderColor: AppColors.accent.withValues(alpha: 0.3),
                borderWidth: 2,
              ),
              const SizedBox(width: AppDimensions.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData!.username,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeXL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '@${_userData!.userId}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildSocialStatsRow(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ソーシャル統計行を構築
  Widget _buildSocialStatsRow() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: () => _onStatItemTap('フレンド'),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.people,
                    size: AppDimensions.iconL,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'フレンド',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '${_socialStats.friendCount}人',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppDimensions.iconS,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// 統計アイテムタップ時の処理
  void _onStatItemTap(String label) {
    // 自分のプロフィールかどうか確認
    final currentUserAsync = ref.read(currentUserDataProvider);
    currentUserAsync.whenOrNull(
      data: (currentUser) {
        if (currentUser != null && currentUser.userId == widget.userId) {
          // 自分のプロフィールの場合はフレンドリスト画面へ
          Navigator.pushNamed(context, '/friends');
        }
        // 他人のプロフィールの場合は何もしない（将来的に詳細表示画面を実装）
      },
    );
  }

  /// ユーザー情報セクションを構築
  Widget _buildUserInfo() {
    if ((_userData!.bio?.isEmpty ?? true) && (_userData!.contact?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userData!.bio?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Text(
                  '自己紹介',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _userData!.bio ?? '',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (_userData!.contact?.isNotEmpty ?? false)
              const SizedBox(height: AppDimensions.spacingM),
          ],
          if (_userData!.contact?.isNotEmpty ?? false) ...[
            Row(
              children: [
                Icon(
                  Icons.contact_mail,
                  color: AppColors.primary,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Text(
                  '連絡先',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _userData!.contact ?? '',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// お気に入りゲームセクションを構築
  Widget _buildFavoriteGamesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gamepad,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'お気に入りゲーム',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  '${_favoriteGames.length}個',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_favoriteGames.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Wrap(
              spacing: AppDimensions.spacingM,
              runSpacing: AppDimensions.spacingM,
              children: _favoriteGames.map((game) => _buildGameCard(game)).toList(),
            ),
          ] else ...[
            const SizedBox(height: AppDimensions.spacingM),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.videogame_asset_off,
                    size: AppDimensions.iconL,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  const Text(
                    'お気に入りゲームが設定されていません',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ゲームカードを構築
  Widget _buildGameCard(Game game) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            iconUrl: game.iconUrl,
            size: 50,
            gameName: game.name,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            game.name,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            game.developer,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// フレンドアクションボタンを構築
  Widget _buildFriendActionButton() {
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final currentUser = currentUserAsync.asData?.value;

    // 現在のユーザーがサインインしていない、または自分自身のプロフィールの場合は表示しない
    if (currentUser == null || currentUser.userId == widget.userId) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: _buildFriendButton(),
    );
  }

  /// フレンドボタンを構築
  Widget _buildFriendButton() {
    if (_isProcessingFriendRequest) {
      return AppButton(
        text: '処理中...',
        icon: Icons.hourglass_empty,
        onPressed: null,
        type: AppButtonType.secondary,
        isFullWidth: true,
      );
    }

    switch (_friendshipStatus) {
      case FriendshipStatus.none:
        return AppButton(
          text: 'フレンドリクエストを送信',
          icon: Icons.person_add,
          onPressed: _sendFriendRequest,
          type: AppButtonType.primary,
          isFullWidth: true,
        );

      case FriendshipStatus.requestSent:
        return AppButton(
          text: 'リクエスト送信済み',
          icon: Icons.schedule,
          onPressed: null,
          type: AppButtonType.secondary,
          isFullWidth: true,
        );

      case FriendshipStatus.requestReceived:
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: '承認',
                icon: Icons.check,
                onPressed: _acceptFriendRequest,
                type: AppButtonType.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: AppButton(
                text: '拒否',
                icon: Icons.close,
                onPressed: _rejectFriendRequest,
                type: AppButtonType.danger,
              ),
            ),
          ],
        );

      case FriendshipStatus.friends:
        return AppButton(
          text: 'フレンドを解除',
          icon: Icons.person_remove,
          onPressed: _removeFriend,
          type: AppButtonType.danger,
          isFullWidth: true,
        );
    }
  }

  /// フレンドリクエストを送信
  Future<void> _sendFriendRequest() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null) return;

    setState(() {
      _isProcessingFriendRequest = true;
    });

    try {
      final success = await FriendService.instance.sendFriendRequest(
        fromUserId: currentUser.userId,
        toUserId: _userData!.userId,
      );

      if (success && mounted) {
        // フレンドリクエスト送信後、ステータスを即座に更新
        setState(() {
          _friendshipStatus = FriendshipStatus.requestSent;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドリクエストを送信しました'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFriendRequest = false;
        });
      }
    }
  }

  /// フレンドリクエストを承認
  Future<void> _acceptFriendRequest() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null) return;

    setState(() {
      _isProcessingFriendRequest = true;
    });

    try {
      // リクエストを取得して承認
      final requests = await FriendService.instance.getIncomingRequests(currentUser.userId);
      final request = requests.where((r) => r.fromUserId == _userData!.userId).firstOrNull;

      if (request != null) {
        final success = await FriendService.instance.acceptFriendRequest(request.id!);

        if (success && mounted) {
          setState(() {
            _friendshipStatus = FriendshipStatus.friends;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('フレンドリクエストを承認しました'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFriendRequest = false;
        });
      }
    }
  }

  /// フレンドリクエストを拒否
  Future<void> _rejectFriendRequest() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null) return;

    setState(() {
      _isProcessingFriendRequest = true;
    });

    try {
      // リクエストを取得して拒否
      final requests = await FriendService.instance.getIncomingRequests(currentUser.userId);
      final request = requests.where((r) => r.fromUserId == _userData!.userId).firstOrNull;

      if (request != null) {
        final success = await FriendService.instance.rejectFriendRequest(request.id!);

        if (success && mounted) {
          setState(() {
            _friendshipStatus = FriendshipStatus.none;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('フレンドリクエストを拒否しました'),
                backgroundColor: AppColors.textSecondary,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFriendRequest = false;
        });
      }
    }
  }

  /// フレンドを解除
  Future<void> _removeFriend() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null || !mounted) return;

    // 確認ダイアログを表示
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド解除の確認'),
        content: Text('${_userData!.username}さんをフレンドから解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('解除する'),
          ),
        ],
      ),
    );

    if (shouldRemove != true) return;

    setState(() {
      _isProcessingFriendRequest = true;
    });

    try {
      final success = await FriendService.instance.removeFriend(
        currentUser.userId,
        _userData!.userId,
      );

      if (success && mounted) {
        setState(() {
          _friendshipStatus = FriendshipStatus.none;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドを解除しました'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFriendRequest = false;
        });
      }
    }
  }

  /// 主催イベントセクションを構築
  Widget _buildHostedEventsSection() {
    if (!_userData!.showHostedEvents) {
      return const SizedBox.shrink();
    }

    final hostedEventsAsync = ref.watch(publicHostedEventsProvider((
      userId: _userData!.id,
      showHostedEvents: _userData!.showHostedEvents,
    )));

    return hostedEventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: AppDimensions.cardElevation,
                offset: const Offset(0, AppDimensions.shadowOffsetY),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppColors.accent,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Text(
                    '主催イベント',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      '${events.length}件',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),
              ...events.take(3).map((event) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                child: EventCard(
                  event: event,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/event_detail',
                      arguments: event.id,
                    );
                  },
                ),
              )),
              if (events.length > 3)
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.spacingS),
                  alignment: Alignment.center,
                  child: Text(
                    '他 ${events.length - 3} 件のイベント',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  /// 参加予定イベントセクションを構築
  Widget _buildParticipatingEventsSection() {
    if (!_userData!.showParticipatingEvents) {
      return const SizedBox.shrink();
    }

    final participatingEventsAsync = ref.watch(publicParticipatingEventsProvider((
      userId: _userData!.id,
      showParticipatingEvents: _userData!.showParticipatingEvents,
    )));

    return participatingEventsAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: AppDimensions.cardElevation,
                offset: const Offset(0, AppDimensions.shadowOffsetY),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: AppColors.primary,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Text(
                    '参加予定イベント',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      '${events.length}件',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),
              ...events.take(3).map((event) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                child: EventCard(
                  event: event,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/event_detail',
                      arguments: event.id,
                    );
                  },
                ),
              )),
              if (events.length > 3)
                Container(
                  margin: const EdgeInsets.only(top: AppDimensions.spacingS),
                  alignment: Alignment.center,
                  child: Text(
                    '他 ${events.length - 3} 件のイベント',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}