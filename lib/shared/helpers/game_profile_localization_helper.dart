import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart' show L10n;
import '../../data/models/game_profile_model.dart';

/// ゲームプロフィール関連のローカライズヘルパー
class GameProfileLocalizationHelper {
  /// スキルレベルのローカライズされた表示名を取得
  static String getSkillLevelDisplayName(BuildContext context, SkillLevel level) {
    final l10n = L10n.of(context);
    switch (level) {
      case SkillLevel.beginner:
        return l10n.skillLevelBeginner;
      case SkillLevel.intermediate:
        return l10n.skillLevelIntermediate;
      case SkillLevel.advanced:
        return l10n.skillLevelAdvanced;
      case SkillLevel.expert:
        return l10n.skillLevelExpert;
    }
  }

  /// スキルレベルのローカライズされた説明を取得
  static String getSkillLevelDescription(BuildContext context, SkillLevel level) {
    final l10n = L10n.of(context);
    switch (level) {
      case SkillLevel.beginner:
        return l10n.skillLevelBeginnerDescription;
      case SkillLevel.intermediate:
        return l10n.skillLevelIntermediateDescription;
      case SkillLevel.advanced:
        return l10n.skillLevelAdvancedDescription;
      case SkillLevel.expert:
        return l10n.skillLevelExpertDescription;
    }
  }

  /// プレイスタイルのローカライズされた表示名を取得
  static String getPlayStyleDisplayName(BuildContext context, PlayStyle style) {
    final l10n = L10n.of(context);
    switch (style) {
      case PlayStyle.casual:
        return l10n.playStyleCasual;
      case PlayStyle.competitive:
        return l10n.playStyleCompetitive;
      case PlayStyle.cooperative:
        return l10n.playStyleCooperative;
      case PlayStyle.solo:
        return l10n.playStyleSolo;
      case PlayStyle.social:
        return l10n.playStyleSocial;
      case PlayStyle.speedrun:
        return l10n.playStyleSpeedrun;
      case PlayStyle.collector:
        return l10n.playStyleCollector;
    }
  }

  /// プレイスタイルのローカライズされた説明を取得
  static String getPlayStyleDescription(BuildContext context, PlayStyle style) {
    final l10n = L10n.of(context);
    switch (style) {
      case PlayStyle.casual:
        return l10n.playStyleCasualDescription;
      case PlayStyle.competitive:
        return l10n.playStyleCompetitiveDescription;
      case PlayStyle.cooperative:
        return l10n.playStyleCooperativeDescription;
      case PlayStyle.solo:
        return l10n.playStyleSoloDescription;
      case PlayStyle.social:
        return l10n.playStyleSocialDescription;
      case PlayStyle.speedrun:
        return l10n.playStyleSpeedrunDescription;
      case PlayStyle.collector:
        return l10n.playStyleCollectorDescription;
    }
  }

  /// 活動時間帯のローカライズされた表示名を取得
  static String getActivityTimeDisplayName(BuildContext context, ActivityTime time) {
    final l10n = L10n.of(context);
    switch (time) {
      case ActivityTime.morning:
        return l10n.activityTimeMorning;
      case ActivityTime.afternoon:
        return l10n.activityTimeAfternoon;
      case ActivityTime.evening:
        return l10n.activityTimeEvening;
      case ActivityTime.night:
        return l10n.activityTimeNight;
      case ActivityTime.weekend:
        return l10n.activityTimeWeekend;
      case ActivityTime.weekday:
        return l10n.activityTimeWeekday;
    }
  }

}
