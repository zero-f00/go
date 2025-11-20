import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../../shared/widgets/game_selection_dialog.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/models/game.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../providers/game_profile_provider.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/services/game_profile_service.dart';
import 'game_profile_edit_screen.dart';

/// お気に入りのゲーム管理画面
class FavoriteGamesScreen extends ConsumerStatefulWidget {
  const FavoriteGamesScreen({super.key});

  @override
  ConsumerState<FavoriteGamesScreen> createState() => _FavoriteGamesScreenState();
}

class _FavoriteGamesScreenState extends ConsumerState<FavoriteGamesScreen> {
  List<Game> _favoriteGames = [];
  List<GameProfile> _gameProfiles = [];
  bool _isLoading = true;
  bool _isDeleteMode = false;
  Set<String> _selectedGameIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ユーザーデータからお気に入りゲームを取得
      final currentUserData = await ref.read(currentUserDataProvider.future);
      if (currentUserData?.favoriteGameIds.isNotEmpty == true) {
        final games = await GameService.instance.getGamesByIds(currentUserData!.favoriteGameIds);
        _favoriteGames = games;
      }

      // ゲームプロフィールを取得
      final profiles = await ref.read(gameProfileListProvider.future);
      _gameProfiles = profiles;

      print('🔄 FavoriteGamesScreen: Data loaded');
      print('   favoriteGames: ${_favoriteGames.length} items');
      print('   gameProfiles: ${_gameProfiles.length} items');

      print('=== Favorite Games ===');
      for (final game in _favoriteGames) {
        print('   - Game: ${game.name}, ID: ${game.id}');
      }

      print('=== Game Profiles ===');
      for (final profile in _gameProfiles) {
        print('   - Profile: gameId=${profile.gameId}, username=${profile.gameUsername}, id=${profile.id}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // エラーハンドリング（必要に応じてユーザーに通知）
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
                title: 'お気に入りのゲーム',
                showBackButton: true,
                showUserIcon: false,
                actions: _favoriteGames.isNotEmpty ? [
                  if (_isDeleteMode && _selectedGameIds.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: _confirmBulkDelete,
                      tooltip: '選択したゲームを削除',
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      _isDeleteMode ? Icons.close : Icons.remove_circle_outline,
                      color: _isDeleteMode ? AppColors.textSecondary : AppColors.textSecondary,
                    ),
                    onPressed: _toggleDeleteMode,
                    tooltip: _isDeleteMode ? '削除モードを終了' : '削除モード',
                  ),
                ] : null,
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingView()
                    : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                'お気に入りゲームを読み込み中...',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_favoriteGames.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildQuickActions(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildGamesSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppDimensions.spacingXXL),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(AppDimensions.spacingXL),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.borderLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videogame_asset_outlined,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  Text(
                    'お気に入りゲームがありません',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeXL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'ゲームを追加してプロフィールを作成し、\nフレンドやイベントに参加しましょう！',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'ゲームを追加',
                      onTap: _onAddGame,
                      backgroundColor: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXXL),
          ],
        ),
      ),
    );
  }

  // 共通セクションコンテナ（他画面と同じスタイル）
  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final profiledGamesCount = _gameProfiles.length;
    final totalGamesCount = _favoriteGames.length;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ゲームプロフィール',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  '$profiledGamesCount/$totalGamesCount ゲーム設定済み',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videogame_asset,
              size: AppDimensions.iconL,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return _buildSectionContainer(
      title: 'クイックアクション',
      icon: Icons.flash_on,
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'ゲームを追加',
                onTap: _onAddGame,
                backgroundColor: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGamesSection() {
    return _buildSectionContainer(
      title: 'お気に入りゲーム一覧',
      icon: Icons.videogame_asset,
      children: _favoriteGames.map((game) {
        final existingProfile = _gameProfiles
            .where((profile) => profile.gameId == game.id.toString())
            .firstOrNull;

        print('🔄 FavoriteGamesScreen: Checking profile for game ${game.name}');
        print('   Game ID: ${game.id}');
        print('   Game ID (string): ${game.id.toString()}');
        print('   Existing profile: ${existingProfile != null ? 'Found' : 'Not found'}');
        if (existingProfile != null) {
          print('   Profile gameId: ${existingProfile.gameId}');
          print('   Profile gameUsername: ${existingProfile.gameUsername}');
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: _buildGameCard(game, existingProfile),
        );
      }).toList(),
    );
  }

  Widget _buildGameCard(Game game, GameProfile? profile) {
    final hasProfile = profile != null;
    final isSelected = _selectedGameIds.contains(game.id);

    return Container(
      decoration: BoxDecoration(
        color: _isDeleteMode && isSelected
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _isDeleteMode && isSelected
              ? AppColors.error
              : AppColors.borderLight,
          width: _isDeleteMode && isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: _isDeleteMode
              ? () => _toggleGameSelection(game.id ?? '')
              : () => _onGameTap(game, profile),
          onLongPress: !_isDeleteMode
              ? () {
                  // 触覚フィードバック
                  HapticFeedback.mediumImpact();
                  // 削除モードを開始し、このカードを選択状態にする
                  setState(() {
                    _isDeleteMode = true;
                    _selectedGameIds.add(game.id ?? '');
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGameCardHeader(game, hasProfile),
                    if (hasProfile) ...[
                      const SizedBox(height: AppDimensions.spacingM),
                      _buildProfileInfo(profile),
                    ],
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildGameCardFooter(hasProfile, profile),
                  ],
                ),
              ),
              if (_isDeleteMode) ...[
                // 削除モード時の選択インジケーター
                Positioned(
                  top: AppDimensions.spacingM,
                  right: AppDimensions.spacingM,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.error
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.error
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.textWhite,
                            size: 18,
                          )
                        : Icon(
                            Icons.remove_circle_outline,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                            size: 18,
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCardHeader(Game game, bool hasProfile) {
    return Row(
      children: [
        // ゲームアイコン（より大きく目立つように）
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: hasProfile ? AppColors.success.withValues(alpha: 0.3) : AppColors.borderLight,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: game.iconUrl?.isNotEmpty == true
                ? Image.network(
                    game.iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultGameIcon(),
                  )
                : _buildDefaultGameIcon(),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  // ステータスバッジをコンパクトに表示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: hasProfile ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasProfile ? Icons.check_circle : Icons.pending,
                          size: 14,
                          color: AppColors.textWhite,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          hasProfile ? '設定済み' : '未設定',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (game.developer.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  game.developer,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(GameProfile profile) {
    if (profile.summary.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        profile.summary,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGameCardFooter(bool hasProfile, GameProfile? profile) {
    return Row(
      children: [
        Expanded(
          child: hasProfile && profile != null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXS),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      '更新: ${_formatDate(profile.updatedAt)}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Text(
                  'ゲームプロフィールを設定してください',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasProfile ? Icons.edit : Icons.add_circle,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                hasProfile ? 'プロフィール編集' : 'プロフィール設定',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultGameIcon() {
    return Container(
      width: AppDimensions.iconXL,
      height: AppDimensions.iconXL,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: const Icon(
        Icons.videogame_asset,
        color: AppColors.primary,
        size: AppDimensions.iconM,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference < 7) {
      return '$difference日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  /// 削除モードの切り替え
  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        _selectedGameIds.clear();
      }
    });
  }

  /// カード選択の切り替え
  void _toggleGameSelection(String gameId) {
    setState(() {
      if (_selectedGameIds.contains(gameId)) {
        _selectedGameIds.remove(gameId);
      } else {
        _selectedGameIds.add(gameId);
      }
    });
  }

  /// 一括削除の確認ダイアログを表示
  void _confirmBulkDelete() {
    final selectedGames = _favoriteGames
        .where((game) => _selectedGameIds.contains(game.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: AppDimensions.iconL,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            const Expanded(
              child: Text('選択したゲームを削除'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '以下の${selectedGames.length}つのゲームをお気に入りから削除しますか？',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedGames.map((game) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '• ${game.name}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Expanded(
                    child: Text(
                      'ゲームプロフィールも同時に削除されます',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBulkDelete(selectedGames);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 一括削除を実行
  void _executeBulkDelete(List<Game> gamesToDelete) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        _showErrorSnackBar('ユーザー情報の取得に失敗しました');
        return;
      }

      // 各ゲームを個別にお気に入りから削除
      for (final game in gamesToDelete) {
        if (game.id != null) {
          await ref.read(userRepositoryProvider).removeFavoriteGame(currentUser.id, game.id!);
        }
      }

      // ゲームプロフィールも削除（存在する場合）
      for (final game in gamesToDelete) {
        final existingProfile = _gameProfiles
            .where((profile) => profile.gameId == game.id.toString())
            .firstOrNull;

        if (existingProfile != null) {
          final success = await GameProfileService.instance
              .deleteGameProfile(currentUser.id, existingProfile.gameId);
          if (!success) {
            print('⚠️ Failed to delete game profile for ${existingProfile.gameId}');
          }
        }
      }

      // プロバイダーのキャッシュを強制更新
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(gameProfileListProvider);

      // UI を更新
      await _loadData();

      // 削除モードを終了
      setState(() {
        _isDeleteMode = false;
        _selectedGameIds.clear();
      });

      if (mounted) {
        _showSuccessSnackBar('${gamesToDelete.length}つのゲームを削除しました');
      }
    } catch (e) {
      print('❌ 一括削除エラー: $e');
      _showErrorSnackBar('削除に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAddGame() {
    GameSelectionDialog.show(
      context,
      title: 'お気に入りゲームを追加',
      onGameSelected: (game) async {
        if (game != null && !_favoriteGames.any((g) => g.id == game.id)) {
          // ゲームを共有キャッシュに保存
          final gameId = await GameService.instance.getOrCacheGame(game);
          if (gameId != null) {
            // ユーザーのお気に入りゲームリストに追加
            final currentUserData = await ref.read(currentUserDataProvider.future);
            if (currentUserData != null) {
              final updatedFavoriteGameIds = [...currentUserData.favoriteGameIds, gameId];

              // お気に入りゲームを更新
              final updateRequest = UpdateUserRequest(
                username: currentUserData.username,
                userId: currentUserData.userId,
                bio: currentUserData.bio,
                contact: currentUserData.contact,
                favoriteGameIds: updatedFavoriteGameIds,
                photoUrl: currentUserData.photoUrl,
              );

              final userDataNotifier = ref.read(userDataNotifierProvider.notifier);
              await userDataNotifier.updateUserData(updateRequest);

              // データを再読み込み
              _loadData();
            }
          }
        }
      },
    );
  }

  void _onGameTap(Game game, GameProfile? existingProfile) {
    print('🔄 _onGameTap: game=${game.name}, hasProfile=${existingProfile != null}');
    if (existingProfile != null) {
      print('   Profile data: gameUsername=${existingProfile.gameUsername}, experience=${existingProfile.experience}');
    }

    // gameIdで新規作成用のプロフィールを作成、または既存プロフィールを編集
    final profileForEdit = existingProfile ?? GameProfile.create(
      gameId: game.id.toString(),
      userId: '', // 実際の値は編集画面で設定
      gameUsername: '',
      gameUserId: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameProfileEditScreen(
          profile: profileForEdit,
          gameIconUrl: game.iconUrl,
          gameName: game.name,
          gameId: game.id!.toString(),
        ),
      ),
    ).then((_) {
      // 編集後にデータを更新
      _loadData();
    });
  }

  /// ゲーム削除の確認ダイアログを表示
  void _confirmRemoveGame(Game game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: AppDimensions.iconL,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            const Expanded(
              child: Text('ゲームを削除'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「${game.name}」をお気に入りから削除しますか？',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  const Expanded(
                    child: Text(
                      'ゲームプロフィールも同時に削除されます',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeGame(game);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// ゲームをお気に入りから削除
  void _removeGame(Game game) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        _showErrorSnackBar('ユーザー情報の取得に失敗しました');
        return;
      }

      // お気に入りゲームから削除（専用メソッドを使用）
      await ref.read(userRepositoryProvider).removeFavoriteGame(currentUser.id, game.id ?? '');

      // ゲームプロフィールも削除（存在する場合）
      final existingProfile = _gameProfiles
          .where((profile) => profile.gameId == game.id.toString())
          .firstOrNull;

      if (existingProfile != null) {
        final success = await GameProfileService.instance
            .deleteGameProfile(currentUser.id, existingProfile.gameId);
        if (!success) {
          print('⚠️ Failed to delete game profile for ${existingProfile.gameId}');
        }
      }

      // プロバイダーのキャッシュを強制更新
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(gameProfileListProvider);

      // UI を更新
      await _loadData();

      if (mounted) {
        _showSuccessSnackBar('「${game.name}」をお気に入りから削除しました');
      }
    } catch (e) {
      print('❌ ゲーム削除エラー: $e');
      _showErrorSnackBar('削除に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 成功メッセージを表示
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.textWhite, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
    );
  }

  /// エラーメッセージを表示
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.textWhite, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
    );
  }

}