import 'package:flutter/material.dart';

/// テキストが親ウィジェットの幅を超える場合に
/// 自動的に流れるアニメーションを表示するテキストウィジェット
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration animationDuration;
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.animationDuration = const Duration(seconds: 5),
    this.pauseDuration = const Duration(seconds: 2),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _needsMarquee = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverflow();
    });
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOverflow();
      });
    }
  }

  void _checkOverflow() {
    if (!mounted) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final needsMarquee = maxScroll > 0;

    if (needsMarquee != _needsMarquee) {
      setState(() {
        _needsMarquee = needsMarquee;
      });
    }

    if (_needsMarquee && !_isAnimating) {
      _startAnimation();
    }
  }

  Future<void> _startAnimation() async {
    if (!mounted || !_needsMarquee) return;

    _isAnimating = true;

    while (mounted && _needsMarquee) {
      // 開始位置で一時停止
      await Future.delayed(widget.pauseDuration);
      if (!mounted) break;

      // 右端までスクロール
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        await _scrollController.animateTo(
          maxScroll,
          duration: widget.animationDuration,
          curve: Curves.linear,
        );
      }

      if (!mounted) break;

      // 右端で一時停止
      await Future.delayed(widget.pauseDuration);
      if (!mounted) break;

      // 開始位置に戻る
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }

    _isAnimating = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
