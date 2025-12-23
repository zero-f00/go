import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// AdMob広告管理サービス
class AdMobService {
  static bool _isInitialized = false;

  /// AdMob SDKを初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    if (kDebugMode) {
      print('AdMob: SDK initialized');
    }
  }

  /// バナー広告のユニットIDを取得
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return AppConstants.admobBannerAdUnitIdIos;
    } else if (Platform.isAndroid) {
      return AppConstants.admobBannerAdUnitIdAndroid;
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// バナー広告を作成
  static BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (ad) {
          if (kDebugMode) {
            print('AdMob: Banner ad opened');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            print('AdMob: Banner ad closed');
          }
        },
      ),
    );
  }
}
