import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/violation_record_model.dart';

/// 違反管理リポジトリのプロバイダー
final violationRepositoryProvider = Provider<ViolationRepository>((ref) {
  return ViolationRepository();
});

/// 違反管理リポジトリ
class ViolationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// コレクション名
  static const String _collectionName = 'violations';

  /// コレクション参照を取得
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// 公開用コレクション参照（テスト・デバッグ用）
  CollectionReference<Map<String, dynamic>> get collection => _collection;

  /// 違反記録を作成
  Future<String> createViolation(ViolationRecord violation) async {
    try {
      final doc = await _collection.add(violation.toMap());
      return doc.id;
    } catch (e) {
      throw Exception('違反記録の作成に失敗しました: $e');
    }
  }

  /// 違反記録を更新
  Future<void> updateViolation(ViolationRecord violation) async {
    try {
      if (violation.id == null) {
        throw ArgumentError('違反記録のIDが指定されていません');
      }
      await _collection.doc(violation.id).update(violation.toMap());
    } catch (e) {
      throw Exception('違反記録の更新に失敗しました: $e');
    }
  }

  /// 違反記録を部分更新
  Future<void> updateViolationById(String violationId, Map<String, dynamic> updateData) async {
    try {
      await _collection.doc(violationId).update(updateData);
    } catch (e) {
      throw Exception('違反記録の更新に失敗しました: $e');
    }
  }

  /// 違反記録を削除
  Future<void> deleteViolation(String violationId) async {
    try {
      await _collection.doc(violationId).delete();
    } catch (e) {
      throw Exception('違反記録の削除に失敗しました: $e');
    }
  }

  /// 違反記録を取得（ID指定）
  Future<ViolationRecord?> getViolation(String violationId) async {
    try {
      final doc = await _collection.doc(violationId).get();
      if (!doc.exists) return null;
      return ViolationRecord.fromFirestore(doc);
    } catch (e) {
      throw Exception('違反記録の取得に失敗しました: $e');
    }
  }

  /// イベントの違反記録を取得
  Future<List<ViolationRecord>> getViolationsByEvent(String eventId) async {
    try {
      final query = await _collection
          .where('eventId', isEqualTo: eventId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('イベントの違反記録取得に失敗しました: $e');
    }
  }

  /// ユーザーの違反記録を取得
  Future<List<ViolationRecord>> getViolationsByUser(String userId) async {
    try {
      final query = await _collection
          .where('violatedUserId', isEqualTo: userId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ユーザーの違反記録取得に失敗しました: $e');
    }
  }

  /// 運営者が報告した違反記録を取得
  Future<List<ViolationRecord>> getViolationsByReporter(String reporterId) async {
    try {
      final query = await _collection
          .where('reportedByUserId', isEqualTo: reporterId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('報告者の違反記録取得に失敗しました: $e');
    }
  }

  /// ステータス別違反記録を取得
  Future<List<ViolationRecord>> getViolationsByStatus(
    String eventId,
    ViolationStatus status,
  ) async {
    try {
      final query = await _collection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: status.name)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ステータス別違反記録取得に失敗しました: $e');
    }
  }

  /// 重要度別違反記録を取得
  Future<List<ViolationRecord>> getViolationsBySeverity(
    String eventId,
    ViolationSeverity severity,
  ) async {
    try {
      final query = await _collection
          .where('eventId', isEqualTo: eventId)
          .where('severity', isEqualTo: severity.name)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('重要度別違反記録取得に失敗しました: $e');
    }
  }

  /// 期間指定で違反記録を取得
  Future<List<ViolationRecord>> getViolationsByDateRange(
    String eventId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _collection
          .where('eventId', isEqualTo: eventId)
          .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('reportedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('期間指定違反記録取得に失敗しました: $e');
    }
  }

  /// 未処理の違反記録を取得
  Future<List<ViolationRecord>> getPendingViolations(String eventId) async {
    try {
      final query = await _collection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: ViolationStatus.pending.name)
          .orderBy('reportedAt', descending: false) // 古い順で表示
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('未処理違反記録取得に失敗しました: $e');
    }
  }

  /// 違反記録の統計を取得
  Future<ViolationStatistics> getViolationStatistics(String eventId) async {
    try {
      final violations = await getViolationsByEvent(eventId);
      return ViolationStatistics.fromViolations(violations);
    } catch (e) {
      throw Exception('違反記録統計取得に失敗しました: $e');
    }
  }

  /// 特定ユーザーの過去の違反履歴を取得（運営者向け）
  /// 運営者が参加者の過去の違反歴を確認するため
  Future<List<ViolationRecord>> getUserViolationHistory(
    String userId,
    String reporterId,
  ) async {
    try {
      // 報告者が関わったイベントでのその参加者の違反履歴を取得
      final query = await _collection
          .where('violatedUserId', isEqualTo: userId)
          .where('reportedByUserId', isEqualTo: reporterId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('ユーザー違反履歴取得に失敗しました: $e');
    }
  }

  /// 運営者が見ることができる全ての違反記録を取得
  Future<List<ViolationRecord>> getViolationsForOrganizer(String organizerId) async {
    try {
      final query = await _collection
          .where('reportedByUserId', isEqualTo: organizerId)
          .orderBy('reportedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('運営者向け違反記録取得に失敗しました: $e');
    }
  }

  /// 違反記録のリアルタイム監視
  Stream<List<ViolationRecord>> watchViolationsByEvent(String eventId) {
    try {
      return _collection
          .where('eventId', isEqualTo: eventId)
          .orderBy('reportedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ViolationRecord.fromFirestore(doc))
              .toList());
    } catch (e) {
      throw Exception('違反記録のリアルタイム監視に失敗しました: $e');
    }
  }

  /// 違反記録の一括更新（ステータス変更など）
  Future<void> batchUpdateViolations(
    List<String> violationIds,
    Map<String, dynamic> updates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final violationId in violationIds) {
        batch.update(_collection.doc(violationId), updates);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('違反記録の一括更新に失敗しました: $e');
    }
  }

  /// 違反記録の検索
  Future<List<ViolationRecord>> searchViolations({
    String? eventId,
    String? violatedUserId,
    ViolationType? violationType,
    ViolationSeverity? severity,
    ViolationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _collection;

      // 条件を追加
      if (eventId != null) {
        query = query.where('eventId', isEqualTo: eventId);
      }

      if (violatedUserId != null) {
        query = query.where('violatedUserId', isEqualTo: violatedUserId);
      }

      if (violationType != null) {
        query = query.where('violationType', isEqualTo: violationType.name);
      }

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity.name);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (startDate != null) {
        query = query.where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('reportedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // 並び順
      query = query.orderBy('reportedAt', descending: true);

      // 制限
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ViolationRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('違反記録の検索に失敗しました: $e');
    }
  }
}