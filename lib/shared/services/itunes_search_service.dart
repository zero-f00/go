import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/itunes_app.dart';
import '../models/game.dart';

class ITunesSearchService {
  static const String _baseUrl = 'https://itunes.apple.com/search';
  static const String _country = 'jp';
  static const int _defaultLimit = 50;
  static const int _maxLimit = 200;

  final http.Client _client;

  ITunesSearchService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Game>> searchGames(String query, {int? limit}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final apps = await _searchApps(
        term: query,
        limit: limit ?? _defaultLimit,
      );

      final games = apps
          .where((app) => _isGameApp(app))
          .map((app) => app.toGame())
          .toList();

      return games;
    } catch (e) {
      throw ITunesSearchException('ゲーム検索に失敗しました: $e');
    }
  }

  // searchPopularGamesメソッドを削除 - API無駄遣い防止のため使用しない

  Future<List<ITunesApp>> _searchApps({
    required String term,
    int limit = _defaultLimit,
  }) async {
    final queryParams = {
      'term': Uri.encodeComponent(term),
      'media': 'software',
      'entity': 'software',
      'country': _country,
      'limit': (limit > _maxLimit ? _maxLimit : limit).toString(),
    };

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: queryParams,
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'Game-Event-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] as List<dynamic>;

        return results
            .map((item) => ITunesApp.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ITunesSearchException(
          'APIエラー: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      throw ITunesSearchException('インターネット接続を確認してください: $e');
    } on FormatException catch (e) {
      throw ITunesSearchException('レスポンスの形式が正しくありません: $e');
    } catch (e) {
      if (e is ITunesSearchException) rethrow;
      throw ITunesSearchException('リクエストが失敗しました: $e');
    }
  }

  bool _isGameApp(ITunesApp app) {
    final gameGenres = [
      'Games',
      'Action',
      'Adventure',
      'Arcade',
      'Board',
      'Card',
      'Casino',
      'Puzzle',
      'Racing',
      'Role Playing',
      'Simulation',
      'Sports',
      'Strategy',
      'Trivia',
      'Word',
    ];

    final primaryGenreLower = app.primaryGenreName.toLowerCase();

    // まず主要ジャンルをチェック（最も信頼できる）
    final isGameByGenre = gameGenres.any((genre) =>
        genre.toLowerCase() == primaryGenreLower);

    if (isGameByGenre) {
      return true;
    }

    // 非ゲームジャンルを除外
    final nonGameGenres = [
      'social networking',
      'productivity',
      'utilities',
      'photo & video',
      'finance',
      'health & fitness',
      'travel',
      'food & drink',
      'music',
      'education', // 教育アプリも除外
      'news',
      'business',
      'lifestyle',
      'weather',
      'reference',
      'medical',
      'shopping',
      'navigation',
    ];

    if (nonGameGenres.contains(primaryGenreLower)) {
      return false;
    }

    // エンターテインメントジャンルの場合は、タイトルでより厳密にチェック
    if (primaryGenreLower == 'entertainment') {
      final trackNameLower = app.trackName.toLowerCase();
      final gameKeywords = ['game', 'puzzle', 'racing', 'rpg', 'action'];

      final hasGameKeyword = gameKeywords.any((keyword) =>
          trackNameLower.contains(keyword));

      if (hasGameKeyword) {
        return true;
      }
    }

    return false;
  }

  void dispose() {
    _client.close();
  }
}

class ITunesSearchException implements Exception {
  final String message;

  const ITunesSearchException(this.message);

  @override
  String toString() => 'ITunesSearchException: $message';
}