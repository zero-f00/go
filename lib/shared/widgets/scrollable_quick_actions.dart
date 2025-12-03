import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// クイックアクション項目の定義
class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });
}

/// 横スライド型クイックアクションウィジェット
class ScrollableQuickActions extends StatelessWidget {
  /// アクションリスト
  final List<QuickAction> actions;

  /// アイテムの幅（固定）
  final double itemWidth;

  /// アイテム間のスペース
  final double itemSpacing;

  const ScrollableQuickActions({
    super.key,
    required this.actions,
    this.itemWidth = 120.0,
    this.itemSpacing = AppDimensions.spacingM,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100, // 固定高さ
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return Container(
            width: itemWidth,
            margin: EdgeInsets.only(
              right: index < actions.length - 1 ? itemSpacing : 0,
            ),
            child: _QuickActionItem(action: action),
          );
        },
      ),
    );
  }
}

/// クイックアクション個別アイテム
class _QuickActionItem extends StatelessWidget {
  final QuickAction action;

  const _QuickActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: action.backgroundColor ?? AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow.withValues(alpha: 0.1),
                blurRadius: AppDimensions.cardElevation * 0.5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: (action.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  action.icon,
                  color: action.iconColor ?? AppColors.primary,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                action.label,
                style: TextStyle(
                  color: action.textColor ?? AppColors.textDark,
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// クイックアクションセクション全体のコンテナ
class QuickActionsSection extends StatelessWidget {
  /// セクションタイトル
  final String title;

  /// セクションアイコン
  final IconData icon;

  /// アクションリスト
  final List<QuickAction> actions;

  /// アイテムの幅
  final double itemWidth;

  /// 追加コンテンツ（オプション）
  final Widget? additionalContent;

  const QuickActionsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.actions,
    this.itemWidth = 120.0,
    this.additionalContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.accent,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ScrollableQuickActions(
            actions: actions,
            itemWidth: itemWidth,
          ),
          if (additionalContent != null) ...[
            const SizedBox(height: AppDimensions.spacingL),
            additionalContent!,
          ],
        ],
      ),
    );
  }
}