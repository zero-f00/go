import 'dart:async';
import 'dart:ui' show Locale;
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'navigation_service.dart';

/// ディープリンク処理サービス
/// Universal Links (iOS) / App Links (Android) を処理してアプリ内ナビゲーションを行う
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Vercelでホストするランディングページのドメイン
  /// TODO: 開発環境用のドメイン切り替え対応
  /// 現在は本番環境のみ対応。開発環境でテストする場合は本番Firebaseに
  /// 同じイベントを作成する必要がある。
  /// 将来的にはFlavorに応じてドメインを切り替える実装を検討。
  static const String webDomain = 'go-web-teal.vercel.app';

  /// ディープリンクのパスパターン
  static const String eventPathPrefix = '/event/';
  static const String userPathPrefix = '/user/';

  /// 初期化
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // アプリ起動時のリンクをチェック
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeepLinkService: Failed to get initial link - $e');
      }
    }

    // アプリ実行中のリンクを監視
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (error) {
        if (kDebugMode) {
          print('DeepLinkService: Link stream error - $error');
        }
      },
    );
  }

  /// リンクを処理
  void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      print('DeepLinkService: Received deep link - $uri');
    }

    // ホストが一致するか確認
    if (uri.host != webDomain) {
      if (kDebugMode) {
        print('DeepLinkService: Unknown host - ${uri.host}');
      }
      return;
    }

    // パスを解析
    final path = uri.path;

    // イベント詳細へのリンク: /event/{eventId}
    if (path.startsWith(eventPathPrefix)) {
      final eventId = path.substring(eventPathPrefix.length);
      if (eventId.isNotEmpty) {
        _navigateToEventDetail(eventId);
      }
      return;
    }

    // ユーザープロフィールへのリンク: /user/{userId}
    if (path.startsWith(userPathPrefix)) {
      final userId = path.substring(userPathPrefix.length);
      if (userId.isNotEmpty) {
        _navigateToUserProfile(userId);
      }
    }
  }

  /// イベント詳細画面へ遷移
  void _navigateToEventDetail(String eventId) {
    if (kDebugMode) {
      print('DeepLinkService: Navigating to event detail - $eventId');
    }

    // NavigationServiceを使用して遷移
    // アプリが完全に起動していない可能性があるため、少し遅延させる
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        NavigationService.navigatorKey.currentState?.pushNamed(
          '/event_detail',
          arguments: eventId,
        );
      }
    });
  }

  /// ユーザープロフィール画面へ遷移
  void _navigateToUserProfile(String userId) {
    if (kDebugMode) {
      print('DeepLinkService: Navigating to user profile - $userId');
    }

    // NavigationServiceを使用して遷移
    // アプリが完全に起動していない可能性があるため、少し遅延させる
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null) {
        NavigationService.navigatorKey.currentState?.pushNamed(
          '/user_profile',
          arguments: userId,
        );
      }
    });
  }

  /// イベント共有用URLを生成
  /// [locale] が指定された場合、言語パラメータをURLに追加
  static String generateEventShareUrl(String eventId, {Locale? locale}) {
    final baseUrl = 'https://$webDomain$eventPathPrefix$eventId';
    return _appendLangParam(baseUrl, locale);
  }

  /// ユーザープロフィール共有用URLを生成
  /// [locale] が指定された場合、言語パラメータをURLに追加
  static String generateUserShareUrl(String userId, {Locale? locale}) {
    final baseUrl = 'https://$webDomain$userPathPrefix$userId';
    return _appendLangParam(baseUrl, locale);
  }

  /// URLに言語パラメータを追加
  /// go-webがサポートする言語: ja, en, ko, zh
  static String _appendLangParam(String url, Locale? locale) {
    if (locale == null) return url;

    // go-webがサポートする言語コード
    const supportedLangs = ['ja', 'en', 'ko', 'zh'];
    final langCode = locale.languageCode;

    if (supportedLangs.contains(langCode)) {
      return '$url?lang=$langCode';
    }

    return url;
  }

  /// リソース解放
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
  }
}
