import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../constants/app_constants.dart';

class EventDetailDialog extends StatelessWidget {
  final GameEvent event;

  const EventDetailDialog({
    super.key,
    required this.event,
  });

  static void show(BuildContext context, GameEvent event) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EventDetailDialog(event: event),
    );
  }

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
        return AppColors.warning;
      case GameEventStatus.draft:
        return AppColors.textSecondary;
      case GameEventStatus.published:
        return AppColors.success;
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventInfo(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildPeriodInfo(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildStatisticsInfo(),
                    if (event.rewards.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildRewardsInfo(),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'イベント詳細',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          if (event.gameName != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _buildGameHeader(),
          ],
        ],
      ),
    );
  }

  Widget _buildGameHeader() {
    return Row(
      children: [
        if (event.gameIconUrl != null)
          Container(
            width: AppDimensions.iconXL,
            height: AppDimensions.iconXL,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              image: DecorationImage(
                image: NetworkImage(event.gameIconUrl!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: AppDimensions.iconXL,
            height: AppDimensions.iconXL,
            decoration: BoxDecoration(
              color: AppColors.overlayMedium,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.videogame_asset,
              color: AppColors.textSecondary,
              size: AppDimensions.iconL,
            ),
          ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.gameName ?? '未設定',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'ゲーム',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                _getTypeIcon(event.type),
                color: _getStatusColor(event.status),
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
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
                        ),
                      ),
                      if (event.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingS,
                            vertical: AppDimensions.spacingXS / 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppDimensions.spacingM / 2),
                          ),
                          child: const Text(
                            AppStrings.premiumLabel,
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: AppDimensions.fontSizeXS,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingXS / 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.type.displayName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: _getStatusColor(event.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: _getStatusColor(event.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(
                          event.status.displayName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: _getStatusColor(event.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          event.description,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodInfo() {
    // ロケール対応のDateFormat作成
    DateFormat dateFormat;
    try {
      dateFormat = DateFormat('yyyy年M月d日 H:mm', 'ja_JP');
    } catch (e) {
      // フォールバック: デフォルトロケール使用
      dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    }
    final now = DateTime.now();
    final daysRemaining = event.status == GameEventStatus.active
        ? event.endDate.difference(now).inDays
        : null;
    final daysUntilStart = event.status == GameEventStatus.upcoming
        ? event.startDate.difference(now).inDays
        : null;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'イベント期間',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '開始',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      dateFormat.format(event.startDate),
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '終了',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      dateFormat.format(event.endDate),
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
          if (daysRemaining != null || daysUntilStart != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    event.status == GameEventStatus.active
                        ? Icons.timelapse
                        : Icons.schedule,
                    color: _getStatusColor(event.status),
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    daysRemaining != null
                        ? daysRemaining > 0
                            ? '残り$daysRemaining日'
                            : '本日終了'
                        : daysUntilStart! > 0
                            ? '開始まで$daysUntilStart日'
                            : '間もなく開始',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: _getStatusColor(event.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '統計情報',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  AppStrings.participantCount,
                  '${event.participantCount}${AppStrings.peopleUnit}',
                  Icons.people,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: _buildStatItem(
                  AppStrings.completionRate,
                  '${(event.completionRate * 100).round()}${AppStrings.percentUnit}',
                  Icons.trending_up,
                  event.completionRate > AppConstants.highCompletionRateThreshold
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconM),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.redeem,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '報酬',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Wrap(
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingM,
            children: event.rewards.entries.map((reward) {
              return Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getRewardIcon(reward.key),
                      size: AppDimensions.iconL,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      reward.key,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${reward.value.round()}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text(
                '閉じる',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // TODO: ステータスに応じた操作の実装
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
              ),
              child: Text(
                _getActionButtonText(),
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText() {
    switch (event.status) {
      case GameEventStatus.upcoming:
        return '編集';
      case GameEventStatus.active:
        return '参加';
      case GameEventStatus.completed:
        return '結果確認';
      case GameEventStatus.expired:
        return '複製';
      case GameEventStatus.cancelled:
        return '再開';
      case GameEventStatus.draft:
        return '編集';
      case GameEventStatus.published:
        return '参加';
    }
  }
}