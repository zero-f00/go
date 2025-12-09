import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_strings.dart';

/// Firestore データベース操作サービス
/// 全てのFirestore操作を統一的に管理し、エラーハンドリングと型安全性を提供
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  /// Firestore インスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Firebase Auth インスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在認証中のユーザーID
  String? get currentUserId => _auth.currentUser?.uid;

  /// コレクション参照の取得
  CollectionReference<Map<String, dynamic>> _collection(String path) {
    return _firestore.collection(path);
  }

  /// ドキュメント参照の取得
  DocumentReference<Map<String, dynamic>> _document(String path) {
    return _firestore.doc(path);
  }

  /// ユーザーコレクションへの参照
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _collection('users');

  /// 特定ユーザーのドキュメント参照
  DocumentReference<Map<String, dynamic>> userDocument(String userId) =>
      _document('users/$userId');

  /// ゲームイベントコレクションへの参照
  CollectionReference<Map<String, dynamic>> get gameEventsCollection =>
      _collection('gameEvents');

  /// 特定ゲームイベントのドキュメント参照
  DocumentReference<Map<String, dynamic>> gameEventDocument(String eventId) =>
      _document('gameEvents/$eventId');

  /// ドキュメント作成
  /// [path] ドキュメントパス
  /// [data] 保存するデータ
  Future<void> createDocument(String path, Map<String, dynamic> data) async {
    try {
      await _document(path).set(data);
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの作成に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ドキュメント更新
  /// [path] ドキュメントパス
  /// [data] 更新するデータ
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      await _document(path).update(data);
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの更新に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ドキュメント設定（upsert動作）
  /// [path] ドキュメントパス
  /// [data] 設定するデータ
  /// [merge] マージオプション（true: 既存データとマージ, false: 上書き）
  Future<void> setDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      await _document(path).set(data, SetOptions(merge: merge));
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの設定に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ドキュメント削除
  /// [path] ドキュメントパス
  Future<void> deleteDocument(String path) async {
    try {
      await _document(path).delete();
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの削除に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ドキュメント取得
  /// [path] ドキュメントパス
  /// 戻り値: ドキュメントスナップショット
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String path) async {
    try {
      return await _document(path).get();
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの取得に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// コレクション取得
  /// [path] コレクションパス
  /// 戻り値: クエリスナップショット
  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String path) async {
    try {
      return await _collection(path).get();
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'コレクションの取得に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// クエリ実行
  /// [query] 実行するクエリ
  Future<QuerySnapshot<Map<String, dynamic>>> executeQuery(
      Query<Map<String, dynamic>> query) async {
    try {
      return await query.get();
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'クエリの実行に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ドキュメントのリアルタイム監視
  /// [path] ドキュメントパス
  /// 戻り値: ドキュメントスナップショットのストリーム
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDocument(String path) {
    try {
      return _document(path).snapshots();
    } catch (e) {
      throw FirestoreException(
        'ドキュメントの監視設定に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// コレクションのリアルタイム監視
  /// [path] コレクションパス
  /// 戻り値: クエリスナップショットのストリーム
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(String path) {
    try {
      return _collection(path).snapshots();
    } catch (e) {
      throw FirestoreException(
        'コレクションの監視設定に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// バッチ処理の実行
  /// [operations] バッチ操作のリスト
  Future<void> executeBatch(List<BatchOperation> operations) async {
    if (operations.isEmpty) return;

    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.set:
            batch.set(
              _document(operation.path),
              operation.data!,
            );
            break;
          case BatchOperationType.update:
            batch.update(
              _document(operation.path),
              operation.data!,
            );
            break;
          case BatchOperationType.delete:
            batch.delete(_document(operation.path));
            break;
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'バッチ処理の実行に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// トランザクション実行
  /// [transactionHandler] トランザクション処理
  Future<T> executeTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } on FirebaseException catch (e) {
      throw FirestoreException._fromFirebaseException(e);
    } catch (e) {
      throw FirestoreException(
        'トランザクションの実行に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// ユーザーIDの重複チェック
  /// [customUserId] チェックするカスタムユーザーID
  /// [excludeUserId] 除外するユーザーID (自分自身の更新時)
  /// 戻り値: true=重複あり, false=利用可能
  Future<bool> isUserIdDuplicate(String customUserId, {String? excludeUserId}) async {
    try {
      final query = usersCollection
          .where('userId', isEqualTo: customUserId)
          .where('isActive', isEqualTo: true) // アクティブなユーザーのみチェック
          .limit(1);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        return false; // 重複なし
      }

      // 除外するユーザーIDが指定されている場合
      if (excludeUserId != null) {
        final doc = snapshot.docs.first;
        return doc.id != excludeUserId; // 自分以外に同じIDがあるかチェック
      }

      return true; // 重複あり
    } catch (e) {
      throw FirestoreException(
        'ユーザーID重複チェックに失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// 接続状態チェック
  /// 戻り値: true=オンライン, false=オフライン
  Future<bool> isOnline() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// オフラインモード有効化
  Future<void> enableOfflineMode() async {
    try {
      await _firestore.disableNetwork();
    } catch (e) {
      throw FirestoreException(
        'オフラインモードの有効化に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }

  /// オンラインモード復帰
  Future<void> enableOnlineMode() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      throw FirestoreException(
        'オンラインモードの復帰に失敗しました: $e',
        FirestoreErrorCode.unknown,
      );
    }
  }
}

/// バッチ操作タイプ
enum BatchOperationType { set, update, delete }

/// バッチ操作
class BatchOperation {
  final BatchOperationType type;
  final String path;
  final Map<String, dynamic>? data;

  const BatchOperation({
    required this.type,
    required this.path,
    this.data,
  });

  /// Create操作
  factory BatchOperation.create(String path, Map<String, dynamic> data) {
    return BatchOperation(
      type: BatchOperationType.set,
      path: path,
      data: data,
    );
  }

  /// Update操作
  factory BatchOperation.update(String path, Map<String, dynamic> data) {
    return BatchOperation(
      type: BatchOperationType.update,
      path: path,
      data: data,
    );
  }

  /// Delete操作
  factory BatchOperation.delete(String path) {
    return BatchOperation(
      type: BatchOperationType.delete,
      path: path,
    );
  }
}

/// Firestore エラー種別
enum FirestoreErrorCode {
  permissionDenied,
  notFound,
  alreadyExists,
  networkError,
  unknown,
}

/// Firestore カスタム例外
class FirestoreException implements Exception {
  final String message;
  final FirestoreErrorCode code;

  const FirestoreException(this.message, this.code);

  factory FirestoreException._fromFirebaseException(FirebaseException e) {
    FirestoreErrorCode code;
    String message;

    switch (e.code) {
      case 'permission-denied':
        code = FirestoreErrorCode.permissionDenied;
        message = AppStrings.firestorePermissionDenied;
        break;
      case 'not-found':
        code = FirestoreErrorCode.notFound;
        message = AppStrings.firestoreNotFound;
        break;
      case 'already-exists':
        code = FirestoreErrorCode.alreadyExists;
        message = AppStrings.firestoreAlreadyExists;
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        code = FirestoreErrorCode.networkError;
        message = AppStrings.firestoreNetworkError;
        break;
      default:
        code = FirestoreErrorCode.unknown;
        message = '${AppStrings.firestoreUnknownError}: ${e.message}';
    }

    return FirestoreException(message, code);
  }

  @override
  String toString() => 'FirestoreException: $message (Code: $code)';
}