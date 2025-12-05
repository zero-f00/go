# AppTextField 移行ガイド

## 概要

アプリ全体でテキストフィールドの統一化とキーボードツールバー機能を提供するため、新しい `AppTextField` コンポーネントを導入しました。

## 主な機能

- ✅ **統一されたデザイン**: 全画面で一貫したUI
- ✅ **自動キーボードツールバー**: 複数行入力時に自動的にツールバーを表示
- ✅ **改行機能**: 複数行フィールドで自然な改行が可能
- ✅ **iOS・Android対応**: 両プラットフォーム最適化済み
- ✅ **バリデーション**: 必須項目の自動検証
- ✅ **アクセシビリティ**: 適切なTextInputAction設定

## 使用方法

### 1. 基本的な使用方法

```dart
// インポート
import '../../../shared/widgets/app_text_field.dart';

// 単一行入力
AppTextField(
  controller: _nameController,
  label: 'イベント名',
  hintText: 'イベント名を入力してください',
  isRequired: true,
)

// 複数行入力（自動的にキーボードツールバーが表示されます）
AppTextField(
  controller: _descriptionController,
  label: '説明',
  hintText: 'イベントの詳しい説明を入力してください',
  maxLines: 4,
  isRequired: true,
)
```

### 2. ショートハンド版

```dart
// 単一行入力専用
AppTextFieldSingle(
  controller: _nameController,
  label: 'イベント名',
  hintText: 'イベント名を入力してください',
  isRequired: true,
)

// 複数行入力専用
AppTextFieldMultiline(
  controller: _descriptionController,
  label: '説明',
  hintText: 'イベントの詳しい説明を入力してください',
  maxLines: 4,
  isRequired: true,
)
```

### 3. 高度なオプション

```dart
AppTextField(
  controller: _controller,
  label: 'パスワード',
  hintText: 'パスワードを入力',
  obscureText: true,
  validator: (value) {
    if (value != null && value.length < 8) {
      return 'パスワードは8文字以上で入力してください';
    }
    return null;
  },
  suffixIcon: Icon(Icons.visibility),
)
```

## 移行手順

### Phase 1: 新規画面での使用

新しく作成する画面では `AppTextField` を使用してください。

### Phase 2: 既存画面の段階的移行

以下の優先順位で既存画面を移行します：

#### 高優先度（複数行入力がある画面）
- ✅ イベント作成画面（既に対応済み）
- ✅ イベント編集画面（既に対応済み）
- ⬜ ゲームプロフィール編集画面
- ⬜ 違反報告画面
- ⬜ イベントキャンセル理由入力

#### 中優先度（単一行だが多数のフィールドがある画面）
- ⬜ ユーザープロフィール編集
- ⬜ 設定画面

#### 低優先度（表示用または検索用フィールド）
- ⬜ 検索画面
- ⬜ 結果入力ダイアログ

## 移行例

### Before（旧実装）
```dart
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  bool isRequired = false,
  int maxLines = 1,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint),
        validator: isRequired ? (value) => value?.isEmpty == true ? '必須項目です' : null : null,
      ),
    ],
  );
}
```

### After（新実装）
```dart
AppTextField(
  controller: controller,
  label: label,
  hintText: hint,
  isRequired: isRequired,
  maxLines: maxLines,
)
```

## 互換性

既存の `EnhancedMultilineTextField` は非推奨になりますが、移行期間中は引き続き動作します：

```dart
// 非推奨だが動作する
@Deprecated('Use AppTextField instead')
EnhancedMultilineTextField(
  controller: controller,
  label: label,
  hint: hint,
)

// 推奨の新しい書き方
AppTextField(
  controller: controller,
  label: label,
  hintText: hint,
)
```

## 主なメリット

1. **開発効率向上**: 統一されたAPIで開発が簡単
2. **UX改善**: キーボードツールバーで操作性向上
3. **保守性向上**: 一箇所でスタイルを管理
4. **アクセシビリティ**: 適切なTextInputAction自動設定
5. **プラットフォーム最適化**: iOS・Android両方で最適なUI

## 注意点

1. **FocusNode**: 必要に応じて外部から渡すことができます
2. **Validator**: カスタムバリデーションも可能です
3. **キーボードツールバー**: `showKeyboardToolbar: false` で無効化できます
4. **maxLength**: 文字数制限も設定可能です

このコンポーネントにより、アプリ全体で一貫したテキスト入力体験を提供できるようになります。