import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/empty_search_result.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/social_stats_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';

/// ソーシャルリストタイプ
enum _SocialListType {
  friends,
  following,
  followers,
}

extension _SocialListTypeExtension on _SocialListType {
  String get emptyMessage {
    switch (this) {
      case _SocialListType.friends:
        return '相互フォローがいません';
      case _SocialListType.following:
        return 'フォロー中のユーザーがいません';
      case _SocialListType.followers:
        return 'フォロワーがいません';
    }
  }

  String get emptySubMessage {
    switch (this) {
      case _SocialListType.friends:
        return '気になるユーザーをフォローして\n相互フォローになりましょう';
      case _SocialListType.following:
        return '気になるユーザーをフォローして\nイベント情報を受け取りましょう';
      case _SocialListType.followers:
        return 'あなたをフォローしてくれる\nユーザーを待っています';
    }
  }

  IconData get icon {
    switch (this) {
      case _SocialListType.friends:
        return Icons.sync_alt;
      case _SocialListType.following:
        return Icons.person_add_alt_1;
      case _SocialListType.followers:
        return Icons.person_add;
    }
  }
}

/// フォロー画面（相互フォロー・フォロー中・フォロワーを管理）
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<UserData> _friends = [];
  List<UserData> _following = [];
  List<UserData> _followers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// データを読み込み
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser != null) {
        final socialStatsService = SocialStatsService.instance;

        final friends = await socialStatsService.getFriendsList(currentUser.userId);
        final following = await socialStatsService.getFollowingList(currentUser.userId);
        final followers = await socialStatsService.getFollowersList(currentUser.userId);

        setState(() {
          _friends = friends;
          _following = following;
          _followers = followers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ユーザー情報が取得できませんでした';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
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
                title: 'フォロー',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
                actions: [
                  GestureDetector(
                    onTap: () => _showUserSearchModal(context),
                    child: Container(
                      width: AppDimensions.headerButtonSize,
                      height: AppDimensions.headerButtonSize,
                      decoration: BoxDecoration(
                        color: AppColors.overlayLight,
                        borderRadius: BorderRadius.circular(AppDimensions.headerButtonSize / 2),
                      ),
                      child: const Icon(
                        Icons.person_search,
                        color: AppColors.textOnPrimary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Container(
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
                        _buildUnifiedHeader(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 統一ヘッダーを構築
  Widget _buildUnifiedHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync_alt,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'フォロー',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
              tabs: [
                Tab(
                  text: '相互フォロー (${_friends.length})',
                ),
                Tab(
                  text: 'フォロー中 (${_following.length})',
                ),
                Tab(
                  text: 'フォロワー (${_followers.length})',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'データを取得中...',
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
                onPressed: _loadData,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// メインコンテンツを構築
  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserList(_friends, _SocialListType.friends),
        _buildUserList(_following, _SocialListType.following),
        _buildUserList(_followers, _SocialListType.followers),
      ],
    );
  }

  /// ユーザーリストを構築
  Widget _buildUserList(List<UserData> users, _SocialListType type) {
    if (users.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingS,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          return _buildUserCard(users[index]);
        },
      ),
    );
  }

  /// 空の状態を構築
  Widget _buildEmptyState(_SocialListType type) {
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
              child: Icon(
                type.icon,
                size: AppDimensions.iconXL,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              type.emptyMessage,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              type.emptySubMessage,
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

  /// ユーザーカードを構築
  Widget _buildUserCard(UserData user) {
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
          onTap: () => _navigateToUserProfile(user.userId),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                UserAvatar(
                  avatarUrl: user.photoUrl,
                  size: 50,
                  backgroundColor: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '@${user.userId}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (user.bio?.isNotEmpty == true) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          user.bio!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ユーザープロフィール画面に遷移
  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(
      context,
      '/user_profile',
      arguments: {'userId': userId},
    );
  }

  /// ユーザー検索モーダルを表示
  void _showUserSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _UserSearchModal(),
    );
  }
}

/// ユーザー検索モーダル
class _UserSearchModal extends StatefulWidget {
  const _UserSearchModal();

  @override
  State<_UserSearchModal> createState() => _UserSearchModalState();
}

class _UserSearchModalState extends State<_UserSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _userRepository = UserRepository();

  List<UserData> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // モーダル表示時に自動でフォーカスを当てる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// ユーザー検索を実行
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _userRepository.searchUsers(query, limit: 20);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'ユーザー検索中にエラーが発生しました';
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.spacingM),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.person_search,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Expanded(
                  child: Text(
                    'ユーザーを検索',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingS),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: AppDimensions.iconS,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 検索フィールド
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'ユーザー名またはIDで検索...',
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppDimensions.fontSizeM,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconM,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconM,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingM,
                ),
              ),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
              onChanged: (value) {
                setState(() {});
                _performSearch();
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // 検索結果
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: _buildSearchContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty) {
      return EmptySearchResult.user(_searchController.text);
    }

    return _buildResultsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: AppDimensions.iconXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            const Text(
              'ユーザー名またはIDで検索',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            const Text(
              'フォローしたいユーザーを\n検索して見つけましょう',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            const Text(
              'ユーザーを検索中...',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            const Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
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

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  Widget _buildUserTile(UserData user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: () {
            Navigator.pop(context); // モーダルを閉じる
            Navigator.pushNamed(
              context,
              '/user_profile',
              arguments: user.userId,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                UserAvatar(
                  size: 50,
                  avatarUrl: user.photoUrl,
                  backgroundColor: AppColors.overlayLight,
                  iconColor: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        '@${user.userId}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          user.bio!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: AppDimensions.iconS,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}