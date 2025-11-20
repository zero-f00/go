import 'package:flutter/material.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_constants.dart';

class EventCard extends StatelessWidget {
  final GameEvent event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _getStatusColor(GameEventStatus status) {
    switch (status) {
      case GameEventStatus.upcoming:
        return AppColors.info;
      case GameEventStatus.active:
        return AppColors.success;
      case GameEventStatus.completed:
        return AppColors.statusCompleted;
      case GameEventStatus.expired:
        return AppColors.statusExpired;
    }
  }

  IconData _getTypeIcon(GameEventType type) {
    switch (type) {
      case GameEventType.daily:
        return Icons.today;
      case GameEventType.weekly:
        return Icons.calendar_view_week;
      case GameEventType.special:
        return Icons.star;
      case GameEventType.seasonal:
        return Icons.celebration;
    }
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case AppConstants.coinRewardKey:
        return Icons.monetization_on;
      case AppConstants.gemRewardKey:
        return Icons.diamond;
      case AppConstants.expRewardKey:
        return Icons.trending_up;
      case AppConstants.rareItemRewardKey:
        return Icons.star;
      case AppConstants.limitedCharacterRewardKey:
        return Icons.person;
      case AppConstants.trophyRewardKey:
        return Icons.emoji_events;
      case AppConstants.titleRewardKey:
        return Icons.military_tech;
      default:
        return Icons.redeem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.eventCardMarginBottom),
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
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEventHeader(),
                if (event.subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildSubtitle(),
                ],
                const SizedBox(height: AppDimensions.spacingM),
                _buildEventMeta(),
                const SizedBox(height: AppDimensions.spacingM),
                _buildEventFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (event.gameIconUrl != null)
            Container(
              width: AppDimensions.iconL,
              height: AppDimensions.iconL,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                image: DecorationImage(
                  image: NetworkImage(event.gameIconUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: AppDimensions.iconL,
              height: AppDimensions.iconL,
              decoration: BoxDecoration(
                color: AppColors.overlayMedium,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(
                Icons.videogame_asset,
                color: AppColors.textSecondary,
                size: AppDimensions.iconM,
              ),
            ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ゲーム',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS / 2),
                Text(
                  event.gameName ?? '未設定',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  _buildStatusBadge(),
                ],
              ),
              if (event.createdByName != null) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                _buildOrganizerTag(),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
          size: AppDimensions.iconM,
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(event.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: _getStatusColor(event.status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        event.status.displayName,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeXS,
          color: _getStatusColor(event.status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOrganizerTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spacingXS / 2),
          Text(
            '主催: ${event.createdByName!}',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      event.subtitle!,
      style: const TextStyle(
        fontSize: AppDimensions.fontSizeM,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEventMeta() {
    return Column(
      children: [
        if (event.gameName != null) ...[
          _buildGameInfo(),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        Row(
          children: [
            if (event.hasFee)
              _buildFeeChip()
            else
              _buildMetaChip(
                '無料',
                Icons.free_breakfast,
                AppColors.success,
              ),
            const SizedBox(width: AppDimensions.spacingS),
            if (event.rewards.isNotEmpty)
              _buildPrizeChip(),
            const Spacer(),
            _buildParticipantInfo(),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeChip() {
    String label = '有料';
    if (event.feeAmount != null && event.feeAmount! > 0) {
      if (event.feeAmount! >= 1000) {
        label = '¥${(event.feeAmount! / 1000).toStringAsFixed(event.feeAmount! % 1000 == 0 ? 0 : 1)}k';
      } else {
        label = '¥${event.feeAmount!.toInt()}';
      }
    }

    return _buildMetaChip(
      label,
      Icons.paid,
      AppColors.warning,
    );
  }

  Widget _buildPrizeChip() {
    String label = '賞品あり';

    // 賞品の種類を確認して適切なアイコンとラベルを設定
    if (event.rewards.containsKey('coin')) {
      final amount = event.rewards['coin']!;
      label = amount >= 1000 ? '${(amount / 1000).toInt()}kコイン' : '${amount.toInt()}コイン';
    } else if (event.rewards.containsKey('gem')) {
      label = '${event.rewards['gem']!.toInt()}ジェム';
    } else if (event.rewards.containsKey('exp')) {
      final amount = event.rewards['exp']!;
      label = amount >= 1000 ? '${(amount / 1000).toInt()}k経験値' : '${amount.toInt()}経験値';
    }

    return _buildMetaChip(
      label,
      Icons.emoji_events,
      AppColors.accent,
    );
  }

  Widget _buildMetaChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantInfo() {
    return Row(
      children: [
        Icon(
          Icons.group,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '${event.participantCount}/${event.maxParticipants}人',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEventFooter() {
    final dateFormat = '${event.startDate.month}/${event.startDate.day}';
    final timeFormat = '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '開催日時: $dateFormat $timeFormat',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.statContainerPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconS),
          const SizedBox(width: AppDimensions.spacingS / 1.5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventPeriod() {
    final startDate = event.startDate;
    final endDate = event.endDate;
    final now = DateTime.now();

    String periodText;
    Color periodColor;
    IconData periodIcon;

    switch (event.status) {
      case GameEventStatus.upcoming:
        final daysUntilStart = startDate.difference(now).inDays;
        periodText = daysUntilStart > 0
            ? '開始まで$daysUntilStart日'
            : '間もなく開始';
        periodColor = AppColors.info;
        periodIcon = Icons.schedule;
        break;
      case GameEventStatus.active:
        final daysRemaining = endDate.difference(now).inDays;
        periodText = daysRemaining > 0
            ? '残り$daysRemaining日'
            : '本日終了';
        periodColor = AppColors.success;
        periodIcon = Icons.timelapse;
        break;
      case GameEventStatus.completed:
        periodText = '終了済み';
        periodColor = AppColors.statusCompleted;
        periodIcon = Icons.check_circle;
        break;
      case GameEventStatus.expired:
        periodText = '期限切れ';
        periodColor = AppColors.statusExpired;
        periodIcon = Icons.cancel;
        break;
    }

    final dateFormat = '${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.statContainerPadding),
      decoration: BoxDecoration(
        color: periodColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        children: [
          Icon(periodIcon, color: periodColor, size: AppDimensions.iconS),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodText,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: periodColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dateFormat,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: periodColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardIndicators() {
    return Wrap(
      spacing: AppDimensions.spacingS / 1.5,
      runSpacing: AppDimensions.spacingS / 1.5,
      children: event.rewards.entries
          .take(AppConstants.maxRewardDisplayCount)
          .map((reward) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.rewardIndicatorPadding,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRewardIcon(reward.key),
                size: AppDimensions.fontSizeS,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                '${reward.value.round()}',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}