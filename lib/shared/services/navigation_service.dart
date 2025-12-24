import 'package:flutter/material.dart';

/// グローバルナビゲーションサービス
/// プッシュ通知からのナビゲーションに使用
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static NavigationService get instance => _instance;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// MainScreenのタブ切り替え用コールバック
  void Function(int index)? _onTabChanged;

  /// タブ切り替えコールバックを設定
  void setTabChangeCallback(void Function(int index) callback) {
    _onTabChanged = callback;
  }

  /// タブ切り替えコールバックをクリア
  void clearTabChangeCallback() {
    _onTabChanged = null;
  }

  /// 現在のコンテキストを取得
  BuildContext? get currentContext => navigatorKey.currentContext;

  /// 通知画面に遷移（MainScreenの通知タブに切り替え）
  void navigateToNotifications() {
    if (_onTabChanged == null) return;

    // ルートまでポップしてからタブを切り替え
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    _onTabChanged!(2); // 通知タブのインデックス
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

  /// 相互フォロー画面に遷移
  void navigateToFriends() {
    final context = currentContext;
    if (context != null) {
      Navigator.of(context).pushNamed('/friends');
    }
  }

  /// 試合詳細画面に遷移（試合結果管理画面経由）
  void navigateToMatchDetail({
    required String eventId,
    required String matchId,
  }) {
    final context = currentContext;
    if (context != null) {
      // 試合結果管理画面に遷移
      Navigator.of(context).pushNamed(
        '/result_management',
        arguments: {
          'eventId': eventId,
          'eventName': '', // イベント名は画面内で取得
          'highlightMatchId': matchId, // 特定の試合をハイライト表示するため
        },
      );
    }
  }
}