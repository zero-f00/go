import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../shared/helpers/game_profile_localization_helper.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';
import 'game_profile_view_screen_sns.dart';

/// ゲームプロフィールコンテンツウィジェット（Scaffold/ヘッダーなし）
/// GameProfileViewWrapperから埋め込んで使用する
class GameProfileViewContent extends StatelessWidget with GameProfileSNSMixin {
  final GameProfile profile;
  final UserData? userData;
  final String? gameName;
  final String? gameIconUrl;

  const GameProfileViewContent({
    super.key,
    required this.profile,
    this.userData,
    this.gameName,
    this.gameIconUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserHeader(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildGameInfo(l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildBasicInfo(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildExperienceInfo(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildPlayStyleInfo(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildActivityInfo(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildSocialLinksInfo(context, l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildCommunicationInfo(l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildAchievementsInfo(l10n),
        const SizedBox(height: AppDimensions.spacingL),
        _buildNotesInfo(l10n),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  /// ユーザーヘッダー
  Widget _buildUserHeader(BuildContext context, L10n l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.primary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.userInfoSection,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          InkWell(
            onTap: () => _viewUserProfile(context),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: userData?.photoUrl != null
                        ? NetworkImage(userData!.photoUrl!)
                        : null,
                    child: userData?.photoUrl == null
                        ? Text(
                            userData?.username.isNotEmpty == true
                                ? userData!.username
                                      .substring(0, 1)
                                      .toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppDimensions.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData?.username ?? l10n.usernameUnknown,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          userData?.userId != null
                              ? '@${userData!.userId}'
                              : l10n.noUserIdSet,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: AppDimensions.iconM,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ゲーム情報
  Widget _buildGameInfo(L10n l10n) {
    return _buildSection(
      title: l10n.gameInfoSection,
      icon: Icons.sports_esports,
      child: Column(
        children: [
          _buildGameNameCard(l10n),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            l10n.inGameUsername,
            profile.gameUsername.isNotEmpty ? profile.gameUsername : l10n.notSet,
            Icons.account_circle,
            l10n,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            l10n.inGameId,
            profile.gameUserId.isNotEmpty ? profile.gameUserId : l10n.notSet,
            Icons.fingerprint,
            l10n,
          ),
        ],
      ),
    );
  }

  /// ゲーム名カード（アイコン付き）
  Widget _buildGameNameCard(L10n l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          if (gameIconUrl != null) ...[
            GameIcon(
              iconUrl: gameIconUrl,
              size: 32,
              gameName: gameName ?? l10n.notSet,
            ),
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Expanded(
            child: Text(
              gameName ?? l10n.notSet,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 基本情報
  Widget _buildBasicInfo(BuildContext context, L10n l10n) {
    return _buildSection(
      title: l10n.basicInfo,
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoCard(
            l10n.rankOrLevel,
            profile.rankOrLevel.isNotEmpty ? profile.rankOrLevel : l10n.notSet,
            Icons.military_tech,
            l10n,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            l10n.gameExperience,
            profile.skillLevel != null
                ? GameProfileLocalizationHelper.getSkillLevelDisplayName(context, profile.skillLevel!)
                : l10n.notSet,
            Icons.history,
            l10n,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            l10n.clanLabel,
            profile.clan.isNotEmpty ? profile.clan : l10n.notSet,
            Icons.groups,
            l10n,
          ),
        ],
      ),
    );
  }

  /// 経験・スキル情報
  Widget _buildExperienceInfo(BuildContext context, L10n l10n) {
    return _buildSection(
      title: l10n.skillLevelSection,
      icon: Icons.emoji_events,
      child: profile.skillLevel != null
          ? _buildInfoCard(
              GameProfileLocalizationHelper.getSkillLevelDisplayName(context, profile.skillLevel!),
              GameProfileLocalizationHelper.getSkillLevelDescription(context, profile.skillLevel!),
              Icons.trending_up,
              l10n,
              backgroundColor: _getExperienceColor(
                profile.skillLevel!,
              ).withValues(alpha: 0.1),
              borderColor: _getExperienceColor(
                profile.skillLevel!,
              ).withValues(alpha: 0.3),
              iconColor: _getExperienceColor(profile.skillLevel!),
            )
          : _buildInfoCard(l10n.skillLevelSection, l10n.notSet, Icons.trending_up, l10n),
    );
  }

  /// プレイスタイル情報
  Widget _buildPlayStyleInfo(BuildContext context, L10n l10n) {
    return _buildSection(
      title: l10n.playStyleSection,
      icon: Icons.style,
      child: profile.playStyles.isNotEmpty
          ? Column(
              children: profile.playStyles.map((style) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                child: _buildInfoCard(
                  GameProfileLocalizationHelper.getPlayStyleDisplayName(context, style),
                  GameProfileLocalizationHelper.getPlayStyleDescription(context, style),
                  Icons.psychology,
                  l10n,
                  backgroundColor: AppColors.info.withValues(alpha: 0.1),
                  borderColor: AppColors.info.withValues(alpha: 0.3),
                  iconColor: AppColors.info,
                ),
              )).toList(),
            )
          : _buildInfoCard(l10n.playStyleSection, l10n.notSet, Icons.psychology, l10n),
    );
  }

  /// 活動時間情報
  Widget _buildActivityInfo(BuildContext context, L10n l10n) {
    return _buildSection(
      title: l10n.activityTimeSection,
      icon: Icons.schedule,
      child: profile.activityTimes.isNotEmpty
          ? _buildInfoCard(
              l10n.activityTimeSection,
              profile.activityTimes.map((time) => GameProfileLocalizationHelper.getActivityTimeDisplayName(context, time)).join('、'),
              Icons.access_time,
              l10n,
              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              borderColor: AppColors.warning.withValues(alpha: 0.3),
              iconColor: AppColors.warning,
            )
          : _buildInfoCard(l10n.activityTimeSection, l10n.notSet, Icons.access_time, l10n),
    );
  }

  /// SNSアカウント情報
  Widget _buildSocialLinksInfo(BuildContext context, L10n l10n) {
    return buildSocialLinksInfo(
      context: context,
      profile: profile,
      userData: userData,
      buildSection: _buildSection,
      l10n: l10n,
    );
  }

  /// コミュニケーション情報
  Widget _buildCommunicationInfo(L10n l10n) {
    return _buildSection(
      title: l10n.communicationSection,
      icon: Icons.mic,
      child: Column(
        children: [
          _buildInfoCard(
            l10n.voiceChat,
            profile.useInGameVC ? l10n.vcUsable : l10n.vcNotUsable,
            profile.useInGameVC ? Icons.mic : Icons.mic_off,
            l10n,
            backgroundColor: profile.useInGameVC
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderColor: profile.useInGameVC
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
            iconColor: profile.useInGameVC
                ? AppColors.success
                : AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            l10n.vcDetailsSection,
            profile.voiceChatDetails.isNotEmpty
                ? profile.voiceChatDetails
                : l10n.notSet,
            Icons.settings_voice,
            l10n,
          ),
        ],
      ),
    );
  }

  /// 実績情報
  Widget _buildAchievementsInfo(L10n l10n) {
    return _buildSection(
      title: l10n.achievementsGoals,
      icon: Icons.workspace_premium,
      child: _buildInfoCard(
        l10n.achievementsGoals,
        profile.achievements.isNotEmpty ? profile.achievements : l10n.notSet,
        Icons.emoji_events,
        l10n,
        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
        borderColor: AppColors.accent.withValues(alpha: 0.3),
        iconColor: AppColors.accent,
      ),
    );
  }

  /// メモ・備考情報
  Widget _buildNotesInfo(L10n l10n) {
    return _buildSection(
      title: l10n.notesSection,
      icon: Icons.note,
      child: _buildInfoCard(
        l10n.notesSection,
        profile.notes.isNotEmpty ? profile.notes : l10n.notSet,
        Icons.note_alt,
        l10n,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        iconColor: AppColors.primary,
      ),
    );
  }

  /// セクション構築ヘルパー
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: AppDimensions.iconM),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          child,
        ],
      ),
    );
  }

  /// 情報カード構築ヘルパー
  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    L10n l10n, {
    Color? backgroundColor,
    Color? borderColor,
    Color? iconColor,
  }) {
    final bool isNotSet = value == l10n.notSet;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color:
              borderColor ??
              (isNotSet
                  ? AppColors.border
                  : AppColors.accent.withValues(alpha: 0.3)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.accent).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              icon,
              color:
                  iconColor ??
                  (isNotSet ? AppColors.textLight : AppColors.accent),
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color:
                        iconColor ??
                        (isNotSet ? AppColors.textLight : AppColors.accent),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: isNotSet ? AppColors.textLight : AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// スキルレベル色取得
  Color _getExperienceColor(SkillLevel skillLevel) {
    switch (skillLevel) {
      case SkillLevel.beginner:
        return AppColors.info;
      case SkillLevel.intermediate:
        return AppColors.warning;
      case SkillLevel.advanced:
        return AppColors.success;
      case SkillLevel.expert:
        return AppColors.accent;
    }
  }

  /// ユーザープロフィール表示
  void _viewUserProfile(BuildContext context) {
    if (userData?.userId != null) {
      Navigator.of(
        context,
      ).pushNamed('/user_profile', arguments: userData!.userId);
    }
  }
}
