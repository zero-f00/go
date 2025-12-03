import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// 標準的なイベントカード（Event モデル用）
class StandardEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const StandardEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return AppColors.textSecondary;
      case EventStatus.scheduled:
        return AppColors.info;
      case EventStatus.published:
        return AppColors.success;
      case EventStatus.cancelled:
        return AppColors.error;
      case EventStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return '下書き';
      case EventStatus.scheduled:
        return '予約公開';
      case EventStatus.published:
        return '公開中';
      case EventStatus.cancelled:
        return '中止';
      case EventStatus.completed:
        return '完了';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: event.status == EventStatus.cancelled
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
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
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(),
                if (event.subtitle != null) ...[
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildSubtitle(),
                ],
                const SizedBox(height: AppDimensions.spacingM),
                if (event.status == EventStatus.cancelled)
                  _buildCancellationInfo(),
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
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: event.status == EventStatus.cancelled
                            ? AppColors.textSecondary
                            : AppColors.textDark,
                        decoration: event.status == EventStatus.cancelled
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  _buildStatusBadge(),
                ],
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
          size: AppDimensions.iconM,
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(event.status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getStatusText(event.status),
        style: TextStyle(
          fontSize: AppDimensions.fontSizeXS,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      event.subtitle!,
      style: TextStyle(
        fontSize: AppDimensions.fontSizeM,
        color: event.status == EventStatus.cancelled
            ? AppColors.textLight
            : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        decoration: event.status == EventStatus.cancelled
            ? TextDecoration.lineThrough
            : TextDecoration.none,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCancellationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: AppColors.error,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Expanded(
                child: Text(
                  'このイベントは中止されました',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (event.cancellationReason != null && event.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              '理由: ${event.cancellationReason}',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (event.cancelledAt != null) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              '中止日: ${event.cancelledAt!.month}/${event.cancelledAt!.day}',
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

  Widget _buildEventMeta() {
    return Row(
      children: [
        if (event.hasParticipationFee) ...[
          _buildMetaChip(
            '有料',
            Icons.paid,
            AppColors.warning,
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ] else ...[
          _buildMetaChip(
            '無料',
            Icons.free_breakfast,
            AppColors.success,
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        if (event.hasPrize) ...[
          _buildMetaChip(
            '賞品あり',
            Icons.emoji_events,
            AppColors.accent,
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        const Spacer(),
        _buildParticipantInfo(),
      ],
    );
  }

  Widget _buildMetaChip(String label, IconData icon, Color color) {
    final chipColor = event.status == EventStatus.cancelled
        ? AppColors.textSecondary
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS,
            color: chipColor,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantInfo() {
    final participantColor = event.status == EventStatus.cancelled
        ? AppColors.textLight
        : AppColors.textSecondary;

    return Row(
      children: [
        Icon(
          Icons.group,
          size: AppDimensions.iconS,
          color: participantColor,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '${event.participantIds.length}/${event.maxParticipants}人',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            fontWeight: FontWeight.w600,
            color: participantColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEventFooter() {
    final date = event.eventDate;
    final dateFormat = '${date.month}/${date.day}';
    final timeFormat = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final footerColor = event.status == EventStatus.cancelled
        ? AppColors.textLight
        : AppColors.textSecondary;

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: AppDimensions.iconS,
          color: footerColor,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          '開催日時: $dateFormat $timeFormat',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: footerColor,
            fontWeight: FontWeight.w500,
            decoration: event.status == EventStatus.cancelled
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
      ],
    );
  }
}