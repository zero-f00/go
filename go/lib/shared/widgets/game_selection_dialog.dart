import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/game.dart';
import '../services/game_service.dart';

class GameSelectionDialog extends StatefulWidget {
  final Game? selectedGame;
  final Function(Game?) onGameSelected;
  final String title;
  final bool allowNone;

  const GameSelectionDialog({
    super.key,
    this.selectedGame,
    required this.onGameSelected,
    this.title = 'ゲーム選択',
    this.allowNone = false,
  });

  static void show(
    BuildContext context, {
    Game? selectedGame,
    required Function(Game?) onGameSelected,
    String title = 'ゲーム選択',
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
  State<GameSelectionDialog> createState() => _GameSelectionDialogState();
}

class _GameSelectionDialogState extends State<GameSelectionDialog> {
  final _searchController = TextEditingController();
  List<Game> _filteredGames = [];
  Game? _selectedGame;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.selectedGame;
    _searchController.addListener(_onSearchChanged);
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
      setState(() {
        _errorMessage = 'ゲーム検索に失敗しました: $e';
        _filteredGames = [];
        _isLoading = false;
      });
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
            _buildSearchSection(),
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
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              widget.title,
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
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ゲーム名で検索...',
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
        ),
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: AppDimensions.fontSizeM,
        ),
      ),
    );
  }

  Widget _buildGameList() {
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: AppDimensions.iconXL,
              ),
              SizedBox(height: AppDimensions.spacingM),
              Text(
                'ゲーム名を入力して検索してください',
                style: TextStyle(
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingL),
          child: Text(
            'ゲームが見つかりませんでした',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeM,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      itemCount: _filteredGames.length,
      itemBuilder: (context, index) {
        final game = _filteredGames[index];
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
                child: const Text(
                  '未選択',
                  style: TextStyle(
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
                _selectedGame != null ? '選択' : 'ゲームを選んでください',
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
}