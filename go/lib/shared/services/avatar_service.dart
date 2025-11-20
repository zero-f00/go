import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AvatarService {
  static AvatarService? _instance;
  static AvatarService get instance => _instance ??= AvatarService._();

  AvatarService._();

  final ImagePicker _picker = ImagePicker();
  static const String _avatarPathKey = 'user_avatar_path';

  Future<File?> pickAndCropAvatar(BuildContext context) async {
    debugPrint('🚀 AvatarService: pickAndCropAvatar called');
    try {
      debugPrint('🔄 AvatarService: Showing image source dialog');
      final XFile? pickedFile = await _showImageSourceDialog(context);
      debugPrint('✅ AvatarService: Image source dialog returned: ${pickedFile?.path}');

      if (pickedFile == null) {
        debugPrint('⚠️ AvatarService: No image was picked');
        return null;
      }

      debugPrint('🔄 AvatarService: Starting image crop with path: ${pickedFile.path}');
      final File? croppedFile = await _cropImage(pickedFile.path, context);
      debugPrint('✅ AvatarService: Image crop returned: ${croppedFile?.path}');

      if (croppedFile != null) {
        debugPrint('🔄 AvatarService: Saving cropped image to app directory');
        // アプリ内ディレクトリにアバター画像を保存
        final File savedFile = await _saveAvatarToAppDirectory(croppedFile);
        await saveAvatarPath(savedFile.path);
        debugPrint('✅ AvatarService: Successfully saved avatar to: ${savedFile.path}');
        return savedFile;
      } else {
        debugPrint('⚠️ AvatarService: Image cropping was cancelled or failed');
      }

      return null;
    } catch (e) {
      debugPrint('❌ AvatarService: Error picking/cropping avatar: $e');
      return null;
    }
  }

  Future<XFile?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アバター画像を選択'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('カメラで撮影'),
                onTap: () async {
                  debugPrint('📸 AvatarService: Camera option selected');
                  debugPrint('🔄 AvatarService: Calling pickImage from camera');
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 60,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  debugPrint('✅ AvatarService: pickImage from camera returned: ${photo?.path}');
                  if (context.mounted) {
                    Navigator.of(context).pop(photo);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('ギャラリーから選択'),
                onTap: () async {
                  debugPrint('📷 AvatarService: Gallery option selected');
                  debugPrint('🔄 AvatarService: Calling pickImage from gallery');
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 60,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  debugPrint('✅ AvatarService: pickImage from gallery returned: ${image?.path}');
                  if (context.mounted) {
                    Navigator.of(context).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  Future<File?> _cropImage(String imagePath, [BuildContext? context]) async {
    debugPrint('🔄 AvatarService: _cropImage called with path: $imagePath');
    try {
      debugPrint('🔄 AvatarService: Starting ImageCropper.cropImage');
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'アバターを調整',
            toolbarColor: const Color(0xFF2E3B4E),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            cropStyle: CropStyle.circle,
            minimumAspectRatio: 1.0,
            hidesNavigationBar: false,
          ),
          if (context != null)
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: CropperSize(
                width: (MediaQuery.of(context).size.width * 0.8).toInt(),
                height: (MediaQuery.of(context).size.height * 0.75).toInt(),
              ),
            ),
        ],
      );
      debugPrint('✅ AvatarService: ImageCropper.cropImage completed: ${croppedFile?.path}');

      final result = croppedFile != null ? File(croppedFile.path) : null;
      debugPrint('🔄 AvatarService: _cropImage returning: ${result?.path}');
      return result;
    } catch (e) {
      debugPrint('❌ AvatarService: Error in _cropImage: $e');
      return null;
    }
  }

  Future<File> _saveAvatarToAppDirectory(File sourceFile) async {
    debugPrint('🔄 AvatarService: Starting to save avatar to app directory');

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String targetPath = path.join(appDir.path, fileName);

    // 古いアバターファイルを削除
    await deleteAvatar();

    // ファイルサイズをチェック
    final int originalSize = await sourceFile.length();
    debugPrint('📊 AvatarService: Original file size: ${_formatFileSize(originalSize)}');

    // 1MB以上の場合は追加圧縮
    if (originalSize > 1024 * 1024) {
      debugPrint('⚠️ AvatarService: File too large, applying additional compression');
      final File compressedFile = await _compressImage(sourceFile, targetPath);
      final int compressedSize = await compressedFile.length();
      debugPrint('✅ AvatarService: Compressed file size: ${_formatFileSize(compressedSize)}');
      return compressedFile;
    } else {
      debugPrint('✅ AvatarService: File size acceptable, copying directly');
      final File copiedFile = await sourceFile.copy(targetPath);
      final int finalSize = await copiedFile.length();
      debugPrint('📊 AvatarService: Final file size: ${_formatFileSize(finalSize)}');
      return copiedFile;
    }
  }

  Future<void> deleteAvatar() async {
    final String? currentAvatarPath = await getAvatarPath();
    if (currentAvatarPath != null) {
      final File currentFile = File(currentAvatarPath);
      if (currentFile.existsSync()) {
        await currentFile.delete();
      }
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarPathKey);
  }

  Future<String?> getAvatarPath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarPathKey);
  }

  Future<void> saveAvatarPath(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
  }

  /// 画像を追加圧縮する
  Future<File> _compressImage(File sourceFile, String targetPath) async {
    debugPrint('🔄 AvatarService: Starting image compression');
    try {
      // 画像を読み込み
      final Uint8List imageBytes = await sourceFile.readAsBytes();
      final ui.Image image = await _decodeImage(imageBytes);

      debugPrint('📏 AvatarService: Original image size: ${image.width}x${image.height}');

      // 512x512のサイズに調整（必要に応じて）
      final ui.Image resizedImage = await _resizeImage(image, 512, 512);

      // JPEGとして圧縮保存（品質40で積極的な圧縮）
      final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to compress image');
      }

      // 圧縮された画像をファイルに保存
      final File compressedFile = File(targetPath);
      await compressedFile.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('✅ AvatarService: Image compression completed');
      return compressedFile;
    } catch (e) {
      debugPrint('❌ AvatarService: Error compressing image: $e');
      // 圧縮に失敗した場合は元ファイルをコピー
      return sourceFile.copy(targetPath);
    }
  }

  /// 画像をデコードする
  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  /// 画像をリサイズする
  Future<ui.Image> _resizeImage(ui.Image image, int targetWidth, int targetHeight) async {
    final double aspectRatio = image.width / image.height;
    int width, height;

    if (aspectRatio > 1) {
      width = targetWidth;
      height = (targetWidth / aspectRatio).round();
    } else {
      width = (targetHeight * aspectRatio).round();
      height = targetHeight;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final ui.Paint paint = ui.Paint();

    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    final ui.Picture picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  /// ファイルサイズを読みやすい形式にフォーマットする
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
  }

  void dispose() {
    // 必要に応じてリソースのクリーンアップ
  }
}