class AppConstants {
  AppConstants._();

  // Animation durations
  static const int animationDurationShort = 200;
  static const int animationDurationMedium = 300;
  static const int animationDurationLong = 500;

  // Threshold values
  static const double highCompletionRateThreshold = 0.8;
  static const int maxRewardDisplayCount = 3;
  static const int maxParticipationDisplayCount = 3;

  // Default values
  static const int defaultParticipantCount = 0;
  static const double defaultCompletionRate = 0.0;

  // Tab counts
  static const int mainTabCount = 2;
  static const int eventTypeTabCount = 4;

  // Date format patterns
  static const String dateTimePattern = 'M/d H:mm';
  static const String datePattern = 'M/d';
  static const String timePattern = 'H:mm';

  // Mock data identifiers
  static const String mockEventId1 = '1';
  static const String mockEventId2 = '2';
  static const String mockEventId3 = '3';
  static const String mockEventId4 = '4';

  // Reward type keys
  static const String coinRewardKey = 'coin';
  static const String gemRewardKey = 'gem';
  static const String expRewardKey = 'exp';
  static const String rareItemRewardKey = 'rare_item';
  static const String limitedCharacterRewardKey = 'limited_character';
  static const String trophyRewardKey = 'trophy';
  static const String titleRewardKey = 'title';

  // Time durations (in days)
  static const int dailyEventDuration = 1;
  static const int weeklyEventDuration = 7;
  static const int specialEventDuration = 7;
  static const int seasonalEventDuration = 15;

  // Network timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Cache durations (in minutes)
  static const int eventCacheDuration = 15;
  static const int analyticsCacheDuration = 30;

  // App Store configurations
  static const String iosAppStoreId = '6756296268';
  static const String androidPackageName = 'go.mobile';

  // In-app review conditions
  static const int reviewRequestMinLaunchCount = 10;
  static const int reviewRequestMinUsageDays = 3;

  // AdMob configurations
  // Flavorに応じてテスト用IDと本番用IDを切り替え
  // 注意: String.fromEnvironmentはビルド時にのみ評価される
  // --dart-define=APP_FLAVOR=prod でビルドした場合のみ本番用IDが使用される
  static const String _appFlavor = String.fromEnvironment('APP_FLAVOR', defaultValue: '');
  // APP_FLAVORが明示的に'prod'の場合のみ本番、それ以外（dev、空文字、未設定）はテスト広告を使用
  static const bool _isProduction = _appFlavor == 'prod';

  // テスト用ID（Google公式）
  static const String _admobBannerAdUnitIdIosTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _admobBannerAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/6300978111';

  // 本番用ID
  static const String _admobBannerAdUnitIdIosProd = 'ca-app-pub-7611377680432550/3765201131';
  static const String _admobBannerAdUnitIdAndroidProd = 'ca-app-pub-7611377680432550/8834614854';

  // Flavorに応じたIDを返す
  static String get admobBannerAdUnitIdIos =>
      _isProduction ? _admobBannerAdUnitIdIosProd : _admobBannerAdUnitIdIosTest;
  static String get admobBannerAdUnitIdAndroid =>
      _isProduction ? _admobBannerAdUnitIdAndroidProd : _admobBannerAdUnitIdAndroidTest;
}