import 'package:equatable/equatable.dart';

/// ゲームデータモデル
/// 既存のGameクラスとの互換性を保ちつつFirestore対応
class Game extends Equatable {
  final String id;
  final String name;
  final String developer;
  final String? description;
  final List<String> genres;
  final List<String> platforms;
  final String? iconUrl;
  final double? rating;
  final bool isPopular;

  const Game({
    required this.id,
    required this.name,
    required this.developer,
    this.description,
    required this.genres,
    required this.platforms,
    this.iconUrl,
    this.rating,
    this.isPopular = false,
  });

  /// JSONから Game を作成
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String,
      name: json['name'] as String,
      developer: json['developer'] as String,
      description: json['description'] as String?,
      genres: List<String>.from(json['genres'] ?? []),
      platforms: List<String>.from(json['platforms'] ?? []),
      iconUrl: json['iconUrl'] as String?,
      rating: json['rating']?.toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'developer': developer,
      'description': description,
      'genres': genres,
      'platforms': platforms,
      'iconUrl': iconUrl,
      'rating': rating,
      'isPopular': isPopular,
    };
  }

  /// 既存のGameクラスから新しいGame modelへの変換
  factory Game.fromLegacyGame(dynamic legacyGame) {
    return Game(
      id: legacyGame.id,
      name: legacyGame.name,
      developer: legacyGame.developer,
      description: legacyGame.description,
      genres: legacyGame.genres,
      platforms: legacyGame.platforms,
      iconUrl: legacyGame.iconUrl,
      rating: legacyGame.rating,
      isPopular: legacyGame.isPopular,
    );
  }

  /// 新しいGame modelから既存のGameクラスへの変換
  dynamic toLegacyGame() {
    // 既存のGameクラスのインスタンスを作成
    // この部分は既存のGameクラスの実装に依存
    return this; // 一時的に自分自身を返す
  }

  @override
  List<Object?> get props => [
        id,
        name,
        developer,
        description,
        genres,
        platforms,
        iconUrl,
        rating,
        isPopular,
      ];

  @override
  String toString() {
    return 'Game{id: $id, name: $name, developer: $developer}';
  }
}