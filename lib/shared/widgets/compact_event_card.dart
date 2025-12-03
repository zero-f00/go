import 'package:flutter/material.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// ホーム画面専用のコンパクトなイベントカード
/// 横スクロールビューに適した高さ制限版
class CompactEventCard extends StatelessWidget {
  final GameEvent event;
  final VoidCallback onTap;

  const CompactEventCard({
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
      case GameEventStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.imageUrl != null) _buildCompactEventImage(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactHeader(),
                        const SizedBox(height: AppDimensions.spacingS),
                        _buildCompactMeta(),
                        const Spacer(),
                        _buildCompactFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactEventImage() {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              event.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.backgroundLight,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return Stack(
                    children: [
                      child,
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Container(
                  color: AppColors.backgroundLight,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: AppDimensions.spacingS,
            right: AppDimensions.spacingS,
            child: _buildCompactStatusBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: _getStatusColor(event.status),
          width: 1,
        ),
      ),
      child: Text(
        event.status.displayName,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final hasImage = event.imageUrl != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                maxLines: hasImage ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!hasImage) ...[
                const SizedBox(height: AppDimensions.spacingXS),
                _buildCompactStatusBadgeInline(),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Icon(
          Icons.chevron_right,
          color: AppColors.textLight,
          size: AppDimensions.iconS,
        ),
      ],
    );
  }

  Widget _buildCompactStatusBadgeInline() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingXS,
        vertical: 2,
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
          fontSize: 10,
          color: _getStatusColor(event.status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCompactMeta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ゲーム情報の行（アイコンとゲーム名）
        if (event.gameName != null || event.gameIconUrl != null) ...[
          Row(
            children: [
              // アイコンを大きく表示
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  color: AppColors.backgroundLight,
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
                child: event.gameIconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        child: Image.network(
                          event.gameIconUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.videogame_asset,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.backgroundLight,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.videogame_asset,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              // ゲーム名を表示
              if (event.gameName != null) ...[
                Expanded(
                  child: Text(
                    event.gameName!,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
        ],
        // メタ情報の行（賞品、参加人数）
        Row(
          children: [
            if (event.rewards.isNotEmpty) ...[
              Icon(
                Icons.emoji_events,
                size: AppDimensions.iconXS,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingXS / 2),
              Text(
                '賞品あり',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
            ],
            const Spacer(),
            Icon(
              Icons.group,
              size: AppDimensions.iconXS,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.spacingXS / 2),
            Text(
              '${event.participantCount}/${event.maxParticipants}人',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeXS,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactFooter() {
    final dateFormat = '${event.startDate.month}/${event.startDate.day}';
    final timeFormat = '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: AppDimensions.iconXS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingXS / 2),
        Expanded(
          child: Text(
            '$dateFormat $timeFormat',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

}