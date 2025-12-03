import 'game.dart';

class ITunesApp {
  final int trackId;
  final String trackName;
  final String artistName;
  final String description;
  final List<String> genres;
  final String artworkUrl100;
  final String artworkUrl512;
  final double? averageUserRating;
  final int? userRatingCount;
  final String primaryGenreName;
  final String? releaseDate;
  final String? version;
  final String? trackViewUrl;
  final String? fileSizeBytes;
  final double? price;
  final String? formattedPrice;
  final String? contentAdvisoryRating;
  final List<String> supportedDevices;
  final List<String> screenshotUrls;
  final List<String> ipadScreenshotUrls;

  const ITunesApp({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.description,
    required this.genres,
    required this.artworkUrl100,
    required this.artworkUrl512,
    this.averageUserRating,
    this.userRatingCount,
    required this.primaryGenreName,
    this.releaseDate,
    this.version,
    this.trackViewUrl,
    this.fileSizeBytes,
    this.price,
    this.formattedPrice,
    this.contentAdvisoryRating,
    required this.supportedDevices,
    required this.screenshotUrls,
    required this.ipadScreenshotUrls,
  });

  factory ITunesApp.fromJson(Map<String, dynamic> json) {
    return ITunesApp(
      trackId: json['trackId'] as int,
      trackName: json['trackName'] as String,
      artistName: json['artistName'] as String,
      description: json['description'] as String? ?? '',
      genres: List<String>.from(json['genres'] as List? ?? []),
      artworkUrl100: json['artworkUrl100'] as String? ?? '',
      artworkUrl512: json['artworkUrl512'] as String? ?? '',
      averageUserRating: (json['averageUserRating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      primaryGenreName: json['primaryGenreName'] as String,
      releaseDate: json['releaseDate'] as String?,
      version: json['version'] as String?,
      trackViewUrl: json['trackViewUrl'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      formattedPrice: json['formattedPrice'] as String?,
      contentAdvisoryRating: json['contentAdvisoryRating'] as String?,
      supportedDevices: List<String>.from(json['supportedDevices'] as List? ?? []),
      screenshotUrls: List<String>.from(json['screenshotUrls'] as List? ?? []),
      ipadScreenshotUrls: List<String>.from(json['ipadScreenshotUrls'] as List? ?? []),
    );
  }

  Game toGame() {
    return Game(
      id: trackId.toString(),
      name: trackName,
      developer: artistName,
      description: description,
      genres: genres.isNotEmpty ? genres : [primaryGenreName],
      platforms: _getPlatforms(),
      iconUrl: artworkUrl512.isNotEmpty ? artworkUrl512 : artworkUrl100,
      rating: averageUserRating,
      isPopular: (userRatingCount ?? 0) > 1000 && (averageUserRating ?? 0) >= 4.0,
    );
  }

  List<String> _getPlatforms() {
    final platforms = <String>[];

    if (supportedDevices.any((device) => device.contains('iPhone'))) {
      platforms.add('iOS');
    }

    if (supportedDevices.any((device) => device.contains('iPad'))) {
      platforms.add('iPad');
    }

    if (platforms.isEmpty) {
      platforms.add('iOS');
    }

    return platforms;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ITunesApp &&
      runtimeType == other.runtimeType &&
      trackId == other.trackId;

  @override
  int get hashCode => trackId.hashCode;

  @override
  String toString() => 'ITunesApp(trackId: $trackId, trackName: $trackName, artistName: $artistName)';
}