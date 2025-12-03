import 'package:equatable/equatable.dart';
import '../../shared/models/game.dart';

/// 共有ゲームデータモデル
/// iTunes APIから取得したゲーム情報をFirestoreで共有するためのモデル
/// キャッシュメタデータを含み、全ユーザー間でゲーム情報を効率的に共有
class SharedGameData extends Equatable {
  final Game game;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int usageCount;
  final String sourceType; // 'itunes' or 'manual'
  final String documentId; // Firestoreドキュメントの一意ID

  const SharedGameData({
    required this.game,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.usageCount,
    required this.sourceType,
    required this.documentId,
  });

  /// JSONから SharedGameData を作成
  factory SharedGameData.fromJson(Map<String, dynamic> json, String docId) {
    return SharedGameData(
      game: Game.fromJson(json['game'] as Map<String, dynamic>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt'] as int),
      usageCount: json['usageCount'] as int,
      sourceType: json['sourceType'] as String,
      documentId: docId,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'game': game.toJson(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'usageCount': usageCount,
      'sourceType': sourceType,
      'version': 1, // データスキーマバージョン管理用
    };
  }

  /// iTunes APIから新しいSharedGameDataを作成
  factory SharedGameData.fromItunesGame(Game game) {
    final now = DateTime.now();
    final documentId = _generateDocumentId(game);

    return SharedGameData(
      game: game,
      createdAt: now,
      lastAccessedAt: now,
      usageCount: 1,
      sourceType: 'itunes',
      documentId: documentId,
    );
  }

  /// 使用回数を増やし、最終アクセス時刻を更新したコピーを作成
  SharedGameData incrementUsage() {
    return SharedGameData(
      game: game,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      usageCount: usageCount + 1,
      sourceType: sourceType,
      documentId: documentId,
    );
  }

  /// ゲームIDをそのままドキュメントIDとして使用
  static String _generateDocumentId(Game game) {
    return game.id;
  }

  /// キャッシュが有効かどうかを判定
  /// 7日間アクセスされていないデータは古いと判定
  bool get isFresh {
    final now = DateTime.now();
    final daysSinceLastAccess = now.difference(lastAccessedAt).inDays;
    return daysSinceLastAccess <= 7;
  }

  /// 人気度スコアを計算（使用回数と最終アクセス時刻を基に）
  double get popularityScore {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    final daysSinceLastAccess = DateTime.now().difference(lastAccessedAt).inDays;

    // 使用回数を基本スコアとし、最近のアクセスにボーナスを与える
    final baseScore = usageCount.toDouble();
    final recencyBonus = daysSinceLastAccess <= 1 ? 2.0 :
                         daysSinceLastAccess <= 7 ? 1.5 : 1.0;
    final ageDecay = daysSinceCreated > 30 ? 0.8 : 1.0;

    return baseScore * recencyBonus * ageDecay;
  }

  @override
  List<Object?> get props => [
        game,
        createdAt,
        lastAccessedAt,
        usageCount,
        sourceType,
        documentId,
      ];

  @override
  String toString() {
    return 'SharedGameData{game: ${game.name}, usageCount: $usageCount, '
           'sourceType: $sourceType, documentId: $documentId}';
  }
}

/// ゲーム検索のためのクエリパラメータ
class GameSearchQuery extends Equatable {
  final String? name;
  final List<String>? platforms;
  final String? developer;
  final double? minRating;
  final bool? isPopular;

  const GameSearchQuery({
    this.name,
    this.platforms,
    this.developer,
    this.minRating,
    this.isPopular,
  });

  @override
  List<Object?> get props => [
        name,
        platforms,
        developer,
        minRating,
        isPopular,
      ];
}