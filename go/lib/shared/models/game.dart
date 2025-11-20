class Game {
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

  /// FirestoreのGameモデルから変換するファクトリメソッド
  factory Game.fromFirestoreGame(dynamic firestoreGame) {
    if (firestoreGame is Map<String, dynamic>) {
      return Game(
        id: firestoreGame['id'] as String? ?? '',
        name: firestoreGame['name'] as String? ?? '',
        developer: firestoreGame['developer'] as String? ?? '',
        description: firestoreGame['description'] as String?,
        genres: (firestoreGame['genres'] as List<dynamic>?)?.cast<String>() ?? [],
        platforms: (firestoreGame['platforms'] as List<dynamic>?)?.cast<String>() ?? [],
        iconUrl: firestoreGame['iconUrl'] as String?,
        rating: (firestoreGame['rating'] as num?)?.toDouble(),
        isPopular: firestoreGame['isPopular'] as bool? ?? false,
      );
    }
    // 既にGameオブジェクトの場合はそのまま返す
    if (firestoreGame is Game) {
      return firestoreGame;
    }
    // 想定外の型の場合はデフォルトGame
    return const Game(
      id: 'unknown',
      name: 'Unknown Game',
      developer: 'Unknown',
      genres: [],
      platforms: [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Game && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// JSONからGameを作成
  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      developer: json['developer'] as String? ?? '',
      description: json['description'] as String?,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      platforms: (json['platforms'] as List<dynamic>?)?.cast<String>() ?? [],
      iconUrl: json['iconUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  /// JSONに変換
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

  @override
  String toString() => 'Game(id: $id, name: $name, developer: $developer)';
}