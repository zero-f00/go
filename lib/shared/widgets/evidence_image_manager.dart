import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/match_result_service.dart';
import '../../l10n/app_localizations.dart';

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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageLoadError(e.toString())),
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
    final l10n = L10n.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (dialogContext) => Container(
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
              l10n.addEvidenceImageTitle,
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
                    label: l10n.takePhotoLabel,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      _takePicture();
                    },
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: _buildImageSourceButton(
                    icon: Icons.photo_library,
                    label: l10n.selectFromGalleryLabel,
                    onTap: () {
                      Navigator.of(dialogContext).pop();
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cameraCaptureError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gallerySelectError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagesUploadedMessage(imageFiles.length)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageUploadError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageDeletedMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageDeleteError(e.toString())),
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
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Text(
          l10n.deleteImageTitle,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(l10n.deleteImageConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
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
    final l10n = L10n.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusM),
        ),
      ),
      builder: (dialogContext) => Container(
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
              l10n.imageOperationsTitle,
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
              title: Text(
                l10n.replaceImageLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(l10n.replaceImageDescription),
              onTap: () {
                Navigator.of(dialogContext).pop();
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
              title: Text(
                l10n.deleteImageLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(l10n.deleteImageDescription),
              onTap: () {
                Navigator.of(dialogContext).pop();
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
      builder: (dialogContext) {
        final l10n = L10n.of(dialogContext);
        return Container(
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
                l10n.replaceImageTitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.replaceImageDialogDescription,
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
                      label: l10n.takePhotoLabel,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _replaceWithCamera(imageUrl);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: l10n.selectFromGalleryLabel,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        _replaceFromGallery(imageUrl);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingL),
            ],
          ),
        );
      },
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cameraCaptureError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.gallerySelectError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageReplacedMessage),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageReplaceError(e.toString())),
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
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Text(
          l10n.replaceAllImagesTitle,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          l10n.replaceAllImagesConfirmMessage(_images.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.replaceAllButton),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageSelectError(e.toString())),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagesReplacedMessage(newImageFiles.length)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imagesBulkReplaceFailedError(e.toString())),
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
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                            l10n.evidenceImageTitle,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showReplaceImageDialog(imageUrl);
                            },
                            icon: Icon(
                              Icons.swap_horiz,
                              color: AppColors.accent,
                            ),
                            tooltip: l10n.replaceImageTooltip,
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showDeleteConfirmation(imageUrl);
                            },
                            icon: Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            tooltip: l10n.deleteImageTooltip,
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
                                      l10n.imageLoadFailedMessage,
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
                                l10n.uploaderLabel,
                                metadata['uploaderName'],
                              ),
                              const SizedBox(height: AppDimensions.spacingXS),
                            ],
                            if (metadata['uploadedAt'] != null) ...[
                              _buildMetadataRow(
                                Icons.schedule,
                                l10n.uploadDateTimeLabel,
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
    final l10n = L10n.of(context);
    return l10n.dateTimeFormatFull(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
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
                l10n.evidenceImageSectionTitle,
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
                    l10n.imagesCountLabel(_images.length),
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
                      label: Text(l10n.replaceAllLabel),
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
                    label: Text(l10n.addImageButtonLabel),
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
            l10n.evidenceImageInfo,
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
                    l10n.noEvidenceImages,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    l10n.noEvidenceImagesDescription,
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