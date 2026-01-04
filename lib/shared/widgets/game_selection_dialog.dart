import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../l10n/app_localizations.dart';

class GameSelectionDialog extends ConsumerStatefulWidget {
  final Game? selectedGame;
  final Function(Game?) onGameSelected;
  final String? title;
  final bool allowNone;

  const GameSelectionDialog({
    super.key,
    this.selectedGame,
    required this.onGameSelected,
    this.title,
    this.allowNone = false,
  });

  static void show(
    BuildContext context, {
    Game? selectedGame,
    required Function(Game?) onGameSelected,
    String? title,
    bool allowNone = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GameSelectionDialog(
        selectedGame: selectedGame,
        onGameSelected: onGameSelected,
        title: title,
        allowNone: allowNone,
      ),
    );
  }

  @override
  ConsumerState<GameSelectionDialog> createState() => _GameSelectionDialogState();
}

class _GameSelectionDialogState extends ConsumerState<GameSelectionDialog> {
  final _searchController = TextEditingController();
  List<Game> _filteredGames = [];
  List<Game> _favoriteGames = [];
  Game? _selectedGame;
  bool _isLoading = false;
  bool _isFavoritesLoading = false;
  String? _errorMessage;
  int _selectedTabIndex = 0; // 0: お気に入り, 1: 検索

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.selectedGame;
    _searchController.addListener(_onSearchChanged);
    _loadFavoriteGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      _searchGames(query);
    } else {
      setState(() {
        _filteredGames = [];
        _errorMessage = null;
      });
    }
  }

  /// お気に入りゲームを読み込み
  Future<void> _loadFavoriteGames() async {
    setState(() {
      _isFavoritesLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);

      // AsyncValueからユーザーを取得
      User? user;
      authState.when(
        data: (data) => user = data,
        loading: () => user = null,
        error: (_, __) => user = null,
      );

      if (user == null) {
        setState(() {
          _favoriteGames = [];
          _isFavoritesLoading = false;
        });
        return;
      }

      final userRepository = UserRepository();
      final userData = await userRepository.getUserById(user!.uid);

      if (userData?.favoriteGameIds.isNotEmpty == true) {
        final favoriteGames = await GameService.instance.getFavoriteGames(userData!.favoriteGameIds);
        setState(() {
          _favoriteGames = favoriteGames;
        });
      } else {
        setState(() {
          _favoriteGames = [];
        });
      }
    } catch (e) {
      setState(() {
        _favoriteGames = [];
      });
    } finally {
      setState(() {
        _isFavoritesLoading = false;
      });
    }
  }

  Future<void> _searchGames(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final games = await GameService.instance.searchGames(query);
      setState(() {
        _filteredGames = games;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        setState(() {
          _errorMessage = l10n.gameSearchFailed(e.toString());
          _filteredGames = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectGame(Game game) {
    setState(() {
      _selectedGame = _selectedGame?.id == game.id ? null : game;
    });
  }

  void _onConfirm() {
    widget.onGameSelected(_selectedGame);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
          minWidth: 350,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabBar(),
            if (_selectedTabIndex == 1) _buildSearchSection(),
            Flexible(
              child: _buildGameList(),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.videogame_asset,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              widget.title ?? l10n.gameSelection,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Container(
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
                  Icons.search,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  l10n.searchTab2,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchGameHint,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.accent,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
                filled: true,
                fillColor: AppColors.cardBackground,
              ),
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: AppDimensions.fontSizeM,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameList() {
    if (_selectedTabIndex == 0) {
      // お気に入りタブ
      return _buildFavoriteGamesList();
    } else {
      // 検索タブ
      return _buildSearchGamesList();
    }
  }

  /// お気に入りゲームリスト
  Widget _buildFavoriteGamesList() {
    final l10n = L10n.of(context);
    if (_isFavoritesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingXL),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_favoriteGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border,
                color: AppColors.textSecondary,
                size: AppDimensions.iconXL,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.noFavoriteGamesShort,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimensions.fontSizeM,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.addFavoriteGamesFromProfile,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppDimensions.fontSizeS,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildGameListView(_favoriteGames);
  }

  /// 検索ゲームリスト
  Widget _buildSearchGamesList() {
    final l10n = L10n.of(context);
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingXL),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: AppDimensions.iconL,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: AppDimensions.fontSizeM,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: AppDimensions.iconXL,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.enterGameNameToSearch,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppDimensions.fontSizeM,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Text(
            l10n.gameNotFoundShort,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeM,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _buildGameListView(_filteredGames);
  }

  /// 共通のゲームリスト表示ウィジェット
  Widget _buildGameListView(List<Game> games) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final isSelected = _selectedGame?.id == game.id;

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectGame(game),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (game.iconUrl != null)
                      Container(
                        width: AppDimensions.iconXL,
                        height: AppDimensions.iconXL,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          image: DecorationImage(
                            image: NetworkImage(game.iconUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: AppDimensions.iconXL,
                        height: AppDimensions.iconXL,
                        decoration: BoxDecoration(
                          color: AppColors.overlayMedium,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: const Icon(
                          Icons.videogame_asset,
                          color: AppColors.textSecondary,
                          size: AppDimensions.iconM,
                        ),
                      ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.accent : AppColors.textDark,
                            ),
                          ),
                          if (game.developer.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              game.developer,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: AppDimensions.iconM,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          if (widget.allowNone)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  widget.onGameSelected(null);
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: Text(
                  l10n.notSelected,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.allowNone) const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedGame != null ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Text(
                _selectedGame != null ? l10n.select : l10n.selectGame,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// タブバー
  Widget _buildTabBar() {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 0;
                  _searchController.clear();
                  _filteredGames = [];
                  _errorMessage = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.accent : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusM),
                    bottomLeft: Radius.circular(AppDimensions.radiusM),
                  ),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: _selectedTabIndex == 0 ? Colors.white : AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.favoritesTab,
                      style: TextStyle(
                        color: _selectedTabIndex == 0 ? Colors.white : AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimensions.fontSizeM,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.accent : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppDimensions.radiusM),
                    bottomRight: Radius.circular(AppDimensions.radiusM),
                  ),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      color: _selectedTabIndex == 1 ? Colors.white : AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.searchTab2,
                      style: TextStyle(
                        color: _selectedTabIndex == 1 ? Colors.white : AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: AppDimensions.fontSizeM,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}