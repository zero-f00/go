import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_profile_model.dart';
import '../../features/game_profile/providers/game_profile_provider.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// ゲームプロフィール確認ダイアログ
class GameProfileConfirmationDialog extends ConsumerWidget {
  final GameProfile gameProfile;
  final String eventName;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const GameProfileConfirmationDialog({
    super.key,
    required this.gameProfile,
    required this.eventName,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return AlertDialog(
      title: Text(l10n.gameProfileConfirmationTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.gameProfileSendMessage(eventName),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildProfileSection(ref, l10n),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          text: l10n.editButtonText,
          onPressed: onEdit,
          width: 100,
        ),
        PrimaryButton(
          text: l10n.applyWithThisContent,
          onPressed: onConfirm,
          width: 140,
        ),
      ],
    );
  }

  Widget _buildProfileSection(WidgetRef ref, L10n l10n) {
    final gameAsync = ref.watch(gameByIdProvider(gameProfile.gameId));

    return gameAsync.when(
      data: (game) => _buildProfileContent(game?.name ?? gameProfile.gameId, l10n),
      loading: () => _buildProfileContent(gameProfile.gameId, l10n),
      error: (_, __) => _buildProfileContent(gameProfile.gameId, l10n),
    );
  }

  Widget _buildProfileContent(String gameName, L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.gameLabel, gameName),
          _buildInfoRow(l10n.gameUsernameLabel, gameProfile.gameUsername),
          if (gameProfile.gameUserId.isNotEmpty)
            _buildInfoRow(l10n.gameUserIdLabel, gameProfile.gameUserId),
          if (gameProfile.skillLevel != null)
            _buildInfoRow(l10n.skillLevelLabel, gameProfile.skillLevel!.displayName),
          if (gameProfile.rankOrLevel.isNotEmpty)
            _buildInfoRow(l10n.rankLevelLabel, gameProfile.rankOrLevel),
          if (gameProfile.playStyles.isNotEmpty)
            _buildInfoRow(
              l10n.playStyleLabel,
              gameProfile.playStyles.map((style) => style.displayName).join(', '),
            ),
          if (gameProfile.activityTimes.isNotEmpty)
            _buildInfoRow(
              l10n.activityTimeLabel,
              gameProfile.activityTimes.map((time) => time.displayName).join(', '),
            ),
          _buildInfoRow(
            l10n.inGameVoiceChatLabel,
            gameProfile.useInGameVC ? l10n.useVoiceChat : l10n.notUseVoiceChat,
          ),
          if (gameProfile.voiceChatDetails.isNotEmpty)
            _buildInfoRow(l10n.voiceChatDetailsLabel, gameProfile.voiceChatDetails),
          if (gameProfile.achievements.isNotEmpty)
            _buildInfoRow(l10n.achievementsLabel, gameProfile.achievements),
          if (gameProfile.notes.isNotEmpty)
            _buildInfoRow(l10n.otherNotesLabel, gameProfile.notes),
        ],
      ),
    );
  }

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
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}