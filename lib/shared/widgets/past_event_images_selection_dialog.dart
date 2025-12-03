import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/models/event_model.dart';

class EventImageData {
  final String imageUrl;
  final String eventName;
  final DateTime eventDate;

  const EventImageData({
    required this.imageUrl,
    required this.eventName,
    required this.eventDate,
  });
}

class PastEventImagesSelectionDialog extends StatefulWidget {
  final List<Event> pastEvents;
  final String title;
  final String emptyMessage;

  const PastEventImagesSelectionDialog({
    super.key,
    required this.pastEvents,
    required this.title,
    required this.emptyMessage,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<Event> pastEvents,
    String title = '過去のイベント画像から選択',
    String emptyMessage = '利用可能な画像がありません',
  }) async {
    return await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PastEventImagesSelectionDialog(
        pastEvents: pastEvents,
        title: title,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  State<PastEventImagesSelectionDialog> createState() => _PastEventImagesSelectionDialogState();
}

class _PastEventImagesSelectionDialogState extends State<PastEventImagesSelectionDialog> {
  String _searchQuery = '';
  List<EventImageData> _availableImages = [];
  List<EventImageData> _filteredImages = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableImages();
  }

  void _loadAvailableImages() {
    _availableImages = widget.pastEvents
        .where((event) => event.imageUrl != null && event.imageUrl!.isNotEmpty)
        .map((event) => EventImageData(
              imageUrl: event.imageUrl!,
              eventName: event.name,
              eventDate: event.eventDate,
            ))
        .toList();

    // 日付順でソート（新しいものから）
    _availableImages.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    _filteredImages = _availableImages;
  }

  void _filterImages(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredImages = _availableImages;
      } else {
        _filteredImages = _availableImages
            .where((imageData) =>
                imageData.eventName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeXL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 検索バー
            TextField(
              onChanged: _filterImages,
              decoration: InputDecoration(
                hintText: 'イベント名で検索...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 統計情報
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      '${_filteredImages.length}個の画像が利用可能です',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 画像グリッド
            Expanded(
              child: _filteredImages.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppDimensions.spacingM,
                        mainAxisSpacing: AppDimensions.spacingM,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _filteredImages.length,
                      itemBuilder: (context, index) {
                        return _buildImageItem(_filteredImages[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: AppDimensions.iconXXL,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            _searchQuery.isNotEmpty ? '検索結果が見つかりません' : widget.emptyMessage,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              '別のキーワードで検索してください',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageItem(EventImageData imageData) {
    return Material(
      color: AppColors.backgroundTransparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(imageData.imageUrl),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: AppDimensions.cardElevation / 2,
                offset: const Offset(0, AppDimensions.shadowOffsetY / 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 画像
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusM),
                    topRight: Radius.circular(AppDimensions.radiusM),
                  ),
                  child: Image.network(
                    imageData.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.backgroundLight,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.backgroundLight,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.textLight,
                            size: AppDimensions.iconL,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // イベント情報
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imageData.eventName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      _formatDate(imageData.eventDate),
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeXS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}