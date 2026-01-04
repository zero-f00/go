import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../services/violation_service.dart';
import '../utils/withdrawn_user_helper.dart';
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
    final l10n = L10n.of(context);
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
              _buildHeader(context),
              const SizedBox(height: AppDimensions.spacingM),
              _buildProfileSummary(l10n),
              if (violations != null && violations!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildViolationInfo(l10n),
              ],
              const SizedBox(height: AppDimensions.spacingM),
              _buildStatusAndActions(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分（アバター、ゲーム内ユーザー名、ランク）
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // アバター（タップでゲームプロフィール表示）
        InkWell(
          onTap: onTap, // ゲームプロフィール表示に変更
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.accent.withValues(alpha: 0.1),
            backgroundImage: WithdrawnUserHelper.getDisplayAvatarUrl(userData) != null
                ? NetworkImage(WithdrawnUserHelper.getDisplayAvatarUrl(userData)!)
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
                  WithdrawnUserHelper.getDisplayUsername(context, userData),
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
  Widget _buildProfileSummary(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ゲーム歴とプレイスタイル
        if (profile.summary.isNotEmpty) ...[
          Text(
            l10n.participantProfileLabel,
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
              profile.useInGameVC ? l10n.voiceChatAvailable : l10n.voiceChatNotUsed,
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
  Widget _buildStatusAndActions(L10n l10n) {
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
                _getStatusDisplayName(l10n, status),
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

  /// 参加ステータスの表示名を取得
  String _getStatusDisplayName(L10n l10n, ParticipationStatus status) {
    switch (status) {
      case ParticipationStatus.pending:
        return l10n.participationStatusPending;
      case ParticipationStatus.waitlisted:
        return l10n.participationStatusWaitlisted;
      case ParticipationStatus.approved:
        return l10n.participationStatusApproved;
      case ParticipationStatus.rejected:
        return l10n.participationStatusRejected;
      case ParticipationStatus.cancelled:
        return l10n.participationStatusCancelled;
    }
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
  Widget _buildViolationInfo(L10n l10n) {
    final violationCount = violations?.length ?? 0;
    final resolvedCount = violations?.where((v) => v.status == ViolationStatus.resolved).length ?? 0;
    final pendingCount = violations?.where((v) => v.status == ViolationStatus.pending || v.status == ViolationStatus.underReview).length ?? 0;

    // リスクレベルに応じた色を設定
    Color riskColor = AppColors.success;
    IconData riskIcon = Icons.check_circle;
    String riskText = l10n.violationRiskNone;

    if (riskLevel != null) {
      switch (riskLevel!) {
        case ViolationRiskLevel.none:
          riskColor = AppColors.success;
          riskIcon = Icons.check_circle;
          riskText = l10n.violationRiskNone;
          break;
        case ViolationRiskLevel.low:
          riskColor = AppColors.info;
          riskIcon = Icons.info;
          riskText = l10n.violationRiskLow;
          break;
        case ViolationRiskLevel.medium:
          riskColor = AppColors.warning;
          riskIcon = Icons.warning;
          riskText = l10n.violationRiskMedium;
          break;
        case ViolationRiskLevel.high:
          riskColor = AppColors.error;
          riskIcon = Icons.error;
          riskText = l10n.violationRiskHigh;
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
                l10n.violationHistoryLabel,
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
              _buildViolationStat(l10n.violationStatTotal, violationCount, AppColors.textDark, l10n),
              const SizedBox(width: AppDimensions.spacingL),
              _buildViolationStat(l10n.violationStatResolved, resolvedCount, AppColors.success, l10n),
              const SizedBox(width: AppDimensions.spacingL),
              _buildViolationStat(l10n.violationStatPending, pendingCount, AppColors.warning, l10n),
            ],
          ),
          if (violations != null && violations!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.violationLatest(violations!.first.violationType.displayName, _formatDate(violations!.first.reportedAt)),
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

  Widget _buildViolationStat(String label, int count, Color color, L10n l10n) {
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
          l10n.violationStatCount(count),
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
  Color get color {
    switch (this) {
      case ParticipationStatus.pending:
        return AppColors.warning;
      case ParticipationStatus.waitlisted:
        return AppColors.warning;
      case ParticipationStatus.approved:
        return AppColors.success;
      case ParticipationStatus.rejected:
        return AppColors.error;
      case ParticipationStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case ParticipationStatus.pending:
        return Icons.access_time;
      case ParticipationStatus.waitlisted:
        return Icons.queue;
      case ParticipationStatus.approved:
        return Icons.check_circle;
      case ParticipationStatus.rejected:
        return Icons.cancel;
      case ParticipationStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}