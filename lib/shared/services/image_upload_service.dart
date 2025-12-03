import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

/// 画像アップロード結果
class ImageUploadResult {
  final String downloadUrl;
  final String filePath;
  final int compressedSize;
  final int originalSize;

  const ImageUploadResult({
    required this.downloadUrl,
    required this.filePath,
    required this.compressedSize,
    required this.originalSize,
  });

  double get compressionRatio => originalSize > 0 ? compressedSize / originalSize : 1.0;
}

/// 画像アップロード設定
class ImageUploadOptions {
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxFileSizeKB;
  final List<String> allowedExtensions;

  const ImageUploadOptions({
    this.maxWidth = 1920,
    this.maxHeight = 1080,
    this.quality = 85,
    this.maxFileSizeKB = 2048, // 2MB
    this.allowedExtensions = const ['jpg', 'jpeg', 'png'],
  });

  static const ImageUploadOptions eventImage = ImageUploadOptions(
    maxWidth: 1920,
    maxHeight: 1080,
    quality: 85,
    maxFileSizeKB: 2048,
  );

  static const ImageUploadOptions avatar = ImageUploadOptions(
    maxWidth: 512,
    maxHeight: 512,
    quality: 90,
    maxFileSizeKB: 1024,
  );
}

/// 画像アップロードサービス
class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// イベント画像をアップロード
  static Future<ImageUploadResult> uploadEventImage(
    File imageFile,
    String eventId, {
    ImageUploadOptions options = ImageUploadOptions.eventImage,
    Function(double)? onProgress,
  }) async {
    try {

      // ファイル検証
      await _validateImage(imageFile, options);

      // 画像圧縮
      final compressedData = await _compressImage(imageFile, options);

      // Firebase Storageパスを生成
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_event_image.jpg';
      final storagePath = 'events/$eventId/images/$fileName';

      // アップロード実行
      final downloadUrl = await _uploadToStorage(
        compressedData,
        storagePath,
        onProgress: onProgress,
      );


      return ImageUploadResult(
        downloadUrl: downloadUrl,
        filePath: storagePath,
        compressedSize: compressedData.length,
        originalSize: imageFile.lengthSync(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーアバター画像をアップロード
  static Future<ImageUploadResult> uploadUserAvatar(
    File imageFile,
    String userId, {
    ImageUploadOptions options = ImageUploadOptions.avatar,
    Function(double)? onProgress,
  }) async {
    try {

      // ファイル検証
      await _validateImage(imageFile, options);

      // 画像圧縮
      final compressedData = await _compressImage(imageFile, options);

      // Firebase Storageパスを生成
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_avatar.jpg';
      final storagePath = 'users/$userId/avatar/$fileName';

      // アップロード実行
      final downloadUrl = await _uploadToStorage(
        compressedData,
        storagePath,
        onProgress: onProgress,
      );


      return ImageUploadResult(
        downloadUrl: downloadUrl,
        filePath: storagePath,
        compressedSize: compressedData.length,
        originalSize: imageFile.lengthSync(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// エビデンス画像をアップロード
  static Future<ImageUploadResult> uploadEvidenceImage(
    File imageFile,
    String eventId,
    String matchId,
    String uploaderId, {
    ImageUploadOptions options = ImageUploadOptions.eventImage,
    Function(double)? onProgress,
  }) async {
    try {

      // ファイル検証
      await _validateImage(imageFile, options);

      // 画像圧縮
      final compressedData = await _compressImage(imageFile, options);

      // Firebase Storageパスを生成
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_evidence_${uploaderId}.jpg';
      final storagePath = 'evidence_images/$eventId/$matchId/$fileName';

      // アップロード実行
      final downloadUrl = await _uploadToStorage(
        compressedData,
        storagePath,
        onProgress: onProgress,
      );


      return ImageUploadResult(
        downloadUrl: downloadUrl,
        filePath: storagePath,
        compressedSize: compressedData.length,
        originalSize: imageFile.lengthSync(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// 複数のエビデンス画像を並行アップロード
  static Future<List<ImageUploadResult>> uploadMultipleEvidenceImages(
    List<File> imageFiles,
    String eventId,
    String matchId,
    String uploaderId, {
    ImageUploadOptions options = ImageUploadOptions.eventImage,
    Function(int completed, int total)? onProgress,
  }) async {
    try {

      final results = <ImageUploadResult>[];
      int completed = 0;

      for (final imageFile in imageFiles) {
        final result = await uploadEvidenceImage(
          imageFile,
          eventId,
          matchId,
          uploaderId,
          options: options,
        );
        results.add(result);
        completed++;
        onProgress?.call(completed, imageFiles.length);
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// 画像を削除
  static Future<void> deleteImage(String filePath) async {
    try {
      await _storage.ref(filePath).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// URLから画像を削除
  static Future<void> deleteImageFromUrl(String downloadUrl) async {
    try {
      // ローカルファイルパスの場合はスキップ
      if (!downloadUrl.startsWith('http') && !downloadUrl.startsWith('gs://')) {
        return;
      }

      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  /// 複数のエビデンス画像をURLから削除
  static Future<void> deleteMultipleEvidenceImages(List<String> downloadUrls) async {
    final List<String> failedDeletions = [];

    for (final url in downloadUrls) {
      try {
        await deleteImageFromUrl(url);
      } catch (e) {
        failedDeletions.add(url);
      }
    }

    if (failedDeletions.isNotEmpty) {
      throw Exception('Failed to delete ${failedDeletions.length} images: ${failedDeletions.join(", ")}');
    }
  }

  /// 画像ファイルを検証
  static Future<void> _validateImage(File imageFile, ImageUploadOptions options) async {
    // ファイル存在確認
    if (!await imageFile.exists()) {
      throw Exception('画像ファイルが見つかりません');
    }

    // ファイルサイズ確認
    final fileSizeKB = imageFile.lengthSync() / 1024;
    if (fileSizeKB > options.maxFileSizeKB) {
      throw Exception('画像ファイルが大きすぎます。${options.maxFileSizeKB}KB以下にしてください。');
    }

    // 拡張子確認
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    if (!options.allowedExtensions.contains(extension)) {
      throw Exception('サポートされていない画像形式です。${options.allowedExtensions.join(', ')}のみ対応しています。');
    }

  }

  /// 画像を圧縮
  static Future<Uint8List> _compressImage(File imageFile, ImageUploadOptions options) async {
    return compute(_compressImageInIsolate, {
      'imageBytes': await imageFile.readAsBytes(),
      'maxWidth': options.maxWidth,
      'maxHeight': options.maxHeight,
      'quality': options.quality,
    });
  }

  /// Isolateで画像圧縮を実行（UIをブロックしないため）
  static Uint8List _compressImageInIsolate(Map<String, dynamic> params) {
    final imageBytes = params['imageBytes'] as Uint8List;
    final maxWidth = params['maxWidth'] as int;
    final maxHeight = params['maxHeight'] as int;
    final quality = params['quality'] as int;

    // 画像をデコード
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('画像のデコードに失敗しました');
    }

    // リサイズが必要かチェック
    img.Image resizedImage = originalImage;
    if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
      // アスペクト比を保持してリサイズ
      resizedImage = img.copyResize(
        originalImage,
        width: originalImage.width > originalImage.height ? maxWidth : null,
        height: originalImage.height > originalImage.width ? maxHeight : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // JPEGとしてエンコード（品質指定）
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: quality));
  }

  /// Firebase Storageにアップロード
  static Future<String> _uploadToStorage(
    Uint8List data,
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref(storagePath);

      // メタデータ設定
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // アップロードタスク開始
      final uploadTask = ref.putData(data, metadata);

      // 進捗監視
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // アップロード完了を待機
      final snapshot = await uploadTask;

      // ダウンロードURL取得
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  /// 画像のメタデータを取得
  static Future<FullMetadata> getImageMetadata(String filePath) async {
    try {
      return await _storage.ref(filePath).getMetadata();
    } catch (e) {
      rethrow;
    }
  }

  /// 一時的なダウンロードURLを生成
  static Future<String> getTemporaryDownloadUrl(String filePath, {Duration? validity}) async {
    try {
      validity ??= const Duration(hours: 1);
      return await _storage.ref(filePath).getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}

/// アップロード進捗コールバック関数の型定義
typedef UploadProgressCallback = void Function(double progress);

/// 画像アップロード例外クラス
class ImageUploadException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const ImageUploadException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'ImageUploadException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}