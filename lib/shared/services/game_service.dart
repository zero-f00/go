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

      // 検索語句が3文字以上の場合のみ、共有キャッシュから検索
      if (query.trim().length >= 3) {
        final cachedGames = await _searchFromCache(query);
        if (cachedGames.isNotEmpty) {
          return cachedGames.map((sharedGame) => sharedGame.game).toList();
        }
      } else {
      }

      // キャッシュに見つからない場合はiTunes APIを使用
      final games = await _itunesService.searchGames(query);
      final limitedGames = games.take(50).toList();


      return limitedGames;
    } catch (e) {
      throw Exception('ゲーム検索に失敗しました: $e');
    }
  }

  /// 特定のゲームを取得またはキャッシュ（お気に入り追加やイベント作成時に使用）
  /// キャッシュ済みのゲームIDを返す
  Future<String?> getOrCacheGame(Game game) async {
    try {

      // 既存のキャッシュを確認
      final existingGame = await _sharedGameRepository.findExistingGame(game.id);
      if (existingGame != null) {
        await _sharedGameRepository.incrementGameUsage(existingGame.documentId);
        return existingGame.game.id;
      }

      // 新しいゲームをキャッシュに保存
      final sharedGame = await _sharedGameRepository.saveNewGame(game);
      if (sharedGame != null) {
        return sharedGame.game.id;
      }

      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// 人気のゲーム一覧を取得（共有キャッシュから）
  Future<List<Game>> getPopularGames({int limit = 10}) async {
    try {
      final sharedGames = await _sharedGameRepository.getPopularGames(limit: limit);
      return sharedGames.map((sharedGame) => sharedGame.game).toList();
    } catch (e) {
      return [];
    }
  }

  /// 最近使用されたゲーム一覧を取得（共有キャッシュから）
  Future<List<Game>> getRecentGames({int limit = 10}) async {
    try {
      final sharedGames = await _sharedGameRepository.getRecentGames(limit: limit);
      return sharedGames.map((sharedGame) => sharedGame.game).toList();
    } catch (e) {
      return [];
    }
  }

  /// お気に入りゲームのIDリストからGameオブジェクトのリストを取得
  Future<List<Game>> getFavoriteGames(List<String> favoriteGameIds) async {
    if (favoriteGameIds.isEmpty) {
      return [];
    }

    final List<Game> favoriteGames = [];

    try {
      // 各ゲームIDに対してゲーム情報を取得
      for (final gameId in favoriteGameIds) {
        final sharedGame = await _sharedGameRepository.findExistingGame(gameId);
        if (sharedGame != null) {
          favoriteGames.add(sharedGame.game);
        }
      }

      return favoriteGames;
    } catch (e) {
      return favoriteGames; // 部分的に取得できたゲームがあれば返す
    }
  }

  /// キャッシュから検索する内部メソッド
  Future<List<SharedGameData>> _searchFromCache(String query) async {
    try {
      final searchQuery = GameSearchQuery(name: query);
      return await _sharedGameRepository.searchGames(searchQuery);
    } catch (e) {
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
        return _gameCache[gameId];
      }


      final sharedGame = await _sharedGameRepository.findExistingGame(gameId);
      if (sharedGame != null) {
        // メモリキャッシュに保存
        _gameCache[gameId] = sharedGame.game;
        return sharedGame.game;
      } else {
        return null;
      }
    } catch (e) {
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

      final games = <Game>[];
      for (final gameId in gameIds) {
        final game = await getGameById(gameId);
        if (game != null) {
          games.add(game);
        }
      }

      return games;
    } catch (e) {
      return [];
    }
  }

  /// 古いキャッシュをクリーンアップ
  Future<void> cleanupCache() async {
    try {
      await _sharedGameRepository.cleanupOldCache();
    } catch (e) {
    }
  }

  /// メモリキャッシュをクリア
  void clearMemoryCache() {
    _gameCache.clear();
  }

  /// キャッシュサイズを取得
  int get cacheSize => _gameCache.length;

  void dispose() {
    _itunesService.dispose();
    clearMemoryCache();
  }
}