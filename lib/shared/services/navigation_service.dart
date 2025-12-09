import 'package:flutter/material.dart';

/// グローバルナビゲーションサービス
/// プッシュ通知からのナビゲーションに使用
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 現在のコンテキストを取得
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// 通知画面に遷移
  void navigateToNotifications() {
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/notifications');
    }
  }

  /// イベント詳細画面に遷移
  void navigateToEventDetail(String eventId) {
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/event_detail', arguments: eventId);
    }
  }

  /// プロフィール画面に遷移
  void navigateToUserProfile(String userId) {
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/user_profile', arguments: userId);
    }
  }

  /// フレンド画面に遷移
  void navigateToFriends() {
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/friends');
    }
  }
}