import 'package:flutter/material.dart';
import '../../data/models/game_profile_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// ゲームプロフィール確認ダイアログ
class GameProfileConfirmationDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            _buildProfileSection(),
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

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('ゲーム', gameProfile.gameId),  // TODO: gameNameをプロバイダーから取得
          _buildInfoRow('ゲーム内ユーザー名', gameProfile.gameUsername),
          if (gameProfile.gameUserId?.isNotEmpty == true)
            _buildInfoRow('ゲーム内ユーザーID', gameProfile.gameUserId!),
          if (gameProfile.experience != null)
            _buildInfoRow('経験レベル', gameProfile.experience!.displayName),
          if (gameProfile.rankOrLevel?.isNotEmpty == true)
            _buildInfoRow('ランク・レベル', gameProfile.rankOrLevel!),
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
          if (gameProfile.useInGameVC != null)
            _buildInfoRow(
              'ゲーム内ボイスチャット',
              gameProfile.useInGameVC! ? '利用する' : '利用しない',
            ),
          if (gameProfile.voiceChatDetails?.isNotEmpty == true)
            _buildInfoRow('ボイスチャット詳細', gameProfile.voiceChatDetails!),
          if (gameProfile.achievements?.isNotEmpty == true)
            _buildInfoRow('実績・成果', gameProfile.achievements!),
          if (gameProfile.notes?.isNotEmpty == true)
            _buildInfoRow('その他メモ', gameProfile.notes!),
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