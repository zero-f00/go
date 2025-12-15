import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUserHeader(context),
        const SizedBox(height: AppDimensions.spacingL),
        _buildGameInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildBasicInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildExperienceInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildPlayStyleInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildActivityInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildSocialLinksInfo(context),
        const SizedBox(height: AppDimensions.spacingL),
        _buildCommunicationInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildAchievementsInfo(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildNotesInfo(),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  /// ユーザーヘッダー
  Widget _buildUserHeader(BuildContext context) {
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
                'ユーザー情報',
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
                          userData?.username ?? 'ユーザー名不明',
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
                              : 'ユーザーIDなし',
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
  Widget _buildGameInfo() {
    return _buildSection(
      title: 'ゲーム情報',
      icon: Icons.sports_esports,
      child: Column(
        children: [
          _buildGameNameCard(),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            'ゲーム内ユーザー名',
            profile.gameUsername.isNotEmpty ? profile.gameUsername : '未設定',
            Icons.account_circle,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            'ゲーム内ID',
            profile.gameUserId.isNotEmpty ? profile.gameUserId : '未設定',
            Icons.fingerprint,
          ),
        ],
      ),
    );
  }

  /// ゲーム名カード（アイコン付き）
  Widget _buildGameNameCard() {
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
              gameName: gameName ?? '未設定',
            ),
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Expanded(
            child: Text(
              gameName ?? '未設定',
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
  Widget _buildBasicInfo() {
    return _buildSection(
      title: '基本情報',
      icon: Icons.person,
      child: Column(
        children: [
          _buildInfoCard(
            'ランク・レベル',
            profile.rankOrLevel.isNotEmpty ? profile.rankOrLevel : '未設定',
            Icons.military_tech,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            'ゲーム歴',
            profile.skillLevel?.displayName ?? '未設定',
            Icons.history,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoCard(
            'クラン',
            profile.clan.isNotEmpty ? profile.clan : '未設定',
            Icons.groups,
          ),
        ],
      ),
    );
  }

  /// 経験・スキル情報
  Widget _buildExperienceInfo() {
    return _buildSection(
      title: '経験・スキル',
      icon: Icons.emoji_events,
      child: profile.skillLevel != null
          ? _buildInfoCard(
              '経験レベル',
              '${profile.skillLevel!.displayName}\n${profile.skillLevel!.description}',
              Icons.trending_up,
              backgroundColor: _getExperienceColor(
                profile.skillLevel!,
              ).withValues(alpha: 0.1),
              borderColor: _getExperienceColor(
                profile.skillLevel!,
              ).withValues(alpha: 0.3),
              iconColor: _getExperienceColor(profile.skillLevel!),
            )
          : _buildInfoCard('経験レベル', '未設定', Icons.trending_up),
    );
  }

  /// プレイスタイル情報
  Widget _buildPlayStyleInfo() {
    return _buildSection(
      title: 'プレイスタイル',
      icon: Icons.style,
      child: profile.playStyles.isNotEmpty
          ? _buildInfoCard(
              'プレイスタイル',
              profile.playStyles.map((style) => style.displayName).join('、'),
              Icons.psychology,
              backgroundColor: AppColors.info.withValues(alpha: 0.1),
              borderColor: AppColors.info.withValues(alpha: 0.3),
              iconColor: AppColors.info,
            )
          : _buildInfoCard('プレイスタイル', '未設定', Icons.psychology),
    );
  }

  /// 活動時間情報
  Widget _buildActivityInfo() {
    return _buildSection(
      title: '活動時間帯',
      icon: Icons.schedule,
      child: profile.activityTimes.isNotEmpty
          ? _buildInfoCard(
              '活動時間帯',
              profile.activityTimes.map((time) => time.displayName).join('、'),
              Icons.access_time,
              backgroundColor: AppColors.warning.withValues(alpha: 0.1),
              borderColor: AppColors.warning.withValues(alpha: 0.3),
              iconColor: AppColors.warning,
            )
          : _buildInfoCard('活動時間帯', '未設定', Icons.access_time),
    );
  }

  /// SNSアカウント情報
  Widget _buildSocialLinksInfo(BuildContext context) {
    return buildSocialLinksInfo(
      context: context,
      profile: profile,
      userData: userData,
      buildSection: _buildSection,
    );
  }

  /// コミュニケーション情報
  Widget _buildCommunicationInfo() {
    return _buildSection(
      title: 'コミュニケーション',
      icon: Icons.mic,
      child: Column(
        children: [
          _buildInfoCard(
            'ボイスチャット',
            profile.useInGameVC ? 'ボイスチャット使用可能' : 'ボイスチャット不使用',
            profile.useInGameVC ? Icons.mic : Icons.mic_off,
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
            'ボイスチャット詳細',
            profile.voiceChatDetails.isNotEmpty
                ? profile.voiceChatDetails
                : '未設定',
            Icons.settings_voice,
          ),
        ],
      ),
    );
  }

  /// 実績情報
  Widget _buildAchievementsInfo() {
    return _buildSection(
      title: '実績・達成目標',
      icon: Icons.workspace_premium,
      child: _buildInfoCard(
        '実績・達成目標',
        profile.achievements.isNotEmpty ? profile.achievements : '未設定',
        Icons.emoji_events,
        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
        borderColor: AppColors.accent.withValues(alpha: 0.3),
        iconColor: AppColors.accent,
      ),
    );
  }

  /// メモ・備考情報
  Widget _buildNotesInfo() {
    return _buildSection(
      title: 'メモ・備考',
      icon: Icons.note,
      child: _buildInfoCard(
        'メモ・備考',
        profile.notes.isNotEmpty ? profile.notes : '未設定',
        Icons.note_alt,
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
    IconData icon, {
    Color? backgroundColor,
    Color? borderColor,
    Color? iconColor,
  }) {
    final bool isNotSet = value == '未設定';
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
