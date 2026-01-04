import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// サポートされる言語
enum AppLanguage {
  system,  // システム設定に従う
  ja,      // 日本語
  en,      // 英語
  ko,      // 韓国語
  zh,      // 中国語（簡体字）
  zhTW,    // 中国語（繁体字）
}

extension AppLanguageExtension on AppLanguage {
  /// 言語コードを取得
  String? get languageCode {
    switch (this) {
      case AppLanguage.system:
        return null;
      case AppLanguage.ja:
        return 'ja';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.ko:
        return 'ko';
      case AppLanguage.zh:
        return 'zh';
      case AppLanguage.zhTW:
        return 'zh';
    }
  }

  /// 国コードを取得
  String? get countryCode {
    switch (this) {
      case AppLanguage.zhTW:
        return 'TW';
      default:
        return null;
    }
  }

  /// Localeを取得
  Locale? get locale {
    if (this == AppLanguage.system) return null;
    return Locale(languageCode!, countryCode);
  }

  /// 表示名を取得（その言語のネイティブ表記）
  String get displayName {
    switch (this) {
      case AppLanguage.system:
        return 'System';
      case AppLanguage.ja:
        return '日本語';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.ko:
        return '한국어';
      case AppLanguage.zh:
        return '简体中文';
      case AppLanguage.zhTW:
        return '繁體中文';
    }
  }

  /// 保存用のキー
  String get storageKey {
    switch (this) {
      case AppLanguage.system:
        return 'system';
      case AppLanguage.ja:
        return 'ja';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.ko:
        return 'ko';
      case AppLanguage.zh:
        return 'zh';
      case AppLanguage.zhTW:
        return 'zh_TW';
    }
  }

  /// 保存キーから言語を取得
  static AppLanguage fromStorageKey(String? key) {
    switch (key) {
      case 'ja':
        return AppLanguage.ja;
      case 'en':
        return AppLanguage.en;
      case 'ko':
        return AppLanguage.ko;
      case 'zh':
        return AppLanguage.zh;
      case 'zh_TW':
        return AppLanguage.zhTW;
      default:
        return AppLanguage.system;
    }
  }
}

/// 言語設定の永続化キー
const String _localePreferenceKey = 'app_language';

/// 言語設定を管理するNotifier
class LocaleNotifier extends StateNotifier<AppLanguage> {
  LocaleNotifier() : super(AppLanguage.system) {
    _loadSavedLocale();
  }

  /// 保存された言語設定を読み込む
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(_localePreferenceKey);
    state = AppLanguageExtension.fromStorageKey(savedKey);
  }

  /// 言語を設定する
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePreferenceKey, language.storageKey);
  }

  /// 現在のLocaleを取得（システム言語も考慮）
  Locale getEffectiveLocale(Locale systemLocale) {
    if (state == AppLanguage.system) {
      // システム言語がサポートされているか確認
      final supportedCodes = ['ja', 'en', 'ko', 'zh'];
      if (supportedCodes.contains(systemLocale.languageCode)) {
        return systemLocale;
      }
      // サポートされていない場合は英語をデフォルトに
      return const Locale('en');
    }
    return state.locale ?? const Locale('ja');
  }
}

/// 言語設定プロバイダー
final localeProvider = StateNotifierProvider<LocaleNotifier, AppLanguage>((ref) {
  return LocaleNotifier();
});

/// 実効的なLocaleを取得するプロバイダー
/// ウィジェットツリー内で使用するにはSystemLocaleが必要
final effectiveLocaleProvider = Provider.family<Locale, Locale>((ref, systemLocale) {
  final language = ref.watch(localeProvider);
  final notifier = ref.read(localeProvider.notifier);
  return notifier.getEffectiveLocale(systemLocale);
});
