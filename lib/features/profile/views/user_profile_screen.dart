import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/services/follow_service.dart';
import '../../../shared/services/user_event_service.dart';
import '../../../shared/services/social_stats_service.dart';
import '../../../shared/services/user_profile_share_service.dart';
import '../../../shared/models/game.dart';
import '../../../shared/widgets/compact_event_card.dart';
import '../../../shared/widgets/generic_event_list_screen.dart';
import '../../../shared/services/event_filter_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../features/game_profile/providers/game_profile_provider.dart';
import '../../../features/game_event_management/models/game_event.dart';
import '../../../data/models/event_model.dart';
import '../../../shared/utils/event_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/auth_dialog.dart';
import '../../calendar/views/participating_events_screen.dart';

/// ユーザープロフィール表示画面
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserData? _userData;
  List<Game> _favoriteGames = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFollowing = false;
  bool _isProcessingFollow = false;
  SocialStats _socialStats = const SocialStats(
    friendCount: 0,
    followerCount: 0,
    followingCount: 0,
  );

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

      // まずカスタムユーザーIDで検索を試行
      UserData? userData = await userRepository.getUserByCustomId(
        widget.userId,
      );

      // カスタムユーザーIDで見つからない場合は、Firebase Auth UIDで検索を試行
      if (userData == null) {
        userData = await userRepository.getUserById(widget.userId);
      }

      if (userData != null) {
        // お気に入りゲーム情報を取得
        final games = await GameService.instance.getGamesByIds(
          userData.favoriteGameIds,
        );

        // ソーシャル統計を取得
        final socialStats = await SocialStatsService.instance.getSocialStats(
          userData.userId,
        );

        // フォロー状態を取得
        final currentUserAsync = await ref.read(currentUserDataProvider.future);
        if (currentUserAsync != null) {
          await _loadFollowStatus(currentUserAsync.userId, userData.userId);
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

  /// フォロー状態を読み込み
  Future<void> _loadFollowStatus(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final isFollowing = await FollowService.instance.isFollowing(
        currentUserId,
        targetUserId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      // フォロー状態の取得に失敗した場合はデフォルト状態を維持
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
      }
    }
  }

  /// ヘッダーのアクションボタンを構築
  List<Widget>? _buildHeaderActions() {
    // ユーザーデータがない場合やシェア不可の場合はボタンを表示しない
    if (_userData == null ||
        !UserProfileShareService.canShareUserProfile(_userData!)) {
      return null;
    }

    return [
      GestureDetector(
        onTap: () => _shareUserProfile(),
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
            Icons.share,
            color: AppColors.textOnPrimary,
            size: AppDimensions.iconM,
          ),
        ),
      ),
    ];
  }

  /// ユーザープロフィールを共有
  Future<void> _shareUserProfile() async {
    if (_userData == null) return;

    try {
      // iPadでのシェアシート位置を取得
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin =
          box != null
              ? box.localToGlobal(Offset.zero) & box.size
              : null;

      await UserProfileShareService.shareUserProfile(
        _userData!,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('共有に失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
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
                actions: _buildHeaderActions(),
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
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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
          _buildSocialLinksSection(),
          _buildUserInfo(),
          _buildFavoriteGamesSection(),
          if (_userData != null) ...[
            _buildManagedEventsSection(),
            _buildParticipatingEventsSection(),
            _buildParticipatedEventsSection(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            ],
                          ),
                        ),
                        _buildCompactFollowButton(),
                      ],
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

  /// コンパクトなフォローボタンを構築（ヘッダー内用）
  Widget _buildCompactFollowButton() {
    final currentUserAsync = ref.watch(currentUserDataProvider);
    final currentUser = currentUserAsync.asData?.value;

    // 現在のユーザーがサインインしていない場合
    if (currentUser == null) {
      return _buildFollowActionButton(
        icon: Icons.person_add_alt_1,
        label: 'フォロー',
        isActive: false,
        onTap: () async {
          final result = await AuthDialog.show(context);
          if (result == true && mounted) {
            _loadUserData();
          }
        },
      );
    }

    // 自分自身のプロフィールの場合は表示しない
    final isOwnProfile =
        currentUser.userId == widget.userId ||
        currentUser.id == widget.userId ||
        (_userData != null &&
            (currentUser.userId == _userData!.userId ||
                currentUser.id == _userData!.userId ||
                currentUser.userId == _userData!.id ||
                currentUser.id == _userData!.id));

    if (isOwnProfile) {
      return const SizedBox.shrink();
    }

    // 処理中
    if (_isProcessingFollow) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
          ),
        ),
      );
    }

    // フォロー中
    if (_isFollowing) {
      return _buildFollowActionButton(
        icon: Icons.check,
        label: 'フォロー中',
        isActive: true,
        onTap: _unfollow,
      );
    }

    // 未フォロー
    return _buildFollowActionButton(
      icon: Icons.person_add_alt_1,
      label: 'フォロー',
      isActive: false,
      onTap: _follow,
    );
  }

  /// フォローアクションボタンを構築
  Widget _buildFollowActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? AppColors.primary : Colors.white,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ソーシャル統計行を構築
  Widget _buildSocialStatsRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => _onStatItemTap('相互フォロー'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '相互フォロー',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeXS,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${_socialStats.friendCount}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 統計アイテムタップ時の処理
  void _onStatItemTap(String label) async {
    // 自分のプロフィールかどうか確認
    try {
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser != null && currentUser.userId == widget.userId) {
        // 自分のプロフィールの場合は相互フォローリスト画面へ
        if (mounted) {
          Navigator.pushNamed(context, '/friends');
        }
      }
      // 他人のプロフィールの場合は何もしない（将来的に詳細表示画面を実装）
    } catch (e) {
      // エラーが発生した場合は何もしない
    }
  }

  /// SNSリンクセクションを構築
  Widget _buildSocialLinksSection() {
    if (_userData?.socialLinks == null || _userData!.socialLinks!.isEmpty) {
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
          Row(
            children: [
              Icon(
                Icons.share,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'SNSアカウント',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingM,
            children: _userData!.socialLinks!.entries
                .map((entry) => _buildSocialLink(entry.key, entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// SNSリンクボタンを構築
  Widget _buildSocialLink(String platform, String username) {
    final Map<String, Map<String, dynamic>> platformInfo = {
      'twitter': {
        'icon': Icons.close,
        'label': 'X',
        'color': const Color(0xFF1DA1F2),
        'url': 'https://twitter.com/$username',
        'displayFormat': '@$username',
      },
      'tiktok': {
        'icon': Icons.music_note,
        'label': 'TikTok',
        'color': const Color(0xFFFF0050),
        'url': 'https://www.tiktok.com/@$username',
        'displayFormat': '@$username',
      },
      'youtube': {
        'icon': Icons.play_circle_fill,
        'label': 'YouTube',
        'color': const Color(0xFFFF0000),
        'url': 'https://youtube.com/@$username',
        'displayFormat': '@$username',
      },
      'instagram': {
        'icon': Icons.camera_alt,
        'label': 'Instagram',
        'color': const Color(0xFFE4405F),
        'url': 'https://instagram.com/$username',
        'displayFormat': '@$username',
      },
      'twitch': {
        'icon': Icons.videogame_asset,
        'label': 'Twitch',
        'color': const Color(0xFF9146FF),
        'url': 'https://twitch.tv/$username',
        'displayFormat': username,
      },
      'discord': {
        'icon': Icons.chat,
        'label': 'Discord',
        'color': const Color(0xFF5865F2),
        'url': 'https://discord.com', // Discord IDはコピー用
        'displayFormat': username,
      },
    };

    final info = platformInfo[platform];
    if (info == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => platform == 'discord'
          ? _copyDiscordUsername(username)
          : _openSocialLink(info['url'] as String),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: (info['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: (info['color'] as Color).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                info['icon'] as IconData,
                color: info['color'] as Color,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info['label'] as String,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: info['color'] as Color,
                    ),
                  ),
                  Text(
                    info['displayFormat'] as String,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeXS,
                      color: (info['color'] as Color).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SNSリンクを開く
  Future<void> _openSocialLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('リンクを開けませんでした'),
              backgroundColor: AppColors.error,
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
    }
  }

  /// Discord IDをクリップボードにコピー
  Future<void> _copyDiscordUsername(String discordId) async {
    try {
      await Clipboard.setData(ClipboardData(text: discordId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discord ID "$discordId" をコピーしました'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('コピーに失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ユーザー情報セクションを構築
  Widget _buildUserInfo() {
    if ((_userData!.bio?.isEmpty ?? true) &&
        (_userData!.contact?.isEmpty ?? true)) {
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
                  Icons.info,
                  color: AppColors.primary,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Text(
                  'その他の情報',
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
              children: _favoriteGames
                  .map((game) => _buildGameCard(game))
                  .toList(),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        onTap: () => _onGameTap(game),
        child: Container(
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
              GameIcon(iconUrl: game.iconUrl, size: 50, gameName: game.name),
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
        ),
      ),
    );
  }

  /// フォローする
  Future<void> _follow() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null) return;

    setState(() {
      _isProcessingFollow = true;
    });

    try {
      final success = await FollowService.instance.follow(
        followerId: currentUser.userId,
        followeeId: _userData!.userId,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _isFollowing = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_userData!.username}さんをフォローしました'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フォローに失敗しました'),
              backgroundColor: AppColors.error,
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
          _isProcessingFollow = false;
        });
      }
    }
  }

  /// フォロー解除
  Future<void> _unfollow() async {
    final currentUser = await ref.read(currentUserDataProvider.future);
    if (currentUser == null || _userData == null) return;

    setState(() {
      _isProcessingFollow = true;
    });

    try {
      final success = await FollowService.instance.unfollow(
        followerId: currentUser.userId,
        followeeId: _userData!.userId,
      );

      if (mounted) {
        if (success) {
          setState(() {
            _isFollowing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_userData!.username}さんのフォローを解除しました'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フォロー解除に失敗しました'),
              backgroundColor: AppColors.error,
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
          _isProcessingFollow = false;
        });
      }
    }
  }

  /// 運営者イベントセクションを構築（主催＋共同編集者）
  Widget _buildManagedEventsSection() {
    // showHostedEventsまたはshowManagedEventsがtrueの場合に表示
    if (!_userData!.showHostedEvents && !_userData!.showManagedEvents) {
      return const SizedBox.shrink();
    }

    final managedEventsAsync = ref.watch(
      publicManagedEventsProvider((
        userId: _userData!.userId,
        showManagedEvents: _userData!.showHostedEvents || _userData!.showManagedEvents,
      )),
    );

    return managedEventsAsync.when(
      data: (events) {
        // NGユーザーのイベントを除外
        final currentUser = ref.watch(currentFirebaseUserProvider);
        final filteredEvents = EventFilterService.filterBlockedUserEvents(
          events,
          currentUser?.uid,
        );

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
                    Icons.admin_panel_settings,
                    color: AppColors.accent,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Text(
                    '運営者としてのイベント',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (filteredEvents.isNotEmpty)
                    TextButton(
                      onPressed: () => _navigateToManagedEventsList(filteredEvents),
                      child: const Text(
                        'もっと見る',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              if (filteredEvents.isEmpty)
                _buildEmptyEventState(
                  icon: Icons.admin_panel_settings,
                  message: '運営者として関わるイベントはありません',
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: (filteredEvents.length > 3) ? 3 : filteredEvents.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(
                          right: AppDimensions.spacingM,
                        ),
                        child: CompactEventCard(
                          event: filteredEvents[index],
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/event_detail',
                              arguments: filteredEvents[index].id,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => _buildEventSectionLoading('運営者としてのイベント', Icons.admin_panel_settings),
      error: (error, _) => const SizedBox.shrink(),
    );
  }

  /// 運営者イベント一覧画面への遷移
  void _navigateToManagedEventsList(List<dynamic> events) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenericEventListScreen(
          title: '運営者としてのイベント',
          events: events.cast(),
          onEventTap: (event) {
            Navigator.pushNamed(
              context,
              '/event_detail',
              arguments: event.id,
            );
          },
          emptyTitle: '運営者として関わるイベントはありません',
          emptyMessage: 'イベントを作成するか、\n共同編集者として招待されると表示されます',
          emptyIcon: Icons.admin_panel_settings,
        ),
      ),
    );
  }

  /// 参加予定イベントセクションを構築
  Widget _buildParticipatingEventsSection() {
    if (!_userData!.showParticipatingEvents) {
      return const SizedBox.shrink();
    }

    // ParticipationServiceを使用して参加申請を取得
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplicationsWithBothIds(
        firebaseUid: _userData!.id,
        customUserId: _userData!.userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEventSectionLoading('参加予定イベント', Icons.event_available);
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final applications = snapshot.data ?? [];
        final approvedApplications = applications
            .where((app) => app.status == ParticipationStatus.approved)
            .toList();

        return FutureBuilder<List<GameEvent>>(
          future: _getUpcomingEventsFromApplications(approvedApplications),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return _buildEventSectionLoading('参加予定イベント', Icons.event_available);
            }

            final events = eventSnapshot.data ?? [];

            // NGユーザーのイベントを除外
            final currentUser = ref.watch(currentFirebaseUserProvider);
            final filteredEvents = EventFilterService.filterBlockedUserEvents(
              events,
              currentUser?.uid,
            );

            return _buildParticipatingEventsContent(filteredEvents, approvedApplications);
          },
        );
      },
    );
  }

  /// 参加予定イベントの内容を構築
  Widget _buildParticipatingEventsContent(
    List<GameEvent> filteredEvents,
    List<ParticipationApplication> approvedApplications,
  ) {
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
              if (approvedApplications.isNotEmpty)
                TextButton(
                  onPressed: () => _navigateToParticipatingEventsList(approvedApplications),
                  child: const Text(
                    'もっと見る',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          if (filteredEvents.isEmpty)
            _buildEmptyEventState(
              icon: Icons.event_available,
              message: '参加予定のイベントはありません',
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: (filteredEvents.length > 3) ? 3 : filteredEvents.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(
                      right: AppDimensions.spacingM,
                    ),
                    child: CompactEventCard(
                      event: filteredEvents[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/event_detail',
                          arguments: filteredEvents[index].id,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 承認済み申請から参加予定イベントを取得
  Future<List<GameEvent>> _getUpcomingEventsFromApplications(
    List<ParticipationApplication> applications,
  ) async {
    if (applications.isEmpty) return [];

    final List<GameEvent> events = [];
    final now = DateTime.now();

    for (final application in applications) {
      final event = await _getEventFromApplication(application);
      // イベント開始時刻が未来のもののみ表示（開始時刻を過ぎたら参加予定から除外）
      if (event != null && event.startDate.isAfter(now)) {
        events.add(event);
      }
    }

    events.sort((a, b) => a.startDate.compareTo(b.startDate));
    return events;
  }

  /// 申請からイベントを取得
  Future<GameEvent?> _getEventFromApplication(ParticipationApplication application) async {
    try {
      // まず gameEvents コレクションから取得を試みる
      final gameEventDoc = await FirebaseFirestore.instance
          .collection('gameEvents')
          .doc(application.eventId)
          .get();

      if (gameEventDoc.exists && gameEventDoc.data() != null) {
        final data = gameEventDoc.data()!;
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInList(data)) {
          return null;
        }
        return GameEvent.fromFirestore(data, gameEventDoc.id);
      }

      // 次に events コレクションから取得を試みる
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(application.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        final data = eventDoc.data()!;
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInList(data)) {
          return null;
        }
        final event = Event.fromFirestore(eventDoc);
        return await EventConverter.eventToGameEvent(event);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// イベントが一覧に表示可能かどうか
  bool _isEventVisibleInList(Map<String, dynamic> eventData) {
    final status = eventData['status'] as String?;
    final visibility = eventData['visibility'] as String?;

    // 下書き状態のイベントは表示しない
    if (status == 'draft') {
      return false;
    }

    // 非公開イベントは表示しない
    if (visibility == 'private') {
      return false;
    }

    return status == 'published' || status == 'scheduled' || status == 'active';
  }

  /// 参加予定イベント一覧画面への遷移
  void _navigateToParticipatingEventsList(List<ParticipationApplication> approvedApplications) async {
    // 承認済み申請からイベント一覧を取得
    final List<GameEvent> events = [];
    final now = DateTime.now();

    for (final application in approvedApplications) {
      final event = await _getEventFromApplication(application);
      // イベント開始時刻が未来のもののみ表示（開始時刻を過ぎたら参加予定から除外）
      if (event != null && event.startDate.isAfter(now)) {
        events.add(event);
      }
    }

    // 開催日順でソート
    events.sort((a, b) => a.startDate.compareTo(b.startDate));

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipatingEventsScreen(
          firebaseUid: _userData!.id,
          initialEvents: events,
        ),
      ),
    );
  }

  /// 過去参加済みイベントセクションを構築
  Widget _buildParticipatedEventsSection() {
    if (!_userData!.showParticipatedEvents) {
      return const SizedBox.shrink();
    }

    // ParticipationServiceを使用して参加申請を取得
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplicationsWithBothIds(
        firebaseUid: _userData!.id,
        customUserId: _userData!.userId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEventSectionLoading('過去参加済みイベント', Icons.history);
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final applications = snapshot.data ?? [];
        final approvedApplications = applications
            .where((app) => app.status == ParticipationStatus.approved)
            .toList();

        return FutureBuilder<List<GameEvent>>(
          future: _getPastEventsFromApplications(approvedApplications),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return _buildEventSectionLoading('過去参加済みイベント', Icons.history);
            }

            final events = eventSnapshot.data ?? [];

            // NGユーザーのイベントを除外
            final currentUser = ref.watch(currentFirebaseUserProvider);
            final filteredEvents = EventFilterService.filterBlockedUserEvents(
              events,
              currentUser?.uid,
            );

            return _buildParticipatedEventsContent(filteredEvents);
          },
        );
      },
    );
  }

  /// 過去参加済みイベントの内容を構築
  Widget _buildParticipatedEventsContent(List<GameEvent> filteredEvents) {
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
                Icons.history,
                color: AppColors.textSecondary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '過去参加済みイベント',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (filteredEvents.isNotEmpty)
                TextButton(
                  onPressed: () => _navigateToParticipatedEventsList(filteredEvents),
                  child: const Text(
                    'もっと見る',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          if (filteredEvents.isEmpty)
            _buildEmptyEventState(
              icon: Icons.history,
              message: '過去に参加したイベントはありません',
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: (filteredEvents.length > 3) ? 3 : filteredEvents.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(
                      right: AppDimensions.spacingM,
                    ),
                    child: CompactEventCard(
                      event: filteredEvents[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/event_detail',
                          arguments: filteredEvents[index].id,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 承認済み申請から過去参加済みイベントを取得
  Future<List<GameEvent>> _getPastEventsFromApplications(
    List<ParticipationApplication> applications,
  ) async {
    if (applications.isEmpty) return [];

    final List<GameEvent> events = [];
    final now = DateTime.now();

    for (final application in applications) {
      final event = await _getEventFromApplication(application);
      // 過去のイベント（開始日が現在より前）のみ取得
      if (event != null && event.startDate.isBefore(now)) {
        events.add(event);
      }
    }

    // 新しい順にソート
    events.sort((a, b) => b.startDate.compareTo(a.startDate));
    return events;
  }

  /// 過去参加済みイベント一覧画面への遷移
  void _navigateToParticipatedEventsList(List<dynamic> events) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GenericEventListScreen(
          title: '過去参加済みイベント',
          events: events.cast(),
          onEventTap: (event) {
            Navigator.pushNamed(
              context,
              '/event_detail',
              arguments: event.id,
            );
          },
          emptyTitle: '過去に参加したイベントはありません',
          emptyMessage: 'イベントに参加すると\nこちらに履歴が表示されます',
          emptyIcon: Icons.history,
        ),
      ),
    );
  }

  /// ゲームタップ時の処理
  Future<void> _onGameTap(Game game) async {
    try {
      // ゲームプロフィールを取得
      final gameProfileService = ref.read(gameProfileServiceProvider);
      final gameProfile = await gameProfileService.getGameProfile(
        _userData!.id,
        game.id,
      );

      if (gameProfile != null && mounted) {
        Navigator.pushNamed(
          context,
          '/game_profile_view',
          arguments: {
            'profile': gameProfile,
            'userData': _userData,
            'gameName': game.name,
            'gameIconUrl': game.iconUrl,
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ゲームプロフィールが見つかりません'),
            backgroundColor: AppColors.error,
          ),
        );
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
    }
  }

  /// イベントセクションの空状態を構築
  Widget _buildEmptyEventState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXL,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// イベントセクションのローディング状態を構築
  Widget _buildEventSectionLoading(String title, IconData icon) {
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
                icon,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          const Center(
            child: SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
