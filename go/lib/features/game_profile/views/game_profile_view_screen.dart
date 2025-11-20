import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';

/// ゲームプロフィール閲覧画面（読み取り専用）
class GameProfileViewScreen extends ConsumerWidget {
  final GameProfile profile;
  final UserData? userData;
  final String? gameName;
  final String? gameIconUrl;

  const GameProfileViewScreen({
    super.key,
    required this.profile,
    this.userData,
    this.gameName,
    this.gameIconUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'ゲームプロフィール',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
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
                      _buildCommunicationInfo(),
                      if (profile.achievements.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildAchievementsInfo(),
                      ],
                      if (profile.notes.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildNotesInfo(),
                      ],
                      const SizedBox(height: AppDimensions.spacingXL),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザーヘッダー
  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _viewUserProfile(context),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              child: Row(
                children: [
                  // ユーザーアバター
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                    backgroundImage: userData?.photoUrl != null
                        ? NetworkImage(userData!.photoUrl!)
                        : null,
                    child: userData?.photoUrl == null
                        ? Text(
                            userData?.username.isNotEmpty == true
                                ? userData!.username.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: AppDimensions.fontSizeXL,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppDimensions.spacingL),
                  // ユーザー情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData?.username ?? 'ユーザー名不明',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeXL,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (userData?.userId != null)
                          Text(
                            '@${userData!.userId}',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // タップ可能であることを示すアイコン
                  Icon(
                    Icons.arrow_forward_ios,
                    size: AppDimensions.iconS,
                    color: AppColors.textLight,
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
          if (gameName != null)
            _buildInfoRow('ゲーム名', gameName!),
          _buildInfoRow('ゲーム内ユーザー名', profile.gameUsername),
          if (profile.gameUserId.isNotEmpty)
            _buildInfoRow('ゲーム内ID', profile.gameUserId),
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
          if (profile.rankOrLevel.isNotEmpty)
            _buildInfoRow('ランク・レベル', profile.rankOrLevel),
          if (profile.experience != null)
            _buildInfoRow('ゲーム歴', profile.experience!.displayName),
        ],
      ),
    );
  }

  /// 経験・スキル情報
  Widget _buildExperienceInfo() {
    if (profile.experience == null) return const SizedBox.shrink();

    return _buildSection(
      title: '経験・スキル',
      icon: Icons.emoji_events,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge(
            profile.experience!.displayName,
            _getExperienceColor(profile.experience!),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            profile.experience!.description,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// プレイスタイル情報
  Widget _buildPlayStyleInfo() {
    if (profile.playStyles.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: 'プレイスタイル',
      icon: Icons.style,
      child: Wrap(
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: profile.playStyles.map((style) =>
          _buildBadge(style.displayName, AppColors.info)
        ).toList(),
      ),
    );
  }

  /// 活動時間情報
  Widget _buildActivityInfo() {
    if (profile.activityTimes.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: '活動時間帯',
      icon: Icons.schedule,
      child: Wrap(
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: profile.activityTimes.map((time) =>
          _buildBadge(time.displayName, AppColors.warning)
        ).toList(),
      ),
    );
  }

  /// コミュニケーション情報
  Widget _buildCommunicationInfo() {
    return _buildSection(
      title: 'コミュニケーション',
      icon: Icons.mic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                profile.useInGameVC ? Icons.mic : Icons.mic_off,
                color: profile.useInGameVC ? AppColors.success : AppColors.error,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                profile.useInGameVC ? 'ボイスチャット使用可能' : 'ボイスチャット不使用',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w500,
                  color: profile.useInGameVC ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          if (profile.voiceChatDetails.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _buildInfoRow('詳細情報', profile.voiceChatDetails),
          ],
        ],
      ),
    );
  }

  /// 実績情報
  Widget _buildAchievementsInfo() {
    return _buildSection(
      title: '実績・達成目標',
      icon: Icons.workspace_premium,
      child: Text(
        profile.achievements,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
          height: 1.5,
        ),
      ),
    );
  }

  /// メモ・備考情報
  Widget _buildNotesInfo() {
    return _buildSection(
      title: 'メモ・備考',
      icon: Icons.note,
      child: Text(
        profile.notes,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
          height: 1.5,
        ),
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
              Icon(
                icon,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
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

  /// 情報行構築ヘルパー
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// バッジ構築ヘルパー
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 経験レベル色取得
  Color _getExperienceColor(GameExperience experience) {
    switch (experience) {
      case GameExperience.beginner:
        return AppColors.info;
      case GameExperience.intermediate:
        return AppColors.warning;
      case GameExperience.advanced:
        return AppColors.success;
      case GameExperience.expert:
        return AppColors.accent;
    }
  }

  /// ユーザープロフィール表示
  void _viewUserProfile(BuildContext context) {
    if (userData?.userId != null) {
      Navigator.of(context).pushNamed(
        '/user_profile',
        arguments: userData!.userId,
      );
    }
  }
}