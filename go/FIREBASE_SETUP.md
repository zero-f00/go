# Firebase認証設定ガイド

このアプリでFirebase Auth（AppleとGoogleサインイン）を機能させるために必要な設定手順です。

## 前提条件
- Firebase プロジェクトが作成済みであること
- Firebase CLI がインストール済みであること
- FlutterFire CLI がインストール済みであること

## 設定手順

### 1. Firebase プロジェクトでの設定

#### Authentication の有効化
1. Firebase Console にアクセス
2. プロジェクトを選択
3. Authentication > Sign-in method に移動
4. 以下のプロバイダーを有効にする：
   - Google
   - Apple（iOS用）

#### Google Sign-In の設定
1. Google プロバイダーを有効にする
2. プロジェクト名とサポートメールを設定
3. Web SDK 設定でクライアント ID をメモ

#### Apple Sign-In の設定（iOS用）
1. Apple プロバイダーを有効にする
2. Apple Developer Account で Sign In with Apple を設定
3. Service ID を Firebase に追加

### 2. FlutterFire CLI での設定

```bash
# プロジェクトルートで実行
flutterfire configure
```

このコマンドにより以下のファイルが生成されます：
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 3. iOS設定

#### Info.plist の更新
`ios/Runner/Info.plist` に以下を追加：

```xml
<!-- Google Sign-In用 -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

`YOUR_REVERSED_CLIENT_ID` は `GoogleService-Info.plist` の `REVERSED_CLIENT_ID` 値に置き換えます。

#### Apple Sign-In Capability
Xcode で以下を有効にする：
1. プロジェクトを Xcode で開く
2. Runner target を選択
3. Signing & Capabilities タブ
4. "+ Capability" をクリック
5. "Sign In with Apple" を追加

### 4. Android設定

#### google-services.json の配置
FlutterFire CLI で生成された `google-services.json` が `android/app/` に配置されていることを確認。

#### build.gradle の設定
`android/build.gradle` に：
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

`android/app/build.gradle` に：
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 5. 現在のファイル更新

生成された実際の `firebase_options.dart` で現在のダミーファイルを置き換えてください。

## テスト

1. iOS シミュレーター / Android エミュレーターでアプリを起動
2. サイドメニューのユーザー部分をタップ
3. サインインダイアログが表示される
4. Google / Apple サインインをテスト

## 注意点

- 本番環境では適切な OAuth リダイレクト URL を設定
- Apple Sign-In は iOS 13+ でのみ利用可能
- Google Sign-In は SHA-1 フィンガープリントの設定が必要（Android）

## トラブルシューティング

### Firebase初期化エラー
- `firebase_options.dart` の設定値を確認
- プラットフォーム別の設定が正しいか確認

### Google Sign-In エラー
- `google-services.json` / `GoogleService-Info.plist` の配置確認
- SHA-1 フィンガープリントの設定確認（Android）

### Apple Sign-In エラー
- Capability の設定確認
- Apple Developer Console での Service ID 設定確認