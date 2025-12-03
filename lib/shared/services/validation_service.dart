import 'dart:io';
import 'package:flutter/material.dart';

/// アプリケーション全体の入力検証サービス
class ValidationService {
  /// メールアドレスの検証
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'メールアドレスの形式が正しくありません';
    }

    return null;
  }

  /// パスワードの検証
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }

    if (value.length < minLength) {
      return 'パスワードは${minLength}文字以上で入力してください';
    }

    // 英数字を含む検証
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return 'パスワードは大文字、小文字、数字をそれぞれ1文字以上含む必要があります';
    }

    return null;
  }

  /// パスワード確認の検証
  static String? validatePasswordConfirm(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'パスワード確認を入力してください';
    }

    if (value != originalPassword) {
      return 'パスワードが一致しません';
    }

    return null;
  }

  /// 必須フィールドの検証
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'この項目'}は必須です';
    }
    return null;
  }

  /// イベント名の検証
  static String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'イベント名を入力してください';
    }

    if (value.trim().length < 3) {
      return 'イベント名は3文字以上で入力してください';
    }

    if (value.trim().length > 100) {
      return 'イベント名は100文字以内で入力してください';
    }

    // 禁止文字のチェック
    final forbiddenChars = RegExp(r'[<>&"\\\/]');
    if (forbiddenChars.hasMatch(value)) {
      return 'イベント名に使用できない文字が含まれています';
    }

    return null;
  }

  /// イベント説明の検証
  static String? validateEventDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'イベント説明を入力してください';
    }

    if (value.trim().length < 10) {
      return 'イベント説明は10文字以上で入力してください';
    }

    if (value.trim().length > 2000) {
      return 'イベント説明は2000文字以内で入力してください';
    }

    return null;
  }

  /// イベントルールの検証
  static String? validateEventRules(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'イベントルールを入力してください';
    }

    if (value.trim().length < 5) {
      return 'イベントルールは5文字以上で入力してください';
    }

    if (value.trim().length > 1000) {
      return 'イベントルールは1000文字以内で入力してください';
    }

    return null;
  }

  /// 参加者数の検証
  static String? validateMaxParticipants(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '最大参加者数を入力してください';
    }

    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return '数値を入力してください';
    }

    if (intValue < 2) {
      return '最大参加者数は2人以上で設定してください';
    }

    if (intValue > 10000) {
      return '最大参加者数は10,000人以下で設定してください';
    }

    return null;
  }

  /// 参加費（自由入力）の検証
  static String? validateParticipationFeeText(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '参加費を入力してください';
    }

    if (value != null && value.trim().isNotEmpty) {
      final trimmedValue = value.trim();

      if (trimmedValue.length > 100) {
        return '参加費は100文字以内で入力してください';
      }

      // 禁止文字のチェック（基本的なHTMLタグやスクリプトを防ぐ）
      final forbiddenChars = RegExp(r'[<>&"\\\\/]');
      if (forbiddenChars.hasMatch(trimmedValue)) {
        return '使用できない文字が含まれています';
      }
    }

    return null;
  }

  /// URLの検証
  static String? validateUrl(
    String? value,
    bool isRequired, [
    String? fieldName,
  ]) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '${fieldName ?? 'URL'}を入力してください';
    }

    if (value != null && value.trim().isNotEmpty) {
      final urlPattern = RegExp(
        r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
        caseSensitive: false,
      );

      if (!urlPattern.hasMatch(value.trim())) {
        return '有効な${fieldName ?? 'URL'}を入力してください（http://またはhttps://で始まる）';
      }
    }

    return null;
  }

  /// 日時の検証
  static String? validateDateTime(
    DateTime? value,
    String fieldName, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (value == null) {
      return '${fieldName}を設定してください';
    }

    if (minDate != null && value.isBefore(minDate)) {
      return '${fieldName}は${_formatDateTime(minDate)}以降に設定してください';
    }

    if (maxDate != null && value.isAfter(maxDate)) {
      return '${fieldName}は${_formatDateTime(maxDate)}以前に設定してください';
    }

    return null;
  }

  /// 文字数制限の検証
  static String? validateTextLength(
    String? value,
    int maxLength,
    String fieldName, {
    int minLength = 0,
    bool isRequired = true,
  }) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '${fieldName}を入力してください';
    }

    final trimmedValue = value?.trim() ?? '';

    if (minLength > 0 && trimmedValue.length < minLength) {
      return '${fieldName}は${minLength}文字以上で入力してください';
    }

    if (trimmedValue.length > maxLength) {
      return '${fieldName}は${maxLength}文字以内で入力してください';
    }

    return null;
  }

  /// 画像ファイルの検証
  static String? validateImageFile(File? file, bool isRequired) {
    if (!isRequired && file == null) {
      return null;
    }

    if (isRequired && file == null) {
      return '画像を選択してください';
    }

    if (file != null) {
      // ファイルサイズの検証（10MB）
      final fileSizeInMB = file.lengthSync() / (1024 * 1024);
      if (fileSizeInMB > 10) {
        return '画像ファイルサイズは10MB以下にしてください';
      }

      // ファイル拡張子の検証
      final extension = file.path.toLowerCase().split('.').last;
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

      if (!allowedExtensions.contains(extension)) {
        return '対応している画像形式: ${allowedExtensions.join(', ')}';
      }
    }

    return null;
  }

  /// リストの検証（プラットフォーム、タグなど）
  static String? validateList(
    List<dynamic>? list,
    String fieldName, {
    int minItems = 1,
    int maxItems = 50,
  }) {
    if (list == null || list.isEmpty) {
      return '${fieldName}を少なくとも${minItems}つ選択してください';
    }

    if (list.length < minItems) {
      return '${fieldName}を少なくとも${minItems}つ選択してください';
    }

    if (list.length > maxItems) {
      return '${fieldName}は${maxItems}個以下で選択してください';
    }

    return null;
  }

  /// イベントタグの検証
  static String? validateEventTags(
    List<String>? tags, {
    bool isRequired = false,
  }) {
    if (!isRequired && (tags == null || tags.isEmpty)) {
      return null;
    }

    if (isRequired && (tags == null || tags.isEmpty)) {
      return 'イベントタグを少なくとも1つ追加してください';
    }

    if (tags != null) {
      // 最大タグ数チェック
      if (tags.length > 10) {
        return 'イベントタグは10個以下で設定してください';
      }

      // 各タグの検証
      for (final tag in tags) {
        // 空文字チェック
        if (tag.trim().isEmpty) {
          return '空のタグは使用できません';
        }

        // 文字数チェック
        if (tag.trim().length > 20) {
          return 'タグは20文字以内で設定してください';
        }

        // 禁止文字チェック
        final forbiddenChars = RegExp(r'[<>&"\\\/\s]');
        if (forbiddenChars.hasMatch(tag)) {
          return 'タグに使用できない文字が含まれています';
        }

        // 英数字、ひらがな、カタカナ、漢字、一部記号のみ許可
        final validPattern = RegExp(
          r'^[a-zA-Z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAFー・＃＆＠＋－]+$',
        );
        if (!validPattern.hasMatch(tag)) {
          return 'タグは英数字、ひらがな、カタカナ、漢字、一部記号のみ使用可能です';
        }
      }

      // 重複チェック
      final uniqueTags = tags.toSet();
      if (uniqueTags.length != tags.length) {
        return '重複するタグは使用できません';
      }
    }

    return null;
  }

  /// 電話番号の検証
  static String? validatePhoneNumber(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '電話番号を入力してください';
    }

    if (value != null && value.trim().isNotEmpty) {
      // 日本の電話番号パターン
      final phoneRegex = RegExp(
        r'^(070|080|090|050)-?\d{4}-?\d{4}$|^0\d{1,4}-?\d{1,4}-?\d{4}$',
      );
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanValue.length < 10 || cleanValue.length > 11) {
        return '電話番号の形式が正しくありません';
      }

      if (!phoneRegex.hasMatch(value.trim())) {
        return '電話番号の形式が正しくありません（例: 090-1234-5678）';
      }
    }

    return null;
  }

  /// 数値範囲の検証
  static String? validateNumberRange(
    String? value,
    String fieldName, {
    int? min,
    int? max,
    bool isRequired = true,
  }) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return '${fieldName}を入力してください';
    }

    if (value != null && value.trim().isNotEmpty) {
      final intValue = int.tryParse(value.trim());
      if (intValue == null) {
        return '${fieldName}は数値で入力してください';
      }

      if (min != null && intValue < min) {
        return '${fieldName}は${min}以上で入力してください';
      }

      if (max != null && intValue > max) {
        return '${fieldName}は${max}以下で入力してください';
      }
    }

    return null;
  }

  /// 複数のバリデータを組み合わせて実行
  static String? validateMultiple(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// イベントパスワードの検証
  static String? validateEventPassword(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'イベントパスワードを設定してください';
    }

    if (value != null && value.trim().isNotEmpty) {
      final trimmedValue = value.trim();

      if (trimmedValue.length < 4) {
        return 'パスワードは4文字以上で設定してください';
      }

      if (trimmedValue.length > 20) {
        return 'パスワードは20文字以内で設定してください';
      }

      // 安全なパスワード文字のみ許可
      final allowedPattern = RegExp(
        r'^[a-zA-Z0-9!@#$%^&*()_+-=\[\]{}|;:,.<>?]+$',
      );
      if (!allowedPattern.hasMatch(trimmedValue)) {
        return 'パスワードには英数字と一般的な記号のみ使用できます';
      }
    }

    return null;
  }


  /// 日時フォーマット用ヘルパー
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// フォーム全体の検証
  static bool validateForm(
    GlobalKey<FormState> formKey, {
    List<String? Function()>? additionalValidations,
  }) {
    bool isValid = formKey.currentState?.validate() ?? false;

    if (additionalValidations != null) {
      for (final validation in additionalValidations) {
        final result = validation();
        if (result != null) {
          isValid = false;
          // 最初のエラーで止める場合
          break;
        }
      }
    }

    return isValid;
  }
}

/// カスタムバリデーター用のクラス
class CustomValidators {
  /// ひらがなのみの検証
  static String? hiraganaOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final hiraganaRegex = RegExp(r'^[あ-ん\s]*$');
    if (!hiraganaRegex.hasMatch(value)) {
      return '${fieldName}はひらがなのみで入力してください';
    }

    return null;
  }

  /// カタカナのみの検証
  static String? katakanaOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final katakanaRegex = RegExp(r'^[ア-ン\s]*$');
    if (!katakanaRegex.hasMatch(value)) {
      return '${fieldName}はカタカナのみで入力してください';
    }

    return null;
  }

  /// 英数字のみの検証
  static String? alphanumericOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]*$');
    if (!alphanumericRegex.hasMatch(value)) {
      return '${fieldName}は英数字のみで入力してください';
    }

    return null;
  }

  /// 禁止語句の検証
  static String? forbiddenWords(
    String? value,
    List<String> forbiddenWords,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) return null;

    final lowerValue = value.toLowerCase();
    for (final word in forbiddenWords) {
      if (lowerValue.contains(word.toLowerCase())) {
        return '${fieldName}に不適切な内容が含まれています';
      }
    }

    return null;
  }
}
