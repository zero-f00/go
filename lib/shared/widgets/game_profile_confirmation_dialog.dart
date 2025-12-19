import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_profile_model.dart';
import '../../features/game_profile/providers/game_profile_provider.dart';
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
    return AlertDialog(
      title: const Text('ゲームプロフィールの確認'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '「$eventName」への申請時に以下のプロフィール情報を送信します。',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildProfileSection(ref),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          text: '編集する',
          onPressed: onEdit,
          width: 100,
        ),
        PrimaryButton(
          text: 'この内容で申請',
          onPressed: onConfirm,
          width: 140,
        ),
      ],
    );
  }

  Widget _buildProfileSection(WidgetRef ref) {
    final gameAsync = ref.watch(gameByIdProvider(gameProfile.gameId));

    return gameAsync.when(
      data: (game) => _buildProfileContent(game?.name ?? gameProfile.gameId),
      loading: () => _buildProfileContent(gameProfile.gameId),
      error: (_, __) => _buildProfileContent(gameProfile.gameId),
    );
  }

  Widget _buildProfileContent(String gameName) {
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
          _buildInfoRow('ゲーム', gameName),
          _buildInfoRow('ゲーム内ユーザー名', gameProfile.gameUsername),
          if (gameProfile.gameUserId.isNotEmpty)
            _buildInfoRow('ゲーム内ユーザーID', gameProfile.gameUserId),
          if (gameProfile.skillLevel != null)
            _buildInfoRow('スキルレベル', gameProfile.skillLevel!.displayName),
          if (gameProfile.rankOrLevel.isNotEmpty)
            _buildInfoRow('ランク・レベル', gameProfile.rankOrLevel),
          if (gameProfile.playStyles.isNotEmpty)
            _buildInfoRow(
              'プレイスタイル',
              gameProfile.playStyles.map((style) => style.displayName).join(', '),
            ),
          if (gameProfile.activityTimes.isNotEmpty)
            _buildInfoRow(
              '活動時間',
              gameProfile.activityTimes.map((time) => time.displayName).join(', '),
            ),
          _buildInfoRow(
            'ゲーム内ボイスチャット',
            gameProfile.useInGameVC ? '利用する' : '利用しない',
          ),
          if (gameProfile.voiceChatDetails.isNotEmpty)
            _buildInfoRow('ボイスチャット詳細', gameProfile.voiceChatDetails),
          if (gameProfile.achievements.isNotEmpty)
            _buildInfoRow('実績・成果', gameProfile.achievements),
          if (gameProfile.notes.isNotEmpty)
            _buildInfoRow('その他メモ', gameProfile.notes),
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