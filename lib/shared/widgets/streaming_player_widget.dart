import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/streaming_utils.dart';

/// ストリーミング配信プレイヤーウィジェット
class StreamingPlayerWidget extends StatefulWidget {
  final List<String> streamingUrls;
  final bool autoPlay;
  final bool showControls;

  const StreamingPlayerWidget({
    super.key,
    required this.streamingUrls,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<StreamingPlayerWidget> createState() => _StreamingPlayerWidgetState();
}

class _StreamingPlayerWidgetState extends State<StreamingPlayerWidget> {
  int _selectedUrlIndex = 0;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  /// プレイヤーの初期化
  void _initializePlayer() {
    if (widget.streamingUrls.isEmpty) return;

    final currentUrl = widget.streamingUrls[_selectedUrlIndex];
    final platform = StreamingUtils.detectPlatform(currentUrl);

    if (platform == StreamingPlatform.youtube) {
      _initializeYouTubePlayer(currentUrl);
    }
  }

  /// YouTubeプレイヤーの初期化
  void _initializeYouTubePlayer(String url) {
    try {
      final videoId = StreamingUtils.extractYouTubeVideoId(url);
      if (videoId == null) return;

      _youtubeController?.dispose();
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: false,
          isLive: false, // LIVE表示を無効化
          loop: false,
          showLiveFullscreenButton: false, // フルスクリーンボタンを無効化
          hideControls: false,
          controlsVisibleAtStart: true,
          disableDragSeek: false,
        ),
      );
    } catch (e) {
      // YouTubeプレイヤーの初期化に失敗した場合
      _youtubeController = null;
    }
  }

  /// 配信URLを変更
  void _changeStreamingUrl(int index) {
    if (index == _selectedUrlIndex || index >= widget.streamingUrls.length) {
      return;
    }

    setState(() {
      _selectedUrlIndex = index;
      _initializePlayer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streamingUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // プラットフォーム選択タブ（複数URLがある場合）
        if (widget.streamingUrls.length > 1) ...[
          _buildPlatformTabs(),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // 選択されたプラットフォームのプレイヤー
        _buildSelectedPlayer(),

        if (widget.showControls) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildPlayerControls(),
        ],
      ],
    );
  }

  /// プラットフォーム選択タブ
  Widget _buildPlatformTabs() {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.streamingUrls.length,
        itemBuilder: (context, index) {
          final url = widget.streamingUrls[index];
          final platform = StreamingUtils.detectPlatform(url);
          final platformName = StreamingUtils.getPlatformName(platform);
          final platformIcon = StreamingUtils.getPlatformIcon(platform);
          final isSelected = index == _selectedUrlIndex;

          return Padding(
            padding: EdgeInsets.only(
              right: index == widget.streamingUrls.length - 1 ? 0 : AppDimensions.spacingS,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _changeStreamingUrl(index),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingM,
                    vertical: AppDimensions.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        platformIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        platformName,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textDark,
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 選択されたプラットフォームのプレイヤー
  Widget _buildSelectedPlayer() {
    final currentUrl = widget.streamingUrls[_selectedUrlIndex];
    final platform = StreamingUtils.detectPlatform(currentUrl);

    switch (platform) {
      case StreamingPlatform.youtube:
        return _buildYouTubePlayer();
      case StreamingPlatform.twitch:
      case StreamingPlatform.niconico:
      case StreamingPlatform.other:
        return _buildGenericPlayer(currentUrl, platform);
    }
  }

  /// YouTubeプレイヤー
  Widget _buildYouTubePlayer() {
    if (_youtubeController == null) {
      return _buildPlayerPlaceholder('YouTube動画を読み込み中...');
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: _youtubeController != null
            ? YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppColors.accent,
                progressColors: ProgressBarColors(
                  playedColor: AppColors.accent,
                  handleColor: AppColors.accent,
                ),
                onReady: () {
                  // プレイヤーの準備完了
                },
              )
            : Container(
                height: 200,
                color: AppColors.backgroundLight,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'プレイヤーを読み込めませんでした',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// 汎用プレイヤー（サムネイル表示 + 外部リンク）
  Widget _buildGenericPlayer(String url, StreamingPlatform platform) {
    final platformName = StreamingUtils.getPlatformName(platform);
    final platformIcon = StreamingUtils.getPlatformIcon(platform);
    final domain = StreamingUtils.extractDomain(url);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => StreamingUtils.openExternalUrl(url),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      platformIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  '$platformName で配信を視聴',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  domain,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppDimensions.fontSizeS,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                const Icon(
                  Icons.open_in_new,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// プレイヤーのプレースホルダー
  Widget _buildPlayerPlaceholder(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accent,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppDimensions.fontSizeM,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// プレイヤーコントロール
  Widget _buildPlayerControls() {
    final currentUrl = widget.streamingUrls[_selectedUrlIndex];
    final platform = StreamingUtils.detectPlatform(currentUrl);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 外部で開く
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (platform == StreamingPlatform.youtube) {
                  StreamingUtils.openYouTubeApp(currentUrl);
                } else {
                  StreamingUtils.openExternalUrl(currentUrl);
                }
              },
              icon: Icon(
                platform == StreamingPlatform.youtube
                    ? Icons.play_circle_outline
                    : Icons.open_in_new,
                size: 20,
              ),
              label: Text(
                platform == StreamingPlatform.youtube
                    ? 'YouTubeで開く'
                    : '外部アプリで開く',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}