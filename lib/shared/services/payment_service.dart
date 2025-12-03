import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../data/models/payment_model.dart';

/// Payment操作の例外クラス
class PaymentServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const PaymentServiceException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() {
    return 'PaymentServiceException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// 支払い証跡アップロード結果
class EvidenceUploadResult {
  final String downloadUrl;
  final String storagePath;
  final String fileName;

  const EvidenceUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
  });
}

/// Payment管理サービス
class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _paymentCollection = 'payment_records';

  /// イベント参加時に支払い記録を初期化
  static Future<String> createPaymentRecord({
    required String eventId,
    required String participantId,
    required String participantName,
    required int amount,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const PaymentServiceException('ユーザーが認証されていません');
      }

      final now = DateTime.now();

      final paymentData = PaymentRecord(
        id: '',
        eventId: eventId,
        participantId: participantId,
        participantName: participantName,
        amount: amount,
        status: PaymentStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore
          .collection(_paymentCollection)
          .add(paymentData.toFirestore());

      return docRef.id;
    } catch (e) {
      throw PaymentServiceException(
        '支払い記録の作成に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// 支払い証跡をアップロード
  static Future<EvidenceUploadResult> uploadPaymentEvidence({
    required String paymentId,
    required File evidenceFile,
    required EvidenceType evidenceType,
    String? notes,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const PaymentServiceException('ユーザーが認証されていません');
      }

      // ファイルをStorageにアップロード
      final fileName = 'payment_evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'payment_evidence/$paymentId/$fileName';

      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'paymentId': paymentId,
          'evidenceType': evidenceType.name,
        },
      );

      final uploadTask = ref.putFile(evidenceFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 支払い記録を更新
      await _firestore
          .collection(_paymentCollection)
          .doc(paymentId)
          .update({
        'evidenceUrl': downloadUrl,
        'evidenceType': evidenceType.name,
        'evidenceFileName': fileName,
        'submittedAt': Timestamp.fromDate(DateTime.now()),
        'participantNotes': notes,
        'status': PaymentStatus.submitted.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return EvidenceUploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
        fileName: fileName,
      );
    } catch (e) {
      throw PaymentServiceException(
        '支払い証跡のアップロードに失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// 運営者による支払い確認
  static Future<void> verifyPayment({
    required String paymentId,
    required bool isVerified,
    String? organizerNotes,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const PaymentServiceException('ユーザーが認証されていません');
      }

      final status = isVerified ? PaymentStatus.verified : PaymentStatus.disputed;

      await _firestore
          .collection(_paymentCollection)
          .doc(paymentId)
          .update({
        'status': status.name,
        'verifiedAt': isVerified ? Timestamp.fromDate(DateTime.now()) : null,
        'organizerNotes': organizerNotes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw PaymentServiceException(
        '支払い確認の更新に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// イベントの支払い記録一覧を取得
  static Future<List<PaymentRecord>> getPaymentRecords({
    required String eventId,
    PaymentStatus? statusFilter,
  }) async {
    try {
      Query query = _firestore
          .collection(_paymentCollection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw PaymentServiceException(
        '支払い記録の取得に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// イベントの支払い記録をリアルタイム監視
  static Stream<List<PaymentRecord>> getPaymentRecordsStream({
    required String eventId,
    PaymentStatus? statusFilter,
  }) {
    try {
      Query query = _firestore
          .collection(_paymentCollection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.name);
      }

      return query.snapshots().map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => PaymentRecord.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Stream.error(PaymentServiceException(
        'リアルタイム支払い記録の監視に失敗しました: ${e.toString()}',
        originalException: e,
      ));
    }
  }

  /// 特定参加者の支払い記録を取得
  static Future<PaymentRecord?> getParticipantPaymentRecord({
    required String eventId,
    required String participantId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_paymentCollection)
          .where('eventId', isEqualTo: eventId)
          .where('participantId', isEqualTo: participantId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return PaymentRecord.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw PaymentServiceException(
        '参加者の支払い記録取得に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// イベントの支払い統計を取得
  static Future<PaymentSummary> getPaymentSummary({
    required String eventId,
  }) async {
    try {
      final paymentRecords = await getPaymentRecords(eventId: eventId);

      int paidCount = 0;
      int pendingCount = 0;
      int disputedCount = 0;
      int collectedAmount = 0;
      int totalAmount = 0;

      for (final record in paymentRecords) {
        totalAmount += record.amount;

        switch (record.status) {
          case PaymentStatus.verified:
            paidCount++;
            collectedAmount += record.amount;
            break;
          case PaymentStatus.pending:
          case PaymentStatus.submitted:
            pendingCount++;
            break;
          case PaymentStatus.disputed:
            disputedCount++;
            break;
        }
      }

      return PaymentSummary(
        totalParticipants: paymentRecords.length,
        paidCount: paidCount,
        pendingCount: pendingCount,
        disputedCount: disputedCount,
        totalAmount: totalAmount,
        collectedAmount: collectedAmount,
        pendingAmount: totalAmount - collectedAmount,
      );
    } catch (e) {
      throw PaymentServiceException(
        '支払い統計の取得に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// 支払い記録を削除
  static Future<void> deletePaymentRecord({
    required String paymentId,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw const PaymentServiceException('ユーザーが認証されていません');
      }

      // 証跡画像も削除
      final paymentDoc = await _firestore
          .collection(_paymentCollection)
          .doc(paymentId)
          .get();

      if (paymentDoc.exists) {
        final paymentData = paymentDoc.data() as Map<String, dynamic>;
        final evidenceUrl = paymentData['evidenceUrl'] as String?;

        if (evidenceUrl != null) {
          try {
            final ref = _storage.refFromURL(evidenceUrl);
            await ref.delete();
          } catch (e) {
            // ファイル削除に失敗しても記録は削除する
            // エラーログは上位層で処理する
          }
        }
      }

      await _firestore
          .collection(_paymentCollection)
          .doc(paymentId)
          .delete();
    } catch (e) {
      throw PaymentServiceException(
        '支払い記録の削除に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }

  /// 支払いステータスを更新
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    String? notes,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (notes != null) {
        updateData['organizerNotes'] = notes;
      }

      if (status == PaymentStatus.verified) {
        updateData['verifiedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection(_paymentCollection)
          .doc(paymentId)
          .update(updateData);
    } catch (e) {
      throw PaymentServiceException(
        '支払いステータスの更新に失敗しました: ${e.toString()}',
        originalException: e,
      );
    }
  }
}