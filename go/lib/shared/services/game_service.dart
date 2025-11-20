import '../models/game.dart';
import 'itunes_search_service.dart';
import '../../data/repositories/shared_game_repository.dart';
import '../../data/models/shared_game_model.dart';

class GameService {
  static GameService? _instance;
  static GameService get instance => _instance ??= GameService._();

  GameService._();

  final ITunesSearchService _itunesService = ITunesSearchService();
  final SharedGameRepository _sharedGameRepository = SharedGameRepository();

  // ゲーム情報のメモリキャッシュ
  final Map<String, Game> _gameCache = <String, Game>{};

  /// ゲーム検索（共有キャッシュ優先）
  /// まずFirestoreの共有データを検索し、見つからない場合のみiTunes APIを使用
  Future<List<Game>> searchGames(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      print('🔍 GameService: Searching games for query: $query');

      // 検索語句が3文字以上の場合のみ、共有キャッシュから検索
      if (query.trim().length >= 3) {
        final cachedGames = await _searchFromCache(query);
        if (cachedGames.isNotEmpty) {
          print('✅ GameService: Found ${cachedGames.length} games from cache');
          return cachedGames.map((sharedGame) => sharedGame.game).toList();
        }
      } else {
        print('ℹ️ GameService: Query too short for cache search, using iTunes API directly');
      }

      // キャッシュに見つからない場合はiTunes APIを使用
      print('🔄 GameService: No cached results, searching iTunes API');
      final games = await _itunesService.searchGames(query);
      final limitedGames = games.take(50).toList();

      print('ℹ️ GameService: Found ${limitedGames.length} games from iTunes API');
      print('ℹ️ GameService: Games will be cached only when user selects them');

      return limitedGames;
    } catch (e) {
      print('❌ GameService: Error in searchGames: $e');
      throw Exception('ゲーム検索に失敗しました: $e');
    }
  }

  /// 特定のゲームを取得またはキャッシュ（お気に入り追加やイベント作成時に使用）
  /// キャッシュ済みのゲームIDを返す
  Future<String?> getOrCacheGame(Game game) async {
    try {
      print('🔍 GameService: Getting or caching game: ${game.name}');
      print('🔍 GameService: Game details - ID: ${game.id}, Developer: ${game.developer}');

      // 既存のキャッシュを確認
      print('🔍 GameService: Checking for existing cached game...');
      final existingGame = await _sharedGameRepository.findExistingGame(game.id);
      if (existingGame != null) {
        print('✅ GameService: Found existing cached game, incrementing usage');
        await _sharedGameRepository.incrementGameUsage(existingGame.documentId);
        return existingGame.game.id;
      }

      // 新しいゲームをキャッシュに保存
      print('💾 GameService: No existing cache found, saving new game to shared repository');
      print('💾 GameService: About to call saveNewGame with: ${game.toJson()}');
      final sharedGame = await _sharedGameRepository.saveNewGame(game);
      if (sharedGame != null) {
        print('✅ GameService: Successfully cached new game with documentId: ${sharedGame.documentId}');
        return sharedGame.game.id;
      }

      print('❌ GameService: Failed to cache game - saveNewGame returned null');
      return null;
    } catch (e, stackTrace) {
      print('❌ GameService: Error in getOrCacheGame: $e');
      print('❌ GameService: Stack trace: $stackTrace');
      return null;
    }
  }

  /// 人気のゲーム一覧を取得（共有キャッシュから）
  Future<List<Game>> getPopularGames({int limit = 10}) async {
    try {
      final sharedGames = await _sharedGameRepository.getPopularGames(limit: limit);
      return sharedGames.map((sharedGame) => sharedGame.game).toList();
    } catch (e) {
      print('❌ GameService: Error getting popular games: $e');
      return [];
    }
  }

  /// 最近使用されたゲーム一覧を取得（共有キャッシュから）
  Future<List<Game>> getRecentGames({int limit = 10}) async {
    try {
      final sharedGames = await _sharedGameRepository.getRecentGames(limit: limit);
      return sharedGames.map((sharedGame) => sharedGame.game).toList();
    } catch (e) {
      print('❌ GameService: Error getting recent games: $e');
      return [];
    }
  }

  /// キャッシュから検索する内部メソッド
  Future<List<SharedGameData>> _searchFromCache(String query) async {
    try {
      final searchQuery = GameSearchQuery(name: query);
      return await _sharedGameRepository.searchGames(searchQuery);
    } catch (e) {
      print('❌ GameService: Error searching cache: $e');
      return [];
    }
  }


  /// 単一のゲームIDからゲーム情報を取得（キャッシュ付き）
  /// GameProfileでの表示などで使用
  Future<Game?> getGameById(String gameId) async {
    if (gameId.isEmpty) {
      return null;
    }

    try {
      // まずメモリキャッシュを確認
      if (_gameCache.containsKey(gameId)) {
        print('✅ GameService: Found game in memory cache: ${_gameCache[gameId]!.name}');
        return _gameCache[gameId];
      }

      print('🔍 GameService: Getting game by ID: $gameId');

      final sharedGame = await _sharedGameRepository.findExistingGame(gameId);
      if (sharedGame != null) {
        // メモリキャッシュに保存
        _gameCache[gameId] = sharedGame.game;
        print('✅ GameService: Found game and cached: ${sharedGame.game.name}');
        return sharedGame.game;
      } else {
        print('⚠️ GameService: Game not found in shared repository: $gameId');
        return null;
      }
    } catch (e) {
      print('❌ GameService: Error getting game by ID $gameId: $e');
      return null;
    }
  }

  /// ゲームIDリストから実際のゲーム情報を取得
  /// お気に入りゲーム表示などで使用
  Future<List<Game>> getGamesByIds(List<String> gameIds) async {
    if (gameIds.isEmpty) {
      return [];
    }

    try {
      print('🔍 GameService: Getting games by IDs: ${gameIds.length} games');

      final games = <Game>[];
      for (final gameId in gameIds) {
        final game = await getGameById(gameId);
        if (game != null) {
          games.add(game);
        }
      }

      print('✅ GameService: Retrieved ${games.length}/${gameIds.length} games');
      return games;
    } catch (e) {
      print('❌ GameService: Error in getGamesByIds: $e');
      return [];
    }
  }

  /// 古いキャッシュをクリーンアップ
  Future<void> cleanupCache() async {
    try {
      await _sharedGameRepository.cleanupOldCache();
    } catch (e) {
      print('❌ GameService: Error cleaning up cache: $e');
    }
  }

  /// メモリキャッシュをクリア
  void clearMemoryCache() {
    _gameCache.clear();
    print('🔄 GameService: Memory cache cleared');
  }

  /// キャッシュサイズを取得
  int get cacheSize => _gameCache.length;

  void dispose() {
    _itunesService.dispose();
    clearMemoryCache();
  }
}