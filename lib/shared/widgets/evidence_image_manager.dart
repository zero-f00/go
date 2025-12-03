import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/match_result_service.dart';

/// エビデンス画像管理ウィジェット
class EvidenceImageManager extends StatefulWidget {
  final String matchResultId;
  final String eventId;
  final String uploaderId;
  final String? uploaderName;
  final List<String> initialImages;
  final Map<String, Map<String, dynamic>>? initialMetadata;
  final VoidCallback? onImagesUpdated;

  const EvidenceImageManager({
    super.key,
    required this.matchResultId,
    required this.eventId,
    required this.uploaderId,
    this.uploaderName,
    this.initialImages = const [],
    this.initialMetadata,
    this.onImagesUpdated,
  });

  @override
  State<EvidenceImageManager> createState() => _EvidenceImageManagerState();
}

class _EvidenceImageManagerState extends State<EvidenceImageManager> {
  late List<String> _images;
  late Map<String, Map<String, dynamic>> _metadata;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final MatchResultService _matchResultService = MatchResultService();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
    _metadata = Map.from(widget.initialMetadata ?? {});
    _loadImages();
  }

  /// 最新の画像情報を読み込み
  Future<void> _loadImages() async {
    try {
      setState(() => _isLoading = true);

      final imageData = await _matchResultService.getAllEvidenceImages(widget.matchResultId);

      final newImages = <String>[];
      final newMetadata = <String, Map<String, dynamic>>{};

      for (final item in imageData) {
        final url = item['url'] as String;
        final metadata = item['metadata'] as Map<String, dynamic>;
        newImages.add(url);
        newMetadata[url] = metadata;
      }

      setState(() {
        _images = newImages;
        _metadata = newMetadata;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の読み込みに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 画像選択ダイアログを表示
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'エビデンス画像の追加',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'カメラで撮影',
                    onTap: () {
                      Navigator.of(context).pop();
                      _takePicture();
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'ギャラリーから選択',
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickImagesFromGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXL,
              color: AppColors.accent,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// カメラで撮影
  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        await _uploadImage(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラでの撮影に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ギャラリーから複数画像を選択
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
        limit: 10,
      );

      if (images != null && images.isNotEmpty) {
        final files = images.map((image) => File(image.path)).toList();
        await _uploadImages(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ギャラリーからの選択に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 単一画像をアップロード
  Future<void> _uploadImage(File imageFile) async {
    await _uploadImages([imageFile]);
  }

  /// 複数画像をアップロード
  Future<void> _uploadImages(List<File> imageFiles) async {
    try {
      setState(() => _isLoading = true);

      await _matchResultService.addEvidenceImages(
        matchResultId: widget.matchResultId,
        imageFiles: imageFiles,
        uploaderId: widget.uploaderId,
        uploaderName: widget.uploaderName,
      );

      await _loadImages();
      widget.onImagesUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${imageFiles.length}枚の画像をアップロードしました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像のアップロードに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 画像を削除
  Future<void> _deleteImage(String imageUrl) async {
    try {
      setState(() => _isLoading = true);

      await _matchResultService.removeEvidenceImage(
        matchResultId: widget.matchResultId,
        imageUrl: imageUrl,
      );

      await _loadImages();
      widget.onImagesUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を削除しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の削除に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 画像削除確認ダイアログ
  Future<void> _showDeleteConfirmation(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: const Text(
          '画像を削除',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text('この画像を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteImage(imageUrl);
    }
  }

  /// 画像操作メニューを表示（削除・置き換え）
  Future<void> _showImageActionMenu(String imageUrl) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              '画像の操作',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            // 置き換えボタン
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.accent,
                ),
              ),
              title: const Text(
                '画像を置き換え',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('新しい画像で置き換えます（古い画像は自動削除）'),
              onTap: () {
                Navigator.of(context).pop();
                _showReplaceImageDialog(imageUrl);
              },
            ),
            // 削除ボタン
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.delete,
                  color: AppColors.error,
                ),
              ),
              title: const Text(
                '画像を削除',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('この画像を完全に削除します'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(imageUrl);
              },
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }

  /// 画像置き換えダイアログを表示
  Future<void> _showReplaceImageDialog(String imageUrl) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              '画像の置き換え',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              '古い画像は自動的に削除され、新しい画像に置き換わります',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.camera_alt,
                    label: 'カメラで撮影',
                    onTap: () {
                      Navigator.of(context).pop();
                      _replaceWithCamera(imageUrl);
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: 'ギャラリーから選択',
                    onTap: () {
                      Navigator.of(context).pop();
                      _replaceFromGallery(imageUrl);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );
  }

  /// カメラで撮影して置き換え
  Future<void> _replaceWithCamera(String oldImageUrl) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        await _replaceImage(oldImageUrl, File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カメラでの撮影に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ギャラリーから選択して置き換え
  Future<void> _replaceFromGallery(String oldImageUrl) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        await _replaceImage(oldImageUrl, File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ギャラリーからの選択に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 画像を置き換え
  Future<void> _replaceImage(String oldImageUrl, File newImageFile) async {
    try {
      setState(() => _isLoading = true);

      await _matchResultService.replaceEvidenceImage(
        matchResultId: widget.matchResultId,
        oldImageUrl: oldImageUrl,
        newImageFile: newImageFile,
        uploaderId: widget.uploaderId,
        uploaderName: widget.uploaderName,
      );

      await _loadImages();
      widget.onImagesUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像を置き換えました（古い画像は自動削除されました）'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の置き換えに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 全ての画像を置き換え確認ダイアログ
  Future<void> _showReplaceAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: const Text(
          '全ての画像を置き換え',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '現在の${_images.length}枚の画像を全て削除し、新しい画像に置き換えますか？\n\nこの操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('置き換える'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _pickImagesForReplaceAll();
    }
  }

  /// 全置き換え用の画像選択
  Future<void> _pickImagesForReplaceAll() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
        limit: 10,
      );

      if (images != null && images.isNotEmpty) {
        final files = images.map((image) => File(image.path)).toList();
        await _replaceAllImages(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の選択に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 全ての画像を置き換え
  Future<void> _replaceAllImages(List<File> newImageFiles) async {
    try {
      setState(() => _isLoading = true);

      await _matchResultService.replaceAllEvidenceImages(
        matchResultId: widget.matchResultId,
        newImageFiles: newImageFiles,
        uploaderId: widget.uploaderId,
        uploaderName: widget.uploaderName,
      );

      await _loadImages();
      widget.onImagesUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newImageFiles.length}枚の新しい画像に置き換えました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の一括置き換えに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 画像拡大表示ダイアログ
  void _showImageDialog(String imageUrl, Map<String, dynamic>? metadata) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(AppDimensions.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusM),
                          topRight: Radius.circular(AppDimensions.radiusM),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image,
                            color: AppColors.info,
                            size: AppDimensions.iconM,
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(
                            'エビデンス画像',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showReplaceImageDialog(imageUrl);
                            },
                            icon: Icon(
                              Icons.swap_horiz,
                              color: AppColors.accent,
                            ),
                            tooltip: '画像を置き換え',
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteConfirmation(imageUrl);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            tooltip: '画像を削除',
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 画像
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: AppColors.backgroundLight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: AppColors.textSecondary,
                                      size: AppDimensions.iconXL,
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    Text(
                                      '画像の読み込みに失敗しました',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // メタデータ
                    if (metadata != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppDimensions.radiusM),
                            bottomRight: Radius.circular(AppDimensions.radiusM),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (metadata['uploaderName'] != null) ...[
                              _buildMetadataRow(
                                Icons.person,
                                'アップロード者',
                                metadata['uploaderName'],
                              ),
                              const SizedBox(height: AppDimensions.spacingXS),
                            ],
                            if (metadata['uploadedAt'] != null) ...[
                              _buildMetadataRow(
                                Icons.schedule,
                                'アップロード日時',
                                _formatDateTime(DateTime.parse(metadata['uploadedAt'])),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                Icons.image,
                color: AppColors.info,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'エビデンス画像',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (_images.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingS,
                    vertical: AppDimensions.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${_images.length}枚',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingS),
              ],
              Row(
                children: [
                  if (_images.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _showReplaceAllConfirmation,
                      icon: Icon(
                        Icons.swap_horiz,
                        size: AppDimensions.iconS,
                      ),
                      label: const Text('全て置換'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showImageSourceDialog,
                    icon: Icon(
                      Icons.add_photo_alternate,
                      size: AppDimensions.iconS,
                    ),
                    label: const Text('画像を追加'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '試合の証拠となる画像をアップロードできます',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          if (_isLoading) ...[
            const SizedBox(height: AppDimensions.spacingL),
            const Center(child: CircularProgressIndicator()),
          ] else if (_images.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingL),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppDimensions.spacingS,
                mainAxisSpacing: AppDimensions.spacingS,
                childAspectRatio: 1,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final imageUrl = _images[index];
                final metadata = _metadata[imageUrl];

                return GestureDetector(
                  onTap: () => _showImageDialog(imageUrl, metadata),
                  onLongPress: () => _showImageActionMenu(imageUrl),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.backgroundLight,
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColors.backgroundLight,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accent,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // オーバーレイ
                          Positioned.fill(
                            child: Container(
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
                          ),
                          // アクションボタン
                          Positioned(
                            top: AppDimensions.spacingXS,
                            right: AppDimensions.spacingXS,
                            child: Container(
                              padding: const EdgeInsets.all(AppDimensions.spacingXS),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                              ),
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: AppDimensions.iconXS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            const SizedBox(height: AppDimensions.spacingL),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingXL),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: AppDimensions.iconXL,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'エビデンス画像がありません',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    '「画像を追加」ボタンから画像をアップロードできます',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}