import 'package:url_launcher/url_launcher.dart';

/// ストリーミングプラットフォーム
enum StreamingPlatform {
  youtube,
  twitch,
  niconico,
  other,
}

/// ストリーミング関連のユーティリティクラス
class StreamingUtils {
  /// URLからストリーミングプラットフォームを判定
  static StreamingPlatform detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return StreamingPlatform.other;

    final host = uri.host.toLowerCase();

    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return StreamingPlatform.youtube;
    } else if (host.contains('twitch.tv')) {
      return StreamingPlatform.twitch;
    } else if (host.contains('nicovideo.jp') || host.contains('live.nicovideo.jp')) {
      return StreamingPlatform.niconico;
    }

    return StreamingPlatform.other;
  }

  /// プラットフォーム名の表示用文字列を取得
  static String getPlatformName(StreamingPlatform platform) {
    switch (platform) {
      case StreamingPlatform.youtube:
        return 'YouTube';
      case StreamingPlatform.twitch:
        return 'Twitch';
      case StreamingPlatform.niconico:
        return 'ニコニコ生放送';
      case StreamingPlatform.other:
        return '配信サイト';
    }
  }

  /// プラットフォームのアイコンデータを取得
  static String getPlatformIcon(StreamingPlatform platform) {
    switch (platform) {
      case StreamingPlatform.youtube:
        return '🔴'; // または専用アイコン
      case StreamingPlatform.twitch:
        return '🟣';
      case StreamingPlatform.niconico:
        return '🔵';
      case StreamingPlatform.other:
        return '🌐';
    }
  }

  /// YouTube URLからVideo IDを抽出
  static String? extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com') && uri.path == '/watch') {
      return uri.queryParameters['v'];
    }

    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    // youtube.com/live/VIDEO_ID (ライブストリーム)
    if (uri.host.contains('youtube.com') && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'live') {
      return uri.pathSegments[1];
    }

    // youtube.com/embed/VIDEO_ID
    if (uri.host.contains('youtube.com') && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
      return uri.pathSegments[1];
    }

    return null;
  }

  /// URLを外部アプリまたはブラウザで開く
  static Future<bool> openExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  /// YouTubeアプリで開く（優先的にYouTubeアプリを使用）
  static Future<bool> openYouTubeApp(String url) async {
    try {
      // YouTubeアプリ優先で開く
      final uri = Uri.parse(url);

      // まずYouTubeアプリで開こうとする
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return opened;
    } catch (e) {
      return false;
    }
  }

  /// ブラウザで開く
  static Future<bool> openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      return false;
    }
  }

  /// URLのドメイン名を抽出
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return 'Unknown';
    }
  }

  /// URLが有効かチェック
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// YouTubeのサムネイル画像URLを生成
  static String? getYouTubeThumbnail(String url) {
    final videoId = extractYouTubeVideoId(url);
    if (videoId == null) return null;

    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}