import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// アプリケーション全体の入力検証サービス
/// ローカライズ対応版: BuildContextを使用してL10nからメッセージを取得
class ValidationService {
  final L10n l10n;

  ValidationService(this.l10n);

  /// BuildContextからValidationServiceを作成
  factory ValidationService.of(BuildContext context) {
    return ValidationService(L10n.of(context));
  }

  /// メールアドレスの検証
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return l10n.validationEmailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return l10n.validationEmailInvalid;
    }

    return null;
  }

  /// パスワードの検証
  String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordRequired;
    }

    if (value.length < minLength) {
      return l10n.validationPasswordMinLength(minLength);
    }

    // 英数字を含む検証
    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasLowercase = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));

    if (!hasUppercase || !hasLowercase || !hasDigits) {
      return l10n.validationPasswordComplexity;
    }

    return null;
  }

  /// パスワード確認の検証
  String? validatePasswordConfirm(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.validationPasswordConfirmRequired;
    }

    if (value != originalPassword) {
      return l10n.validationPasswordMismatch;
    }

    return null;
  }

  /// 必須フィールドの検証
  String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      if (fieldName != null) {
        return l10n.validationFieldRequired(fieldName);
      }
      return l10n.validationFieldRequiredDefault;
    }
    return null;
  }

  /// イベント名の検証
  String? validateEventName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEventNameRequired;
    }

    if (value.trim().length < 3) {
      return l10n.validationEventNameMinLength;
    }

    if (value.trim().length > 100) {
      return l10n.validationEventNameMaxLength;
    }

    // 禁止文字のチェック
    final forbiddenChars = RegExp(r'[<>&"\\\/]');
    if (forbiddenChars.hasMatch(value)) {
      return l10n.validationEventNameForbiddenChars;
    }

    return null;
  }

  /// イベント説明の検証
  String? validateEventDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEventDescriptionRequired;
    }

    if (value.trim().length < 10) {
      return l10n.validationEventDescriptionMinLength;
    }

    if (value.trim().length > 2000) {
      return l10n.validationEventDescriptionMaxLength;
    }

    return null;
  }

  /// イベントルールの検証
  String? validateEventRules(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationEventRulesRequired;
    }

    if (value.trim().length < 5) {
      return l10n.validationEventRulesMinLength;
    }

    if (value.trim().length > 1000) {
      return l10n.validationEventRulesMaxLength;
    }

    return null;
  }

  /// 参加者数の検証
  String? validateMaxParticipants(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationMaxParticipantsRequired;
    }

    final intValue = int.tryParse(value.trim());
    if (intValue == null) {
      return l10n.validationNumberRequired;
    }

    if (intValue < 2) {
      return l10n.validationMaxParticipantsMin;
    }

    if (intValue > 10000) {
      return l10n.validationMaxParticipantsMax;
    }

    return null;
  }

  /// 参加費（自由入力）の検証
  String? validateParticipationFeeText(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return l10n.validationParticipationFeeRequired;
    }

    if (value != null && value.trim().isNotEmpty) {
      final trimmedValue = value.trim();

      if (trimmedValue.length > 100) {
        return l10n.validationParticipationFeeMaxLength;
      }

      // 禁止文字のチェック（基本的なHTMLタグやスクリプトを防ぐ）
      final forbiddenChars = RegExp(r'[<>&"\\\\/]');
      if (forbiddenChars.hasMatch(trimmedValue)) {
        return l10n.validationForbiddenChars;
      }
    }

    return null;
  }

  /// URLの検証
  String? validateUrl(
    String? value,
    bool isRequired, [
    String? fieldName,
  ]) {
    final displayName = fieldName ?? 'URL';

    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return l10n.validationUrlRequired(displayName);
    }

    if (value != null && value.trim().isNotEmpty) {
      final urlPattern = RegExp(
        r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
        caseSensitive: false,
      );

      if (!urlPattern.hasMatch(value.trim())) {
        return l10n.validationUrlInvalid(displayName);
      }
    }

    return null;
  }

  /// 日時の検証
  String? validateDateTime(
    DateTime? value,
    String fieldName, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (value == null) {
      return l10n.validationDateTimeRequired(fieldName);
    }

    if (minDate != null && value.isBefore(minDate)) {
      return l10n.validationDateTimeAfter(fieldName, _formatDateTime(minDate));
    }

    if (maxDate != null && value.isAfter(maxDate)) {
      return l10n.validationDateTimeBefore(fieldName, _formatDateTime(maxDate));
    }

    return null;
  }

  /// 文字数制限の検証
  String? validateTextLength(
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
      return l10n.validationUrlRequired(fieldName);
    }

    final trimmedValue = value?.trim() ?? '';

    if (minLength > 0 && trimmedValue.length < minLength) {
      return l10n.validationTextMinLength(fieldName, minLength);
    }

    if (trimmedValue.length > maxLength) {
      return l10n.validationTextMaxLength(fieldName, maxLength);
    }

    return null;
  }

  /// 画像ファイルの検証
  String? validateImageFile(File? file, bool isRequired) {
    if (!isRequired && file == null) {
      return null;
    }

    if (isRequired && file == null) {
      return l10n.validationImageRequired;
    }

    if (file != null) {
      // ファイルサイズの検証（10MB）
      final fileSizeInMB = file.lengthSync() / (1024 * 1024);
      if (fileSizeInMB > 10) {
        return l10n.validationImageSizeMax;
      }

      // ファイル拡張子の検証
      final extension = file.path.toLowerCase().split('.').last;
      const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];

      if (!allowedExtensions.contains(extension)) {
        return l10n.validationImageFormat(allowedExtensions.join(', '));
      }
    }

    return null;
  }

  /// リストの検証（プラットフォーム、タグなど）
  String? validateList(
    List<dynamic>? list,
    String fieldName, {
    int minItems = 1,
    int maxItems = 50,
  }) {
    if (list == null || list.isEmpty) {
      return l10n.validationListMinItems(fieldName, minItems);
    }

    if (list.length < minItems) {
      return l10n.validationListMinItems(fieldName, minItems);
    }

    if (list.length > maxItems) {
      return l10n.validationListMaxItems(fieldName, maxItems);
    }

    return null;
  }

  /// イベントタグの検証
  String? validateEventTags(
    List<String>? tags, {
    bool isRequired = false,
  }) {
    if (!isRequired && (tags == null || tags.isEmpty)) {
      return null;
    }

    if (isRequired && (tags == null || tags.isEmpty)) {
      return l10n.validationEventTagsRequired;
    }

    if (tags != null) {
      // 最大タグ数チェック
      if (tags.length > 10) {
        return l10n.validationEventTagsMaxCount;
      }

      // 各タグの検証
      for (final tag in tags) {
        // 空文字チェック
        if (tag.trim().isEmpty) {
          return l10n.validationTagEmpty;
        }

        // 文字数チェック
        if (tag.trim().length > 20) {
          return l10n.validationTagMaxLength;
        }

        // 禁止文字チェック
        final forbiddenChars = RegExp(r'[<>&"\\\/\s]');
        if (forbiddenChars.hasMatch(tag)) {
          return l10n.validationTagForbiddenChars;
        }

        // 英数字、ひらがな、カタカナ、漢字、一部記号のみ許可
        final validPattern = RegExp(
          r'^[a-zA-Z0-9\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAFー・＃＆＠＋－]+$',
        );
        if (!validPattern.hasMatch(tag)) {
          return l10n.validationTagInvalidChars;
        }
      }

      // 重複チェック
      final uniqueTags = tags.toSet();
      if (uniqueTags.length != tags.length) {
        return l10n.validationTagDuplicate;
      }
    }

    return null;
  }

  /// 電話番号の検証
  String? validatePhoneNumber(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return l10n.validationPhoneRequired;
    }

    if (value != null && value.trim().isNotEmpty) {
      // 日本の電話番号パターン
      final phoneRegex = RegExp(
        r'^(070|080|090|050)-?\d{4}-?\d{4}$|^0\d{1,4}-?\d{1,4}-?\d{4}$',
      );
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanValue.length < 10 || cleanValue.length > 11) {
        return l10n.validationPhoneInvalid;
      }

      if (!phoneRegex.hasMatch(value.trim())) {
        return l10n.validationPhoneInvalidWithExample;
      }
    }

    return null;
  }

  /// 数値範囲の検証
  String? validateNumberRange(
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
      return l10n.validationNumberRangeRequired(fieldName);
    }

    if (value != null && value.trim().isNotEmpty) {
      final intValue = int.tryParse(value.trim());
      if (intValue == null) {
        return l10n.validationNumberRangeInvalid(fieldName);
      }

      if (min != null && intValue < min) {
        return l10n.validationNumberRangeMin(fieldName, min);
      }

      if (max != null && intValue > max) {
        return l10n.validationNumberRangeMax(fieldName, max);
      }
    }

    return null;
  }

  /// 複数のバリデータを組み合わせて実行
  String? validateMultiple(
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
  String? validateEventPassword(String? value, bool isRequired) {
    if (!isRequired && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (isRequired && (value == null || value.trim().isEmpty)) {
      return l10n.validationEventPasswordRequired;
    }

    if (value != null && value.trim().isNotEmpty) {
      final trimmedValue = value.trim();

      if (trimmedValue.length < 4) {
        return l10n.validationEventPasswordMinLength;
      }

      if (trimmedValue.length > 20) {
        return l10n.validationEventPasswordMaxLength;
      }

      // 安全なパスワード文字のみ許可
      final allowedPattern = RegExp(
        r'^[a-zA-Z0-9!@#$%^&*()_+-=\[\]{}|;:,.<>?]+$',
      );
      if (!allowedPattern.hasMatch(trimmedValue)) {
        return l10n.validationEventPasswordInvalidChars;
      }
    }

    return null;
  }


  /// 日時フォーマット用ヘルパー
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

/// カスタムバリデーター用のクラス（ローカライズ対応版）
class CustomValidators {
  final L10n l10n;

  CustomValidators(this.l10n);

  /// BuildContextからCustomValidatorsを作成
  factory CustomValidators.of(BuildContext context) {
    return CustomValidators(L10n.of(context));
  }

  /// ひらがなのみの検証
  String? hiraganaOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final hiraganaRegex = RegExp(r'^[あ-ん\s]*$');
    if (!hiraganaRegex.hasMatch(value)) {
      return l10n.validationHiraganaOnly(fieldName);
    }

    return null;
  }

  /// カタカナのみの検証
  String? katakanaOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final katakanaRegex = RegExp(r'^[ア-ン\s]*$');
    if (!katakanaRegex.hasMatch(value)) {
      return l10n.validationKatakanaOnly(fieldName);
    }

    return null;
  }

  /// 英数字のみの検証
  String? alphanumericOnly(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]*$');
    if (!alphanumericRegex.hasMatch(value)) {
      return l10n.validationAlphanumericOnly(fieldName);
    }

    return null;
  }

  /// 禁止語句の検証
  String? forbiddenWords(
    String? value,
    List<String> forbiddenWords,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) return null;

    final lowerValue = value.toLowerCase();
    for (final word in forbiddenWords) {
      if (lowerValue.contains(word.toLowerCase())) {
        return l10n.validationForbiddenContent(fieldName);
      }
    }

    return null;
  }
}
