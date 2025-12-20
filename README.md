# go

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase 設定ファイルの配置と管理

このプロジェクトは、Firebaseの環境を本番用(`prod`)と開発用(`dev`)で切り替えるFlavor設定がされています。
各環境に対応するFirebase設定ファイルを以下の場所に配置してください。

### iOS (`GoogleService-Info.plist`)

*   **開発用 (`dev`)**: `ios/Runner/dev/GoogleService-Info.plist`
*   **本番用 (`prod`)**: `ios/Runner/prod/GoogleService-Info.plist`

ビルド時にXcodeのBuild Phaseスクリプト (`ios/scripts/copy_google_service_info.sh`) が自動的に適切な `GoogleService-Info.plist` を `ios/Runner/GoogleService-Info.plist` にコピーします。

### Android (`google-services.json`)

*   **開発用 (`dev`)**: `android/app/src/dev/google-services.json`
*   **本番用 (`prod`)**: `android/app/src/prod/google-services.json`

これらのファイルを配置すると、ビルド時にGradleプラグインが自動的に適切なものを選択します。

## iOS URLスキーム (`Info.plist`) の設定

Googleサインイン機能を使用する場合、iOSアプリは `REVERSED_CLIENT_ID` をURLスキームとして登録する必要があります。
`ios/Runner/Info.plist` の `CFBundleURLSchemes` 配列には、開発用と本番用の両方の `REVERSED_CLIENT_ID` を記述済みです。これにより、どちらの環境でビルドしてもGoogleサインインが機能します。

例:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.<PROD_REVERSED_CLIENT_ID></string>
            <string>com.googleusercontent.apps.<DEV_REVERSED_CLIENT_ID></string>
        </array>
    </dict>
</array>
```

## ビルド方法 (Building the App)

このプロジェクトは、`--flavor` と `--dart-define=APP_FLAVOR=` を使用してFirebase環境を切り替えます。

### 開発環境 (`dev`)

開発用のFirebaseプロジェクトに接続します。

*   **実行 (デバッグモード):**
    ```bash
    flutter run --flavor dev --dart-define=APP_FLAVOR=dev
    ```

*   **Android (デバッグAPKをビルド):**
    ```bash
    flutter build apk --flavor dev --dart-define=APP_FLAVOR=dev
    ```

*   **iOS (リリースビルド):**
    ```bash
    flutter build ios --release --flavor dev --dart-define=APP_FLAVOR=dev
    ```

### 本番環境 (`prod`)

本番用のFirebaseプロジェクトに接続します。

*   **Android (リリースApp Bundleをビルド):**
    ```bash
    flutter build appbundle --release --flavor prod --dart-define=APP_FLAVOR=prod
    ```

*   **Android (リリースAPKをビルド):**
    ```bash
    flutter build apk --release --flavor prod --dart-define=APP_FLAVOR=prod
    ```

*   **iOS (リリースビルド):**
    ```bash
    flutter build ios --release --flavor prod --dart-define=APP_FLAVOR=prod
    ```

## Firebase CLI (flutterfire) について

このプロジェクトのFirebase設定を更新するには `flutterfire` コマンドラインツールが必要です。
このツールはプロジェクトの依存関係には含まれていません。
もし `flutterfire` コマンドが見つからない場合は、以下のコマンドでグローバルにインストールしてください。

```bash
dart pub global activate flutterfire_cli
```
