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
import '../providers/game_profile_provider.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/services/game_profile_service.dart';
import '../../../shared/services/recommendation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      // ユーザーデータからお気に入りゲームを取得（watchを使用して変更を監視）
      final currentUserData = await ref.read(currentUserDataProvider.future);
      if (currentUserData?.favoriteGameIds.isNotEmpty == true) {
        final games = await GameService.instance.getGamesByIds(currentUserData!.favoriteGameIds);
        _favoriteGames = games;
      } else {
        _favoriteGames = [];
      }

      // ゲームプロフィールを取得
      final profiles = await ref.read(gameProfileListProvider.future);
      _gameProfiles = profiles;

      // 直接サービスからも取得を試行（プロバイダーに問題がある場合のフォールバック）
      if (profiles.isEmpty && currentUserData != null) {
        final directProfiles = await GameProfileService.instance.getUserGameProfiles(currentUserData.id);
        _gameProfiles = directProfiles;
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
    // プロバイダーの変更を監視（これにより自動的に再ビルドされる）
    ref.watch(currentUserDataProvider);
    ref.watch(gameProfileListProvider);

    // データが更新されたら再読み込み
    ref.listen<AsyncValue<UserData?>>(
      currentUserDataProvider,
      (previous, next) {
        if (next.hasValue && mounted && !_isLoading) {
          _loadData();
        }
      },
    );

    ref.listen<AsyncValue<List<GameProfile>>>(
      gameProfileListProvider,
      (previous, next) {
        if (next.hasValue && mounted && !_isLoading) {
          _loadData();
        }
      },
    );

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
                        color: AppColors.textWhite,
                      ),
                      onPressed: _confirmBulkDelete,
                      tooltip: '選択したゲームを削除',
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      _isDeleteMode ? Icons.close : Icons.remove_circle_outline,
                      color: AppColors.textWhite,
                    ),
                    onPressed: _toggleDeleteMode,
                    tooltip: _isDeleteMode ? '削除モードを終了' : '削除モード',
                  ),
                ] : null,
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
                              ? _buildLoadingView()
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
      child: Row(
        children: [
          Icon(
            Icons.videogame_asset,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          const Text(
            'お気に入りのゲーム',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (_favoriteGames.isNotEmpty)
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
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Padding(
      padding: EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: AppDimensions.spacingM),
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
    );
  }

  Widget _buildContent() {
    if (_favoriteGames.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingS,
      ),
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
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'クイックアクション',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
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
      ),
    );
  }

  Widget _buildGamesSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.videogame_asset,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'お気に入りゲーム一覧',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ..._favoriteGames.map((game) {
            final existingProfile = _gameProfiles
                .where((profile) =>
                  profile.gameId == game.id.toString() ||
                  profile.gameId == game.id
                )
                .firstOrNull;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
              child: _buildGameCard(game, existingProfile),
            );
          }),
        ],
      ),
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
      ),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: _isDeleteMode
              ? () => _toggleGameSelection(game.id)
              : () => _onGameTap(game, profile),
          onLongPress: !_isDeleteMode
              ? () {
                  // 触覚フィードバック
                  HapticFeedback.mediumImpact();
                  // 削除モードを開始し、このカードを選択状態にする
                  setState(() {
                    _isDeleteMode = true;
                    _selectedGameIds.add(game.id);
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
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        _showErrorSnackBar('ユーザー情報の取得に失敗しました');
        return;
      }

      // 削除予定のゲームIDを取得
      final gameIdsToDelete = gamesToDelete.map((game) => game.id).toSet();

      // UIを即座に更新（楽観的更新）
      setState(() {
        _favoriteGames.removeWhere((game) => gameIdsToDelete.contains(game.id));
        _gameProfiles.removeWhere((profile) => gameIdsToDelete.contains(profile.gameId));
        _isDeleteMode = false;
        _selectedGameIds.clear();
      });

      // バックグラウンドでFirestoreから削除
      // 各ゲームを個別にお気に入りから削除
      for (final game in gamesToDelete) {
        await ref.read(userRepositoryProvider).removeFavoriteGame(currentUser.id, game.id);
      }

      // ゲームプロフィールも削除（存在する場合）
      for (final game in gamesToDelete) {
        // プロフィールをgameIdで検索（game.idを文字列として比較）
        final gameIdStr = game.id.toString();

        // _gameProfilesから検索（既に取得済みのプロフィール）
        final existingProfile = _gameProfiles
            .where((profile) => profile.gameId == gameIdStr)
            .firstOrNull;

        // プロフィールが存在する場合は削除
        if (existingProfile != null) {
          try {
            await GameProfileService.instance
                .deleteGameProfile(currentUser.id, gameIdStr);
          } catch (e) {
            // プロフィール削除が失敗してもお気に入り削除は継続
          }
        } else {
          // プロフィールが見つからない場合でも、念のため削除を試みる
          try {
            await GameProfileService.instance
                .deleteGameProfile(currentUser.id, gameIdStr);
          } catch (e) {
            // プロフィールが存在しない場合は無視
          }
        }
      }

      // プロバイダーのキャッシュを強制更新
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(gameProfileListProvider);

      // おすすめイベントを更新（お気に入りゲームが変わったため）
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid != null) {
        ref.invalidate(recommendedEventsProvider(firebaseUid));
      }

      if (mounted) {
        _showSuccessSnackBar('${gamesToDelete.length}つのゲームを削除しました');
      }
    } catch (e) {
      // エラーが発生した場合は元の状態に戻す
      _loadData();
      _showErrorSnackBar('削除に失敗しました: $e');
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

              // おすすめイベントを更新（お気に入りゲームが変わったため）
              final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
              if (firebaseUid != null) {
                ref.invalidate(recommendedEventsProvider(firebaseUid));
              }

              // データを再読み込み
              _loadData();
            }
          }
        }
      },
    );
  }

  void _onGameTap(Game game, GameProfile? existingProfile) {

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
          gameId: game.id.toString(),
        ),
      ),
    ).then((result) {
      // 編集または削除後にデータを更新
      // resultがtrueの場合は編集・削除が行われた
      if (result == true) {
        // プロバイダーの無効化により自動的に再読み込みされるが、
        // 念のため明示的にも再読み込み
        _loadData();
      }
    });
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
            Flexible(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
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
            Flexible(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
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