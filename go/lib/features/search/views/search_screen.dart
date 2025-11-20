import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/empty_search_result.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../features/game_event_management/models/game_event.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/models/game.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/utils/event_converter.dart';

class SearchScreen extends StatefulWidget {
  final bool shouldFocusSearchField;

  const SearchScreen({super.key, this.shouldFocusSearchField = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _userRepository = UserRepository();
  String _selectedSearchType = 'イベント';

  // ユーザー検索関連の状態
  List<UserData> _userSearchResults = [];
  bool _isSearching = false;
  String? _searchErrorMessage;

  // ゲーム検索関連の状態
  List<Game> _gameSearchResults = [];
  Game? _selectedGame;
  List<GameEvent> _relatedEvents = [];
  bool _isSearchingGames = false;
  bool _isLoadingEvents = false;
  String? _gameSearchErrorMessage;

  // イベント検索関連の状態
  List<GameEvent> _eventSearchResults = [];
  bool _isSearchingEvents = false;
  String? _eventSearchErrorMessage;

  final List<String> _searchTypes = [
    'イベント',
    'ユーザー',
    'ゲーム名',
  ];

  @override
  void initState() {
    super.initState();
    // ホーム画面からの遷移時にフォーカスを当てる
    if (widget.shouldFocusSearchField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// ユーザー検索を実行
  Future<void> _performUserSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _userSearchResults = [];
        _searchErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });

    try {
      print('🔍 SearchScreen: Searching for users with query: "$query"');
      final results = await _userRepository.searchUsers(query, limit: 20);

      setState(() {
        _userSearchResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _searchErrorMessage = 'ユーザーが見つかりませんでした';
        }
      });

      print('✅ SearchScreen: Found ${results.length} users');
    } catch (e) {
      print('❌ SearchScreen: Error searching users: $e');
      setState(() {
        _isSearching = false;
        _searchErrorMessage = 'ユーザー検索中にエラーが発生しました';
        _userSearchResults = [];
      });
    }
  }

  /// ゲーム検索を実行
  Future<void> _performGameSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _gameSearchResults = [];
        _selectedGame = null;
        _relatedEvents = [];
        _gameSearchErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearchingGames = true;
      _gameSearchErrorMessage = null;
    });

    try {
      print('🎮 SearchScreen: Searching for games with query: "$query"');
      final results = await GameService.instance.searchGames(query);

      setState(() {
        _gameSearchResults = results;
        _isSearchingGames = false;
        _selectedGame = null;
        _relatedEvents = [];
        if (results.isEmpty) {
          _gameSearchErrorMessage = 'ゲームが見つかりませんでした';
        }
      });

      print('✅ SearchScreen: Found ${results.length} games');
    } catch (e) {
      print('❌ SearchScreen: Error searching games: $e');
      setState(() {
        _isSearchingGames = false;
        _gameSearchErrorMessage = 'ゲーム検索中にエラーが発生しました';
        _gameSearchResults = [];
      });
    }
  }

  /// 選択されたゲームの関連イベントを取得
  Future<void> _loadRelatedEvents(Game game) async {
    setState(() {
      _selectedGame = game;
      _isLoadingEvents = true;
      _relatedEvents = [];
    });

    try {
      print('🎮 SearchScreen: Loading events for game: ${game.name}');
      final events = await EventService.getEventsByGameId(game.id);
      final gameEvents = await EventConverter.eventsToGameEvents(events);

      setState(() {
        _relatedEvents = gameEvents;
        _isLoadingEvents = false;
      });

      print('✅ SearchScreen: Found ${events.length} related events');
    } catch (e) {
      print('❌ SearchScreen: Error loading related events: $e');
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  /// イベント検索を実行
  Future<void> _performEventSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _eventSearchResults = [];
        _eventSearchErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearchingEvents = true;
      _eventSearchErrorMessage = null;
    });

    try {
      print('🎪 SearchScreen: Searching for events with query: "$query"');
      final events = await EventService.searchEvents(keyword: query);
      final gameEvents = await EventConverter.eventsToGameEvents(events);

      setState(() {
        _eventSearchResults = gameEvents;
        _isSearchingEvents = false;
        if (gameEvents.isEmpty) {
          _eventSearchErrorMessage = 'イベントが見つかりませんでした';
        }
      });

      print('✅ SearchScreen: Found ${gameEvents.length} events');
    } catch (e) {
      print('❌ SearchScreen: Error searching events: $e');
      setState(() {
        _isSearchingEvents = false;
        _eventSearchErrorMessage = 'イベント検索中にエラーが発生しました';
        _eventSearchResults = [];
      });
    }
  }

  /// 検索を実行する
  void _performSearch() {
    switch (_selectedSearchType) {
      case 'ユーザー':
        _performUserSearch();
        break;
      case 'ゲーム名':
        _performGameSearch();
        break;
      case 'イベント':
        _performEventSearch();
        break;
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
                title: AppStrings.searchTab,
                showBackButton: false,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                      Expanded(
                        child: _buildSearchResults(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
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
                Icons.search,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '検索',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // 検索対象セレクター
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.textSecondary,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '検索対象:',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _searchTypes.map((type) {
                      final isSelected = _selectedSearchType == type;
                      return Container(
                        margin: const EdgeInsets.only(right: AppDimensions.spacingS),
                        child: FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSearchType = type;
                              // 検索タイプが変更されたら結果をリセット
                              _userSearchResults = [];
                              _searchErrorMessage = null;
                              _gameSearchResults = [];
                              _selectedGame = null;
                              _relatedEvents = [];
                              _gameSearchErrorMessage = null;
                              _isLoadingEvents = false;
                              _eventSearchResults = [];
                              _eventSearchErrorMessage = null;
                              _isSearchingEvents = false;
                              // 既に入力されているテキストで検索を実行
                              if (_searchController.text.isNotEmpty) {
                                _performSearch();
                              }
                            });
                          },
                          backgroundColor: AppColors.backgroundLight,
                          selectedColor: AppColors.accent.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.accent : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: AppDimensions.fontSizeS,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : AppColors.border,
                            width: 1,
                          ),
                          elevation: 0,
                          pressElevation: 2,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: '${_selectedSearchType}を検索...',
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
                          // 検索フィールドがクリアされたら結果もリセット
                          _userSearchResults = [];
                          _searchErrorMessage = null;
                          _gameSearchResults = [];
                          _selectedGame = null;
                          _relatedEvents = [];
                          _gameSearchErrorMessage = null;
                          _isLoadingEvents = false;
                          _eventSearchResults = [];
                          _eventSearchErrorMessage = null;
                          _isSearchingEvents = false;
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
        ],
      ),
    );
  }


  Widget _buildSearchResults() {
    switch (_selectedSearchType) {
      case 'ユーザー':
        return _buildUserSearchResults();
      case 'ゲーム名':
        return _buildGameSearchResults();
      case 'イベント':
        return _buildEventSearchResults();
      default:
        return _buildDefaultSearchResults();
    }
  }

  /// ユーザー検索結果を表示
  Widget _buildUserSearchResults() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'ユーザー検索結果',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  SizedBox(
                    width: AppDimensions.iconS,
                    height: AppDimensions.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildUserSearchContent(),
          ),
        ],
      ),
    );
  }

  /// ユーザー検索のコンテンツを表示
  Widget _buildUserSearchContent() {
    if (_searchController.text.isEmpty) {
      return _buildEmptySearchState();
    }

    if (_isSearching) {
      return _buildLoadingState();
    }

    if (_searchErrorMessage != null) {
      return _buildErrorState();
    }

    if (_userSearchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return _buildUserList();
  }

  /// 空の検索状態
  Widget _buildEmptySearchState() {
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
            Text(
              'ユーザー名またはIDで検索',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'ユーザー名またはユーザーIDで他のユーザーを検索できます',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  /// ローディング状態
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
            Text(
              'ユーザーを検索中...',
              style: const TextStyle(
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

  /// エラー状態
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'エラーが発生しました',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _searchErrorMessage!,
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

  /// 検索結果がない状態
  Widget _buildNoResultsState() {
    return EmptySearchResult.user(_searchController.text);
  }

  /// ユーザー一覧を表示
  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        bottom: AppDimensions.spacingL,
      ),
      itemCount: _userSearchResults.length,
      itemBuilder: (context, index) {
        final user = _userSearchResults[index];
        return _buildUserTile(user);
      },
    );
  }

  /// ユーザータイルを表示
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
            Navigator.of(context).pushNamed(
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
                Icon(
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

  /// ゲーム検索結果を表示
  Widget _buildGameSearchResults() {
    // ゲームが選択されている場合は関連イベントのみを表示
    if (_selectedGame != null) {
      return _buildSelectedGameView();
    }

    // ゲームが選択されていない場合はゲーム検索結果を表示
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.games,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'ゲーム検索結果',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isSearchingGames) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  SizedBox(
                    width: AppDimensions.iconS,
                    height: AppDimensions.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildGameSearchContent(),
          ),
        ],
      ),
    );
  }

  /// 選択されたゲームと関連イベントを表示するビュー
  Widget _buildSelectedGameView() {
    return Column(
      children: [
        // 選択されたゲーム情報（コンパクト表示）
        Container(
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
          child: Row(
            children: [
              // 戻るボタン
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _resetGameSelection,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingS),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.accent,
                      size: AppDimensions.iconM,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              // ゲーム情報
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: _selectedGame!.iconUrl != null
                    ? Image.network(
                        _selectedGame!.iconUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCompactGameIcon();
                        },
                      )
                    : _buildCompactGameIcon(),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedGame!.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedGame!.developer != null) ...[
                      const SizedBox(height: AppDimensions.spacingXS / 2),
                      Text(
                        _selectedGame!.developer!,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: AppDimensions.iconM,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // 関連イベント（フルスクリーン表示）
        Expanded(
          child: _buildRelatedEventsSection(),
        ),
      ],
    );
  }

  /// コンパクトなゲームアイコンを作成
  Widget _buildCompactGameIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        Icons.videogame_asset,
        color: AppColors.textSecondary,
        size: AppDimensions.iconS,
      ),
    );
  }

  /// ゲーム選択をリセット
  void _resetGameSelection() {
    setState(() {
      _selectedGame = null;
      _relatedEvents = [];
    });
  }

  /// ゲーム検索のコンテンツを表示
  Widget _buildGameSearchContent() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyGameSearchState();
    }

    if (_isSearchingGames) {
      return _buildGameLoadingState();
    }

    if (_gameSearchErrorMessage != null) {
      return _buildGameErrorState();
    }

    if (_gameSearchResults.isEmpty) {
      return _buildNoGameResultsState();
    }

    return _buildGameList();
  }

  /// 空のゲーム検索状態
  Widget _buildEmptyGameSearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videogame_asset_off,
              size: AppDimensions.iconXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'ゲーム名で検索',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'ゲーム名を入力してゲームを検索し、\n関連するイベントを確認できます',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  /// ゲームローディング状態
  Widget _buildGameLoadingState() {
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
            Text(
              'ゲームを検索中...',
              style: const TextStyle(
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

  /// ゲーム検索エラー状態
  Widget _buildGameErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'エラーが発生しました',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _gameSearchErrorMessage!,
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

  /// ゲーム検索結果がない状態
  Widget _buildNoGameResultsState() {
    return EmptySearchResult.game(_searchController.text);
  }

  /// ゲーム一覧を表示
  Widget _buildGameList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        bottom: AppDimensions.spacingL,
      ),
      itemCount: _gameSearchResults.length,
      itemBuilder: (context, index) {
        final game = _gameSearchResults[index];
        return _buildGameTile(game);
      },
    );
  }

  /// ゲームタイルを表示
  Widget _buildGameTile(Game game) {
    final isSelected = _selectedGame?.id == game.id;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: () => _loadRelatedEvents(game),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: game.iconUrl != null
                      ? Image.network(
                          game.iconUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildGameIcon();
                          },
                        )
                      : _buildGameIcon(),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game.name,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.accent : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      if (game.developer != null) ...[
                        Text(
                          game.developer!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                      ],
                      Text(
                        game.platforms.take(3).join(' • '),
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: AppDimensions.iconS,
                  color: isSelected ? AppColors.accent : AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Icon(
        Icons.videogame_asset,
        color: AppColors.textSecondary,
        size: AppDimensions.iconM,
      ),
    );
  }

  /// 関連イベントセクションを表示
  Widget _buildRelatedEventsSection() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    '${_selectedGame?.name ?? ""}の関連イベント',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoadingEvents) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  SizedBox(
                    width: AppDimensions.iconS,
                    height: AppDimensions.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildRelatedEventsContent(),
          ),
        ],
      ),
    );
  }

  /// 関連イベントのコンテンツを表示
  Widget _buildRelatedEventsContent() {
    if (_isLoadingEvents) {
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
              Text(
                'イベントを読み込み中...',
                style: const TextStyle(
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

    if (_relatedEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: AppDimensions.iconXXL,
                color: AppColors.overlayMedium,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text(
                '関連イベントはありません',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                'このゲームに関連する公開イベント\nが見つかりませんでした',
                textAlign: TextAlign.center,
                style: const TextStyle(
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

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        bottom: AppDimensions.spacingL,
      ),
      itemCount: _relatedEvents.length,
      itemBuilder: (context, index) {
        final event = _relatedEvents[index];
        return Padding(
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
        );
      },
    );
  }

  /// イベント検索結果を表示
  Widget _buildEventSearchResults() {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'イベント検索結果',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                if (_isSearchingEvents) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  SizedBox(
                    width: AppDimensions.iconS,
                    height: AppDimensions.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildEventSearchContent(),
          ),
        ],
      ),
    );
  }

  /// イベント検索のコンテンツを表示
  Widget _buildEventSearchContent() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyEventSearchState();
    }

    if (_isSearchingEvents) {
      return _buildEventLoadingState();
    }

    if (_eventSearchErrorMessage != null) {
      return _buildEventErrorState();
    }

    if (_eventSearchResults.isEmpty) {
      return _buildNoEventResultsState();
    }

    return _buildEventList();
  }

  /// 空のイベント検索状態
  Widget _buildEmptyEventSearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: AppDimensions.iconXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'イベント名で検索',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'イベント名やキーワードを入力して\nパブリックイベントを検索できます',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  /// イベント検索ローディング状態
  Widget _buildEventLoadingState() {
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
            Text(
              'イベントを検索中...',
              style: const TextStyle(
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

  /// イベント検索エラー状態
  Widget _buildEventErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'エラーが発生しました',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              _eventSearchErrorMessage!,
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

  /// イベント検索結果がない状態
  Widget _buildNoEventResultsState() {
    return EmptySearchResult.event(_searchController.text);
  }

  /// イベント一覧を表示
  Widget _buildEventList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppDimensions.spacingL,
        right: AppDimensions.spacingL,
        bottom: AppDimensions.spacingL,
      ),
      itemCount: _eventSearchResults.length,
      itemBuilder: (context, index) {
        final event = _eventSearchResults[index];
        return Padding(
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
        );
      },
    );
  }

  /// デフォルトの検索結果表示
  Widget _buildDefaultSearchResults() {
    return Container(
      width: double.infinity,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty
                ? Icons.search_off
                : Icons.search,
            size: AppDimensions.iconXXL,
            color: AppColors.overlayMedium,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            _searchController.text.isEmpty
                ? '検索ワードを入力してください'
                : '検索結果',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            _searchController.text.isEmpty
                ? '$_selectedSearchType名で検索できます'
                : '「${_searchController.text}」で$_selectedSearchTypeを検索しています\n\n実装時にはここに検索結果が表示されます',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}