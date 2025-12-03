import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../services/violation_service.dart';
import '../../data/models/game_profile_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/violation_record_model.dart';

/// 参加者のゲームプロフィールを表示するカード
/// イベント管理画面で使用する簡潔な表示形式
class ParticipantProfileCard extends StatelessWidget {
  final GameProfile profile;
  final UserData? userData;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap; // ユーザープロフィールアクセス用
  final ParticipationStatus status;
  final List<ViolationRecord>? violations; // 違反履歴
  final ViolationRiskLevel? riskLevel; // リスクレベル

  const ParticipantProfileCard({
    super.key,
    required this.profile,
    this.userData,
    this.onTap,
    this.onUserTap,
    this.status = ParticipationStatus.pending,
    this.violations,
    this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      elevation: 2.0,
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onUserTap, // ユーザープロフィール表示に変更
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingM),
              _buildProfileSummary(),
              if (violations != null && violations!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildViolationInfo(),
              ],
              const SizedBox(height: AppDimensions.spacingM),
              _buildStatusAndActions(),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分（アバター、ゲーム内ユーザー名、ランク）
  Widget _buildHeader() {
    return Row(
      children: [
        // アバター（タップでゲームプロフィール表示）
        InkWell(
          onTap: onTap, // ゲームプロフィール表示に変更
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
            backgroundImage: userData?.photoUrl != null
                ? NetworkImage(userData!.photoUrl!)
                : null,
            child: userData?.photoUrl == null
                ? Text(
                    profile.gameUsername.isNotEmpty
                        ? profile.gameUsername.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingL),

        // メイン情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ゲーム内ユーザー名
              Text(
                profile.gameUsername,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingXS),

              // ユーザー名（リアル）
              if (userData?.username != null)
                Text(
                  userData!.username,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

              // ランク/レベル
              if (profile.rankOrLevel.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingS,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    profile.rankOrLevel,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ステータスアイコン
        _buildStatusIcon(),
      ],
    );
  }

  /// プロフィール要約
  Widget _buildProfileSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ゲーム歴とプレイスタイル
        if (profile.summary.isNotEmpty) ...[
          Text(
            'プロフィール',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            profile.summary,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
            ),
          ),
        ],

        // ボイスチャット情報
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          children: [
            Icon(
              profile.useInGameVC ? Icons.mic : Icons.mic_off,
              size: AppDimensions.iconS,
              color: profile.useInGameVC ? AppColors.success : AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              profile.useInGameVC ? 'ボイスチャット対応' : 'ボイスチャット不使用',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: profile.useInGameVC ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ステータスとアクション
  Widget _buildStatusAndActions() {
    return Row(
      children: [
        // 参加ステータス
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status.icon,
                size: AppDimensions.iconS,
                color: status.color,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                status.displayName,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // タップアクション
        Icon(
          Icons.arrow_forward_ios,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  /// ステータスアイコン
  Widget _buildStatusIcon() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingXS),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        status.icon,
        size: AppDimensions.iconS,
        color: status.color,
      ),
    );
  }

  /// 違反情報表示
  Widget _buildViolationInfo() {
    final violationCount = violations?.length ?? 0;
    final resolvedCount = violations?.where((v) => v.status == ViolationStatus.resolved).length ?? 0;
    final pendingCount = violations?.where((v) => v.status == ViolationStatus.pending || v.status == ViolationStatus.underReview).length ?? 0;

    // リスクレベルに応じた色を設定
    Color riskColor = AppColors.success;
    IconData riskIcon = Icons.check_circle;
    String riskText = 'リスクなし';

    if (riskLevel != null) {
      switch (riskLevel!) {
        case ViolationRiskLevel.none:
          riskColor = AppColors.success;
          riskIcon = Icons.check_circle;
          riskText = riskLevel!.displayName;
          break;
        case ViolationRiskLevel.low:
          riskColor = AppColors.info;
          riskIcon = Icons.info;
          riskText = riskLevel!.displayName;
          break;
        case ViolationRiskLevel.medium:
          riskColor = AppColors.warning;
          riskIcon = Icons.warning;
          riskText = riskLevel!.displayName;
          break;
        case ViolationRiskLevel.high:
          riskColor = AppColors.error;
          riskIcon = Icons.error;
          riskText = riskLevel!.displayName;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: AppDimensions.iconS),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '違反履歴',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  riskText,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              _buildViolationStat('合計', violationCount, AppColors.textDark),
              const SizedBox(width: AppDimensions.spacingL),
              _buildViolationStat('処理済み', resolvedCount, AppColors.success),
              const SizedBox(width: AppDimensions.spacingL),
              _buildViolationStat('未処理', pendingCount, AppColors.warning),
            ],
          ),
          if (violations != null && violations!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              '最新: ${violations!.first.violationType.displayName} (${_formatDate(violations!.first.reportedAt)})',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViolationStat(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeXS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '$count件',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeXS,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

/// ParticipationStatus拡張 (participation_service.dartのenumに対する拡張)
extension ParticipationStatusExtension on ParticipationStatus {
  String get displayName {
    switch (this) {
      case ParticipationStatus.pending:
        return '承認待ち';
      case ParticipationStatus.approved:
        return '承認済み';
      case ParticipationStatus.rejected:
        return '拒否';
    }
  }

  Color get color {
    switch (this) {
      case ParticipationStatus.pending:
        return AppColors.warning;
      case ParticipationStatus.approved:
        return AppColors.success;
      case ParticipationStatus.rejected:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case ParticipationStatus.pending:
        return Icons.access_time;
      case ParticipationStatus.approved:
        return Icons.check_circle;
      case ParticipationStatus.rejected:
        return Icons.cancel;
    }
  }
}