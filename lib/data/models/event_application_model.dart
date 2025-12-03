import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// イベント参加申込モデル
class EventApplication extends Equatable {
  /// ドキュメントID
  final String? id;

  /// イベントID
  final String eventId;

  /// 申込者のユーザーID（カスタムユーザーID）
  final String userId;

  /// ゲームプロフィールID
  final String gameProfileId;

  /// 申込ステータス
  final ApplicationStatus status;

  /// 申込日時
  final DateTime appliedAt;

  /// 承認/拒否日時
  final DateTime? processedAt;

  /// 承認/拒否者のユーザーID
  final String? processedBy;

  /// 管理者コメント
  final String? adminComment;

  /// 申込者のメモ・メッセージ
  final String? applicantMessage;

  const EventApplication({
    this.id,
    required this.eventId,
    required this.userId,
    required this.gameProfileId,
    required this.status,
    required this.appliedAt,
    this.processedAt,
    this.processedBy,
    this.adminComment,
    this.applicantMessage,
  });

  /// 新規申込作成
  factory EventApplication.create({
    required String eventId,
    required String userId,
    required String gameProfileId,
    String? applicantMessage,
  }) {
    return EventApplication(
      eventId: eventId,
      userId: userId,
      gameProfileId: gameProfileId,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
      applicantMessage: applicantMessage,
    );
  }

  /// Firestoreから作成
  factory EventApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventApplication(
      id: doc.id,
      eventId: data['eventId'] as String,
      userId: data['userId'] as String,
      gameProfileId: data['gameProfileId'] as String,
      status: ApplicationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'] as String?,
      adminComment: data['adminComment'] as String?,
      applicantMessage: data['applicantMessage'] as String?,
    );
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'gameProfileId': gameProfileId,
      'status': status.name,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'processedAt': processedAt != null
          ? Timestamp.fromDate(processedAt!)
          : null,
      'processedBy': processedBy,
      'adminComment': adminComment,
      'applicantMessage': applicantMessage,
    };
  }

  /// コピーを作成
  EventApplication copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? gameProfileId,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? processedAt,
    String? processedBy,
    String? adminComment,
    String? applicantMessage,
  }) {
    return EventApplication(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      gameProfileId: gameProfileId ?? this.gameProfileId,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      processedAt: processedAt ?? this.processedAt,
      processedBy: processedBy ?? this.processedBy,
      adminComment: adminComment ?? this.adminComment,
      applicantMessage: applicantMessage ?? this.applicantMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        gameProfileId,
        status,
        appliedAt,
        processedAt,
        processedBy,
        adminComment,
        applicantMessage,
      ];
}

/// 申込ステータス
enum ApplicationStatus {
  pending,   // 承認待ち
  approved,  // 承認済み
  rejected,  // 拒否
  waitlist,  // 補欠
  cancelled, // 申込者による取り消し
}

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return '承認待ち';
      case ApplicationStatus.approved:
        return '承認済み';
      case ApplicationStatus.rejected:
        return '拒否';
      case ApplicationStatus.waitlist:
        return '補欠';
      case ApplicationStatus.cancelled:
        return '取り消し';
    }
  }
}