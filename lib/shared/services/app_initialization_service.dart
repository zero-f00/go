import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';

/// アプリ初期化サービス
/// アプリ起動時の初期化処理を一元管理
class AppInitializationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// アプリ初期化処理
  static Future<void> initialize() async {
    try {
      // ゲストユーザー状態でのキャッシュクリアチェック
      await _clearCacheForGuestUser();

      // その他の初期化処理（将来的に追加可能）
      // - アプリバージョンチェック
      // - 必要な権限のリクエスト
      // - 初回起動時の設定等

    } catch (e) {
      // 初期化エラーでもアプリを続行
    }
  }

  /// ゲストユーザー状態でのキャッシュクリア処理
  static Future<void> _clearCacheForGuestUser() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        await UserService.instance.clearAllUserData();
        await _clearAllAppRelatedPreferences();
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// アプリ関連のSharedPreferencesをクリア
  static Future<void> _clearAllAppRelatedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // アプリ関連のキーパターン（必要に応じて追加）
      final appRelatedPatterns = [
        'user_', // UserServiceのキー
        'game_', // ゲーム関連キー
        'event_', // イベント関連キー
        'cache_', // キャッシュ関連キー
        'settings_', // 設定関連キー（ユーザー固有）
        'temp_', // 一時データ
      ];

      for (final key in keys) {
        for (final pattern in appRelatedPatterns) {
          if (key.startsWith(pattern)) {
            await prefs.remove(key);
            break;
          }
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// 強制的な全キャッシュクリア（開発・デバッグ用）
  static Future<void> forceClearAllCaches() async {
    try {
      await UserService.instance.clearAllUserData();
      await _clearAllAppRelatedPreferences();
    } catch (e) {
      // Silent error handling
    }
  }

  /// アプリバージョン情報の管理（将来的な拡張用）
  static Future<void> _handleAppVersionCheck() async {
    // TODO: 将来的にアプリバージョンチェックとマイグレーション処理を実装
    // - バージョンアップ時のデータマイグレーション
    // - 古いキャッシュの削除
    // - 新機能の初期設定等
  }
}