import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import 'push_notification_service.dart';
import 'event_reminder_service.dart';

/// アプリ初期化サービス
/// アプリ起動時の初期化処理を一元管理
class AppInitializationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// アプリ初期化処理
  static Future<void> initialize() async {
    try {
      print('🚀 AppInitializationService: Starting app initialization...');

      // ゲストユーザー状態でのキャッシュクリアチェック
      await _clearCacheForGuestUser();

      // プッシュ通知サービスの初期化
      await _initializePushNotifications();

      // イベントリマインダーサービスの初期化
      await _initializeEventReminderService();

      // その他の初期化処理（将来的に追加可能）
      // - アプリバージョンチェック
      // - 必要な権限のリクエスト
      // - 初回起動時の設定等

      print('✅ AppInitializationService: App initialization completed');
    } catch (e) {
      print('❌ AppInitializationService: Initialization error: $e');
      // 初期化エラーでもアプリを続行
    }
  }

  /// プッシュ通知サービスの初期化
  static Future<void> _initializePushNotifications() async {
    try {
      print('🔔 AppInitializationService: Initializing push notifications...');

      final pushService = PushNotificationService.instance;
      final success = await pushService.initialize();

      if (success) {
        print('✅ AppInitializationService: Push notifications initialized successfully');
      } else {
        print('⚠️ AppInitializationService: Push notification initialization failed, but continuing...');
      }
    } catch (e) {
      print('❌ AppInitializationService: Push notification initialization error: $e');
      // プッシュ通知初期化失敗でもアプリを続行
    }
  }

  /// イベントリマインダーサービスの初期化
  static Future<void> _initializeEventReminderService() async {
    try {
      print('⏰ AppInitializationService: Initializing event reminder service...');

      // 認証済みユーザーの場合のみリマインダーサービスを開始
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        EventReminderService.instance.startReminderService();
        print('✅ AppInitializationService: Event reminder service started successfully');
      } else {
        print('⚠️ AppInitializationService: Skipping reminder service (user not authenticated)');
      }
    } catch (e) {
      print('❌ AppInitializationService: Event reminder service initialization error: $e');
      // リマインダーサービス初期化失敗でもアプリを続行
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