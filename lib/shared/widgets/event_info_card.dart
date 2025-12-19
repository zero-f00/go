import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// イベント情報表示用の共通カード
///
/// 運営管理画面の各サブ画面で使用される、イベント名を表示するカードコンポーネント。
/// 長いイベント名の場合は自動的にMarqueeアニメーションで表示される。
class EventInfoCard extends StatefulWidget {
  /// イベント名
  final String eventName;

  /// イベントID（タップ時のナビゲーションに使用）
  final String? eventId;

  /// タップ機能の有効/無効
  /// 通知画面から遷移した場合のみtrueにする
  final bool enableTap;

  /// カスタムアイコン（デフォルト: Icons.event）
  final IconData? iconData;

  /// アイコン色（デフォルト: AppColors.accent）
  final Color? iconColor;

  /// カードのマージン（デフォルト: AppDimensions.spacingL）
  final EdgeInsetsGeometry? margin;

  /// カードに追加ウィジェット（参加者数バッジなど）を表示する場合
  final Widget? trailing;

  /// ボーダーの表示有無
  final bool showBorder;

  const EventInfoCard({
    super.key,
    required this.eventName,
    this.eventId,
    this.enableTap = false,
    this.iconData,
    this.iconColor,
    this.margin,
    this.trailing,
    this.showBorder = false,
  });

  @override
  State<EventInfoCard> createState() => _EventInfoCardState();
}

class _EventInfoCardState extends State<EventInfoCard>
    with TickerProviderStateMixin {
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: widget.margin ?? const EdgeInsets.all(AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: widget.showBorder
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            widget.iconData ?? Icons.event,
            color: widget.iconColor ?? AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: _buildMarqueeEventName(),
          ),
          if (widget.trailing != null) widget.trailing!,
          if (widget.enableTap && widget.eventId != null) ...[
            const SizedBox(width: AppDimensions.spacingS),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ],
        ],
      ),
    );

    // タップ機能が有効な場合はInkWellで包む
    if (widget.enableTap && widget.eventId != null) {
      return InkWell(
        onTap: () => _navigateToEventDetail(context),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: content,
      );
    }

    return content;
  }

  /// イベント詳細画面に遷移
  void _navigateToEventDetail(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/event_detail',
      arguments: widget.eventId,
    );
  }

  /// Marqueeアニメーション付きイベント名表示
  Widget _buildMarqueeEventName() {
    return SizedBox(
      height: 28,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _marqueeController,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return _buildMarqueeContent(widget.eventName, constraints);
              },
            );
          },
        ),
      ),
    );
  }

  /// Marqueeコンテンツ作成
  Widget _buildMarqueeContent(String eventName, BoxConstraints constraints) {
    final textWidth = _calculateTextWidth(eventName);

    if (textWidth <= constraints.maxWidth) {
      return _buildStaticEventName(eventName);
    }

    return _buildAnimatedEventName(eventName, textWidth);
  }

  /// テキスト幅計算
  double _calculateTextWidth(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.size.width;
  }

  /// 静的イベント名表示（幅が十分な場合）
  Widget _buildStaticEventName(String eventName) {
    return Text(
      eventName,
      style: const TextStyle(
        fontSize: AppDimensions.fontSizeL,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  /// アニメーション付きイベント名表示（幅が不足する場合）
  Widget _buildAnimatedEventName(String eventName, double textWidth) {
    final double currentOffset = -textWidth * _marqueeController.value;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        _buildPositionedEventName(eventName, currentOffset),
        _buildPositionedEventName(
            eventName, currentOffset + textWidth + 50), // 50pxのスペースを追加
      ],
    );
  }

  /// 位置指定されたイベント名テキスト
  Widget _buildPositionedEventName(String eventName, double offset) {
    return Positioned(
      left: offset,
      child: Text(
        eventName,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}