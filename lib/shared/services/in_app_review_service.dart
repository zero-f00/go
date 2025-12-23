import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../constants/app_constants.dart';

class InAppReviewService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// アプリ内レビューを表示する
  /// デバイスがサポートしていない場合は、アプリストアページを開く
  static Future<void> requestReview() async {
    try {
      // デバッグモードではスキップ（リリースビルドのみ動作）
      if (kDebugMode) {
        print('In-App Review: Skipping in debug mode');
        return;
      }

      // ストア設定の検証
      if (!_isValidStoreConfiguration()) {
        // リリースでも設定不正なら何もしない
        return;
      }

      // デバイスがアプリ内レビューをサポートしているかチェック
      if (await _inAppReview.isAvailable()) {
        // アプリ内レビューダイアログを表示
        await _inAppReview.requestReview();
      } else {
        // サポートしていない場合は、アプリストアページを開く
        await openStoreListing();
      }
    } catch (e) {
      // エラーが発生した場合は無視（フリーズを防ぐ）
      if (kDebugMode) {
        print('In-App Review error: $e');
      }
      // エラー時は何もしない
    }
  }

  /// アプリストアページを直接開く
  static Future<void> openStoreListing() async {
    try {
      // ストア設定が有効かチェック
      if (!_isValidStoreConfiguration()) {
        if (kDebugMode) {
          print('Store listing: Invalid store configuration, skipping');
        }
        return;
      }

      // まずネイティブAPIで開く試行
      try {
        await _inAppReview.openStoreListing(
          appStoreId: AppConstants.iosAppStoreId,
        );
      } catch (e) {
        // ネイティブAPIが失敗した場合はブラウザで開く
        if (kDebugMode) {
          print('Native store listing failed, trying browser: $e');
        }
        await _openStoreInBrowser();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Store listing error: $e');
      }
      // 最終フォールバック：ブラウザで開く
      await _openStoreInBrowser();
    }
  }

  /// ブラウザでストアページを開く
  static Future<void> _openStoreInBrowser() async {
    String storeUrl;

    if (Platform.isIOS) {
      // iOS App Store
      storeUrl = 'https://apps.apple.com/app/id${AppConstants.iosAppStoreId}';
    } else if (Platform.isAndroid) {
      // Google Play Store
      storeUrl = 'https://play.google.com/store/apps/details?id=${AppConstants.androidPackageName}';
    } else {
      return; // サポートしていないプラットフォーム
    }

    try {
      final Uri uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Browser launch error: $e');
      }
    }
  }

  /// ストア設定が有効かチェック
  static bool _isValidStoreConfiguration() {
    // iOS App Store IDが有効かチェック
    if (Platform.isIOS) {
      return AppConstants.iosAppStoreId != 'YOUR_APP_STORE_ID' &&
             AppConstants.iosAppStoreId.isNotEmpty &&
             RegExp(r'^\d+$').hasMatch(AppConstants.iosAppStoreId);
    }

    // Androidパッケージ名が有効かチェック
    if (Platform.isAndroid) {
      return AppConstants.androidPackageName != 'YOUR_PACKAGE_NAME' &&
             AppConstants.androidPackageName.isNotEmpty &&
             AppConstants.androidPackageName.contains('.');
    }

    return false;
  }

  /// レビューリクエストの条件をチェック
  /// アプリの使用頻度や重要なアクションの完了後などに呼び出す
  static bool shouldRequestReview({
    required int appLaunchCount,
    required int daysUsed,
    required bool hasCompletedImportantAction,
  }) {
    // 開発中または無効なストア設定の場合はレビューをリクエストしない
    if (kDebugMode || !_isValidStoreConfiguration()) {
      return false;
    }

    // レビューリクエストの条件を定義（定数から取得）
    return appLaunchCount >= AppConstants.reviewRequestMinLaunchCount &&
           daysUsed >= AppConstants.reviewRequestMinUsageDays &&
           hasCompletedImportantAction;
  }
}