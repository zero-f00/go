import 'package:flutter/material.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'event_card.dart';

/// 管理者向けイベントカードラッパー
/// EventCardの上部に公開状態を表示
class ManagementEventCardWrapper extends StatelessWidget {
  final GameEvent event;
  final VoidCallback onTap;

  const ManagementEventCardWrapper({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildManagementHeader(),
        EventCard(
          event: event,
          onTap: onTap,
        ),
      ],
    );
  }

  /// 管理者向けヘッダー情報（公開状態のみ）
  Widget _buildManagementHeader() {
    return Container(
      margin: const EdgeInsets.only(
        left: AppDimensions.spacingM,
        right: AppDimensions.spacingM,
        bottom: AppDimensions.spacingS,
      ),
      child: Row(
        children: [
          _buildPublishStatusBadge(),
          const SizedBox(width: AppDimensions.spacingM),
          _buildVisibilityBadge(),
        ],
      ),
    );
  }

  /// 公開状態バッジ（公開中/下書き/予約公開）
  Widget _buildPublishStatusBadge() {
    final publishStatus = _getPublishStatus();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: publishStatus.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        boxShadow: [
          BoxShadow(
            color: publishStatus.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            publishStatus.icon,
            size: 14,
            color: AppColors.textWhite,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            publishStatus.label,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// 可視性バッジ（限定公開の場合のみ表示）
  Widget _buildVisibilityBadge() {
    // 限定公開の場合のみバッジを表示
    if (event.visibility == '限定公開') {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: AppColors.textWhite,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              '限定',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }


  /// 公開状態情報を取得
  ({String label, IconData icon, Color color}) _getPublishStatus() {
    // visibilityフィールドで公開状態を判定
    // プライベート = 下書き
    // パブリック = 公開中
    // 限定公開 = 限定公開（公開中と同じ扱い）

    if (event.visibility == 'プライベート' || event.visibility.isEmpty) {
      // 下書き状態
      return (
        label: '下書き',
        icon: Icons.drafts,
        color: AppColors.warning,
      );
    }

    // パブリックまたは限定公開の場合はイベントステータスで判定
    switch (event.status) {
      case GameEventStatus.upcoming:
        // 開催予定だが公開されている
        return (
          label: '公開中',
          icon: Icons.public,
          color: AppColors.success,
        );
      case GameEventStatus.active:
        // 開催中
        return (
          label: '開催中',
          icon: Icons.play_circle_filled,
          color: AppColors.success,
        );
      case GameEventStatus.completed:
      case GameEventStatus.expired:
        // 終了済み
        return (
          label: '終了',
          icon: Icons.event_busy,
          color: AppColors.textSecondary,
        );
      case GameEventStatus.cancelled:
        // 中止
        return (
          label: '中止',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
        );
    }
  }

}