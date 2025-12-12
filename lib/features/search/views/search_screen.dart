import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/empty_search_result.dart';
import '../../../data/models/user_model.dart';
import '../../../features/game_event_management/models/game_event.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/models/game.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/utils/event_converter.dart';
import '../../../shared/services/event_filter_service.dart';
import '../../../shared/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool shouldFocusSearchField;

  const SearchScreen({super.key, this.shouldFocusSearchField = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  // お気に入りゲーム関連の状態
  List<Game> _favoriteGames = [];
  bool _isFavoriteGamesLoading = false;
  Game? _selectedFavoriteGame;

  // UI状態
  bool _isSearchFieldFocused = false;

  final List<String> _searchTypes = [
    'イベント',
    'ユーザー',
    'ゲーム名',
  ];

  // 前回のお気に入りゲームIDリスト（変更検出用）
  List<String> _lastFavoriteGameIds = [];

  // 認証状態が確定してデータを読み込んだかどうか
  bool _hasInitialDataLoaded = false;

  @override
  void initState() {
    super.initState();

    // フォーカス状態のリスナーを追加
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // ホーム画面からの遷移時にフォーカスを当てる
    if (widget.shouldFocusSearchField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }

    // 認証状態が確定するまでお気に入りゲームの読み込みを待機
    // buildメソッド内のref.listenで認証状態を監視してデータを読み込む
  }

  /// お気に入りゲームを読み込み
  Future<void> _loadFavoriteGames() async {
    setState(() {
      _isFavoriteGamesLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);

      User? user;
      authState.when(
        data: (data) => user = data,
        loading: () => user = null,
        error: (_, __) => user = null,
      );

      if (user == null) {
        setState(() {
          _favoriteGames = [];
          _isFavoriteGamesLoading = false;
        });
        return;
      }

      final userRepository = UserRepository();
      final userData = await userRepository.getUserById(user!.uid);

      if (userData?.favoriteGameIds.isNotEmpty == true) {
        final favoriteGames = await GameService.instance.getFavoriteGames(userData!.favoriteGameIds);
        setState(() {
          _favoriteGames = favoriteGames;
          _lastFavoriteGameIds = List.from(userData.favoriteGameIds);
        });
      } else {
        setState(() {
          _favoriteGames = [];
          _lastFavoriteGameIds = [];
        });
      }
    } catch (e) {
      setState(() {
        _favoriteGames = [];
      });
    } finally {
      setState(() {
        _isFavoriteGamesLoading = false;
      });
    }
  }

  /// 2つのリストが等しいかどうかを比較
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onSearchFocusChanged() {
    // キーボードのアニメーションとタイミングを合わせるため少し遅延を追加
    if (!_searchFocusNode.hasFocus) {
      // フォーカスが外れた場合は少し遅延を入れる
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          setState(() {
            _isSearchFieldFocused = false;
          });
        }
      });
    } else {
      // フォーカスが当たった場合は即座に反映
      setState(() {
        _isSearchFieldFocused = true;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
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
      final results = await _userRepository.searchUsers(query, limit: 20);

      setState(() {
        _userSearchResults = results;
        _isSearching = false;
        _searchErrorMessage = null; // エラーメッセージをクリア
      });

    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchErrorMessage = 'ユーザー検索中にエラーが発生しました: ${e.toString()}';
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
      final results = await GameService.instance.searchGames(query);

      setState(() {
        _gameSearchResults = results;
        _isSearchingGames = false;
        _selectedGame = null;
        _relatedEvents = [];
        _gameSearchErrorMessage = null; // エラーメッセージをクリア
      });

    } catch (e) {
      setState(() {
        _isSearchingGames = false;
        _gameSearchErrorMessage = 'ゲーム検索中にエラーが発生しました: ${e.toString()}';
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
      final events = await EventService.getEventsByGameId(game.id);
      final gameEvents = await EventConverter.eventsToGameEvents(events);

      // NGユーザーのイベントを除外
      final currentUser = FirebaseAuth.instance.currentUser;
      final filteredEvents = EventFilterService.filterBlockedUserEvents(gameEvents, currentUser?.uid);

      setState(() {
        _relatedEvents = filteredEvents;
        _isLoadingEvents = false;
      });

    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  /// お気に入りゲームを選択して関連イベントを取得
  Future<void> _selectFavoriteGame(Game game) async {
    setState(() {
      _selectedFavoriteGame = game;
      _isLoadingEvents = true;
      _relatedEvents = [];
    });

    try {
      final events = await EventService.getEventsByGameId(game.id);
      final gameEvents = await EventConverter.eventsToGameEvents(events);

      // NGユーザーのイベントを除外
      final currentUser = FirebaseAuth.instance.currentUser;
      final filteredEvents = EventFilterService.filterBlockedUserEvents(gameEvents, currentUser?.uid);

      setState(() {
        _relatedEvents = filteredEvents;
        _isLoadingEvents = false;
      });

    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  /// お気に入りゲーム選択をリセット
  void _resetFavoriteGameSelection() {
    setState(() {
      _selectedFavoriteGame = null;
      _relatedEvents = [];
    });
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
      final events = await EventService.searchEvents(keyword: query);
      final gameEvents = await EventConverter.eventsToGameEvents(events);

      // NGユーザーのイベントを除外
      final currentUser = FirebaseAuth.instance.currentUser;
      final filteredEvents = EventFilterService.filterBlockedUserEvents(gameEvents, currentUser?.uid);

      setState(() {
        _eventSearchResults = filteredEvents;
        _isSearchingEvents = false;
        _eventSearchErrorMessage = null; // エラーメッセージをクリア
      });

    } catch (e) {
      setState(() {
        _isSearchingEvents = false;
        _eventSearchErrorMessage = 'イベント検索でエラーが発生しました: ${e.toString()}';
        _eventSearchResults = [];
      });
    }
  }

  /// 検索を実行する
  void _performSearch() {
    // Firebase Firestore接続状態の確認
    FirebaseFirestore.instance.settings.persistenceEnabled;

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
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ユーザーデータの変更を監視してお気に入りゲームを再読み込み
    ref.listen<AsyncValue<UserData?>>(currentUserDataProvider, (previous, next) {
      next.whenData((userData) {
        if (userData != null) {
          // 初回読み込み（認証状態が確定した時）
          if (!_hasInitialDataLoaded) {
            _hasInitialDataLoaded = true;
            _loadFavoriteGames();
            return;
          }
          // お気に入りゲームIDが変更された場合のみ再読み込み
          final currentFavoriteIds = userData.favoriteGameIds;
          if (!_listEquals(currentFavoriteIds, _lastFavoriteGameIds)) {
            _lastFavoriteGameIds = List.from(currentFavoriteIds);
            _loadFavoriteGames();
          }
        } else {
          // ログアウト時はフラグをリセット
          _hasInitialDataLoaded = false;
          setState(() {
            _favoriteGames = [];
            _lastFavoriteGameIds = [];
          });
        }
      });
    });

    // 初回ビルド時に既にログイン状態であればデータを読み込む
    final currentUserAsync = ref.read(currentUserDataProvider);
    if (!_hasInitialDataLoaded && currentUserAsync.hasValue && currentUserAsync.value != null) {
      _hasInitialDataLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFavoriteGames();
        }
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      resizeToAvoidBottomInset: true,
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: AppStrings.searchTab,
                showBackButton: false,
                showUserIcon: true,
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    children: [
                      _buildSearchSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isSearchFieldFocused
                            ? SizedBox(
                                key: const ValueKey('focused'),
                                child: _buildFocusedStateHint(),
                              )
                            : SizedBox(
                                key: const ValueKey('unfocused'),
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: _buildSearchResults(),
                              ),
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
                              _selectedFavoriteGame = null;
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
              hintText: '$_selectedSearchTypeを検索...',
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
          // お気に入りゲームフィルター（イベント検索時のみ表示）
          if (_selectedSearchType == 'イベント') ...[
            const SizedBox(height: AppDimensions.spacingM),
            _buildFavoriteGamesFilter(),
          ],
        ],
      ),
    );
  }

  /// お気に入りゲームフィルターを構築
  Widget _buildFavoriteGamesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              color: AppColors.primary,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            const Text(
              'お気に入りゲームで絞り込み',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        if (_isFavoriteGamesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.spacingS),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          )
        else if (_favoriteGames.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textLight,
                  size: AppDimensions.iconS,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Expanded(
                  child: Text(
                    'お気に入りゲームを登録するとここに表示されます',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteGames.length,
              itemBuilder: (context, index) {
                final game = _favoriteGames[index];
                final isSelected = _selectedFavoriteGame?.id == game.id;
                return _buildFavoriteGameChip(game, isSelected);
              },
            ),
          ),
      ],
    );
  }

  /// お気に入りゲームチップを構築
  Widget _buildFavoriteGameChip(Game game, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isSelected) {
              _resetFavoriteGameSelection();
            } else {
              _selectFavoriteGame(game);
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (game.iconUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                    child: Image.network(
                      game.iconUrl!,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.overlayLight,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                          ),
                          child: Icon(
                            Icons.videogame_asset,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            size: 14,
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.overlayLight,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: 14,
                    ),
                  ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  game.name,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppDimensions.spacingXS),
                  Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSearchResults() {
    // お気に入りゲームが選択されている場合は関連イベントを表示
    if (_selectedSearchType == 'イベント' && _selectedFavoriteGame != null) {
      return _buildFavoriteGameEventsView();
    }

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

  /// お気に入りゲームの関連イベント表示
  Widget _buildFavoriteGameEventsView() {
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
                  onTap: _resetFavoriteGameSelection,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingS),
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: AppDimensions.iconM,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              // ゲーム情報
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: _selectedFavoriteGame!.iconUrl != null
                    ? Image.network(
                        _selectedFavoriteGame!.iconUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildCompactFavoriteGameIcon();
                        },
                      )
                    : _buildCompactFavoriteGameIcon(),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFavoriteGame!.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_selectedFavoriteGame!.developer.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingXS / 2),
                      Text(
                        _selectedFavoriteGame!.developer,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'お気に入り',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeXS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // 関連イベント
        Expanded(
          child: _buildFavoriteGameRelatedEventsSection(),
        ),
      ],
    );
  }

  /// コンパクトなお気に入りゲームアイコン
  Widget _buildCompactFavoriteGameIcon() {
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

  /// お気に入りゲームの関連イベントセクション
  Widget _buildFavoriteGameRelatedEventsSection() {
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
                  color: AppColors.primary,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    '${_selectedFavoriteGame?.name ?? ""}の関連イベント',
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildFavoriteGameRelatedEventsContent(),
          ),
        ],
      ),
    );
  }

  /// お気に入りゲームの関連イベントコンテンツ
  Widget _buildFavoriteGameRelatedEventsContent() {
    if (_isLoadingEvents) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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

  Widget _buildFocusedStateHint() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard,
            size: AppDimensions.iconL,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'キーワードを入力して検索',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'Enterキーを押すか、検索ボタンをタップして検索してください',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}