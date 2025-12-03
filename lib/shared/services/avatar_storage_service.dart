import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// アバター画像のFirebase Storage管理サービス
class AvatarStorageService {
  static final AvatarStorageService _instance = AvatarStorageService._internal();
  factory AvatarStorageService() => _instance;
  AvatarStorageService._internal();

  static AvatarStorageService get instance => _instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 最大ファイルサイズ（5MB）
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// 許可されるファイル形式
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];

  /// ユーザーのアバター画像をアップロードする
  ///
  /// [file]: アップロードする画像ファイル
  /// [onProgress]: アップロード進捗コールバック（0.0-1.0）
  ///
  /// Returns: アップロードされた画像のダウンロードURL
  Future<String> uploadAvatar({
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // ファイル検証
    await _validateFile(file);

    try {
      // 古いアバターを削除
      await _deleteOldAvatar(user.uid);

      // 新しいアバターをアップロード
      final fileName = _generateFileName(file);
      final ref = _storage.ref().child('users/${user.uid}/avatars/$fileName');

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(file),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': user.uid,
          },
        ),
      );

      // 進捗監視
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('アバターのアップロードに失敗しました: ${e.toString()}');
    }
  }

  /// ユーザーのアバター画像を取得する
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final listResult = await _storage.ref().child('users/$userId/avatars').listAll();

      if (listResult.items.isEmpty) {
        return null;
      }

      // 最新のアバターを取得（ファイル名にタイムスタンプが含まれているため）
      final latestItem = listResult.items.last;
      return await latestItem.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null;
      }
      throw _handleFirebaseException(e);
    } catch (e) {
      print('アバターURL取得エラー: $e');
      return null;
    }
  }

  /// ユーザーのアバター画像を削除する
  Future<void> deleteAvatar() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ユーザーが認証されていません');
    }

    try {
      await _deleteOldAvatar(user.uid);
    } on FirebaseException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception('アバターの削除に失敗しました: ${e.toString()}');
    }
  }

  /// 古いアバターを削除する
  Future<void> _deleteOldAvatar(String userId) async {
    try {
      final listResult = await _storage.ref().child('users/$userId/avatars').listAll();

      // 既存のアバターをすべて削除
      for (final item in listResult.items) {
        await item.delete();
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        // アバターがない場合は無視
        return;
      }
      rethrow;
    }
  }

  /// ファイルの検証
  Future<void> _validateFile(File file) async {
    // ファイルの存在確認
    if (!await file.exists()) {
      throw Exception('ファイルが存在しません');
    }

    // ファイルサイズチェック
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) {
      throw Exception('ファイルサイズが大きすぎます（最大5MB）');
    }

    // ファイル拡張子チェック
    final extension = path.extension(file.path).toLowerCase().substring(1);
    if (!allowedExtensions.contains(extension)) {
      throw Exception('サポートされていないファイル形式です（JPEG, PNG のみ）');
    }
  }

  /// ファイル名を生成する
  String _generateFileName(File file) {
    final extension = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'avatar_$timestamp$extension';
  }

  /// Content-Typeを取得する
  String _getContentType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Firebase例外をハンドリングする
  Exception _handleFirebaseException(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return Exception('アクセス権限がありません');
      case 'canceled':
        return Exception('アップロードがキャンセルされました');
      case 'unknown':
        return Exception('不明なエラーが発生しました');
      case 'object-not-found':
        return Exception('ファイルが見つかりません');
      case 'bucket-not-found':
        return Exception('ストレージが見つかりません');
      case 'quota-exceeded':
        return Exception('ストレージ容量を超過しました');
      case 'unauthenticated':
        return Exception('認証されていません');
      case 'retry-limit-exceeded':
        return Exception('リトライ制限を超過しました');
      case 'invalid-checksum':
        return Exception('ファイルが破損している可能性があります');
      default:
        return Exception('アップロードエラー: ${e.message}');
    }
  }

  /// 画像ピッカーからファイルサイズを事前チェック
  static Future<bool> validatePickedFile(XFile pickedFile) async {
    try {
      final fileSize = await pickedFile.length();
      final extension = path.extension(pickedFile.path).toLowerCase().substring(1);

      return fileSize <= maxFileSizeBytes && allowedExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }
}