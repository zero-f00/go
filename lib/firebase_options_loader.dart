// go/lib/firebase_options_loader.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, kDebugMode; // kDebugMode を追加

import 'firebase_options_dev.dart'; // 開発用
import 'firebase_options_prod.dart'; // 本番用 (現在の firebase_options.dart をリネームしたもの)

// Flavor判定のための環境変数
// flutter run --flavor dev -t lib/main_dev.dart --dart-define=APP_FLAVOR=dev
// flutter run --flavor prod -t lib/main_prod.dart --dart-define=APP_FLAVOR=prod
// のように、dart-define で APP_FLAVOR を渡すことを想定。
const String _flavor = String.fromEnvironment('APP_FLAVOR');

class FirebaseOptionsLoader {
  static FirebaseOptions get currentPlatform {
    switch (_flavor) {
      case 'dev':
        return DefaultFirebaseOptionsDev.currentPlatform;
      case 'prod':
        return DefaultFirebaseOptionsProd.currentPlatform;
      default:
        // デフォルトとして本番環境を使用するか、エラーを投げるか
        // アプリケーションの要件に応じて調整
        // 例: Debugモードでのみdevを使う、リリースビルドではprodを強制するなど
        if (kDebugMode) {
          // デバッグモードでFLAVORが指定されていない場合は開発用を使用
          return DefaultFirebaseOptionsDev.currentPlatform;
        }
        throw Exception('Unknown or undefined APP_FLAVOR: $_flavor');
    }
  }
}