import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../l10n/app_localizations.dart';

class AvatarService {
  static AvatarService? _instance;
  static AvatarService get instance => _instance ??= AvatarService._();

  AvatarService._();

  final ImagePicker _picker = ImagePicker();
  static const String _avatarPathKey = 'user_avatar_path';

  Future<File?> pickAndCropAvatar(BuildContext context) async {
    try {
      final XFile? pickedFile = await _showImageSourceDialog(context);

      if (pickedFile == null) {
        return null;
      }

      final File? croppedFile = await _cropImage(pickedFile.path, context);

      if (croppedFile != null) {
        // アプリ内ディレクトリにアバター画像を保存
        final File savedFile = await _saveAvatarToAppDirectory(croppedFile);
        await saveAvatarPath(savedFile.path);
        return savedFile;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<XFile?> _showImageSourceDialog(BuildContext context) async {
    final l10n = L10n.of(context);
    return showDialog<XFile?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.selectAvatarImage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.takePhotoFromCamera),
                onTap: () async {
                  final XFile? photo = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 60,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(photo);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.selectFromGalleryOption),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 60,
                    maxWidth: 512,
                    maxHeight: 512,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<File?> _cropImage(String imagePath, [BuildContext? context]) async {
    try {
      // contextがある場合はローカライズされたタイトルを使用
      final String toolbarTitle = context != null
          ? L10n.of(context).adjustAvatar
          : 'Adjust Avatar';

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: toolbarTitle,
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

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      return null;
    }
  }

  Future<File> _saveAvatarToAppDirectory(File sourceFile) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String targetPath = path.join(appDir.path, fileName);

    // 古いアバターファイルを削除
    await deleteAvatar();

    // ファイルサイズをチェック
    final int originalSize = await sourceFile.length();

    // 1MB以上の場合は追加圧縮
    if (originalSize > 1024 * 1024) {
      return await _compressImage(sourceFile, targetPath);
    } else {
      return await sourceFile.copy(targetPath);
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
    try {
      // 画像を読み込み
      final Uint8List imageBytes = await sourceFile.readAsBytes();
      final ui.Image image = await _decodeImage(imageBytes);

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

      return compressedFile;
    } catch (e) {
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