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
}