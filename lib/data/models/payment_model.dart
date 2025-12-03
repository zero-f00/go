import 'package:cloud_firestore/cloud_firestore.dart';

/// 支払いステータス
enum PaymentStatus {
  pending,    // 未払い
  submitted,  // 証跡提出済み
  verified,   // 確認済み
  disputed,   // 問題あり
}

/// 支払い証跡の種類
enum EvidenceType {
  screenshot,  // スクリーンショット
  receipt,     // 領収書
  bankSlip,    // 振込明細
  other,       // その他
}

/// 支払い記録データモデル
class PaymentRecord {
  final String id;
  final String eventId;
  final String participantId;
  final String participantName;
  final int amount;
  final PaymentStatus status;
  final String? evidenceUrl;
  final EvidenceType? evidenceType;
  final String? evidenceFileName;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? participantNotes;
  final String? organizerNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentRecord({
    required this.id,
    required this.eventId,
    required this.participantId,
    required this.participantName,
    required this.amount,
    required this.status,
    this.evidenceUrl,
    this.evidenceType,
    this.evidenceFileName,
    this.submittedAt,
    this.verifiedAt,
    this.participantNotes,
    this.organizerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから PaymentRecord を作成
  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PaymentRecord(
      id: doc.id,
      eventId: data['eventId'] as String,
      participantId: data['participantId'] as String,
      participantName: data['participantName'] as String,
      amount: data['amount'] as int,
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      evidenceUrl: data['evidenceUrl'] as String?,
      evidenceType: data['evidenceType'] != null
          ? EvidenceType.values.firstWhere(
              (type) => type.name == data['evidenceType'],
              orElse: () => EvidenceType.other,
            )
          : null,
      evidenceFileName: data['evidenceFileName'] as String?,
      submittedAt: data['submittedAt'] != null
          ? (data['submittedAt'] as Timestamp).toDate()
          : null,
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      participantNotes: data['participantNotes'] as String?,
      organizerNotes: data['organizerNotes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// PaymentRecord を Firestore ドキュメント形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'participantId': participantId,
      'participantName': participantName,
      'amount': amount,
      'status': status.name,
      'evidenceUrl': evidenceUrl,
      'evidenceType': evidenceType?.name,
      'evidenceFileName': evidenceFileName,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'participantNotes': participantNotes,
      'organizerNotes': organizerNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// コピーメソッド
  PaymentRecord copyWith({
    String? id,
    String? eventId,
    String? participantId,
    String? participantName,
    int? amount,
    PaymentStatus? status,
    String? evidenceUrl,
    EvidenceType? evidenceType,
    String? evidenceFileName,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? participantNotes,
    String? organizerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
      evidenceType: evidenceType ?? this.evidenceType,
      evidenceFileName: evidenceFileName ?? this.evidenceFileName,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      participantNotes: participantNotes ?? this.participantNotes,
      organizerNotes: organizerNotes ?? this.organizerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 支払い統計データ
class PaymentSummary {
  final int totalParticipants;
  final int paidCount;
  final int pendingCount;
  final int disputedCount;
  final int totalAmount;
  final int collectedAmount;
  final int pendingAmount;

  const PaymentSummary({
    required this.totalParticipants,
    required this.paidCount,
    required this.pendingCount,
    required this.disputedCount,
    required this.totalAmount,
    required this.collectedAmount,
    required this.pendingAmount,
  });
}