import 'package:cloud_firestore/cloud_firestore.dart';

/// 違反記録モデル
class ViolationRecord {
  final String? id;
  final String eventId;
  final String eventName;
  final String violatedUserId;
  final String reportedByUserId;
  final String reportedByUserName;
  final ViolationType violationType;
  final String description;
  final ViolationSeverity severity;
  final DateTime reportedAt;
  final ViolationStatus status;
  final String? penalty;
  final String? notes;
  final DateTime? resolvedAt;
  final String? resolvedByUserId;
  final String? appealText;
  final DateTime? appealedAt;
  final AppealStatus? appealStatus;
  final String? appealResponse;
  final DateTime? appealResolvedAt;
  final String? appealResolvedByUserId;
  final DateTime? appealDeadline;
  final bool canProcessWithoutAppeal;

  const ViolationRecord({
    this.id,
    required this.eventId,
    required this.eventName,
    required this.violatedUserId,
    required this.reportedByUserId,
    required this.reportedByUserName,
    required this.violationType,
    required this.description,
    required this.severity,
    required this.reportedAt,
    required this.status,
    this.penalty,
    this.notes,
    this.resolvedAt,
    this.resolvedByUserId,
    this.appealText,
    this.appealedAt,
    this.appealStatus,
    this.appealResponse,
    this.appealResolvedAt,
    this.appealResolvedByUserId,
    this.appealDeadline,
    this.canProcessWithoutAppeal = false,
  });

  /// Firestoreドキュメントから変換
  factory ViolationRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViolationRecord.fromMap(data, doc.id);
  }

  /// Mapから変換
  factory ViolationRecord.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return ViolationRecord(
      id: documentId ?? map['id'],
      eventId: map['eventId'] ?? '',
      eventName: map['eventName'] ?? '',
      violatedUserId: map['violatedUserId'] ?? '',
      reportedByUserId: map['reportedByUserId'] ?? '',
      reportedByUserName: map['reportedByUserName'] ?? '',
      violationType: ViolationType.values.firstWhere(
        (e) => e.name == map['violationType'],
        orElse: () => ViolationType.other,
      ),
      description: map['description'] ?? '',
      severity: ViolationSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ViolationSeverity.minor,
      ),
      reportedAt: map['reportedAt'] is Timestamp
          ? (map['reportedAt'] as Timestamp).toDate()
          : DateTime.parse(map['reportedAt'] ?? DateTime.now().toIso8601String()),
      status: ViolationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ViolationStatus.pending,
      ),
      penalty: map['penalty'],
      notes: map['notes'],
      resolvedAt: map['resolvedAt'] != null
          ? map['resolvedAt'] is Timestamp
              ? (map['resolvedAt'] as Timestamp).toDate()
              : DateTime.parse(map['resolvedAt'])
          : null,
      resolvedByUserId: map['resolvedByUserId'],
      appealText: map['appealText'],
      appealedAt: map['appealedAt'] != null
          ? map['appealedAt'] is Timestamp
              ? (map['appealedAt'] as Timestamp).toDate()
              : DateTime.parse(map['appealedAt'])
          : null,
      appealStatus: map['appealStatus'] != null
          ? AppealStatus.values.firstWhere(
              (e) => e.name == map['appealStatus'],
              orElse: () => AppealStatus.pending,
            )
          : null,
      appealResponse: map['appealResponse'],
      appealResolvedAt: map['appealResolvedAt'] != null
          ? map['appealResolvedAt'] is Timestamp
              ? (map['appealResolvedAt'] as Timestamp).toDate()
              : DateTime.parse(map['appealResolvedAt'])
          : null,
      appealResolvedByUserId: map['appealResolvedByUserId'],
      appealDeadline: map['appealDeadline'] != null
          ? map['appealDeadline'] is Timestamp
              ? (map['appealDeadline'] as Timestamp).toDate()
              : DateTime.parse(map['appealDeadline'])
          : null,
      canProcessWithoutAppeal: map['canProcessWithoutAppeal'] ?? false,
    );
  }

  /// Mapに変換
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'violatedUserId': violatedUserId,
      'reportedByUserId': reportedByUserId,
      'reportedByUserName': reportedByUserName,
      'violationType': violationType.name,
      'description': description,
      'severity': severity.name,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'status': status.name,
      'penalty': penalty,
      'notes': notes,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedByUserId': resolvedByUserId,
      'appealText': appealText,
      'appealedAt': appealedAt != null ? Timestamp.fromDate(appealedAt!) : null,
      'appealStatus': appealStatus?.name,
      'appealResponse': appealResponse,
      'appealResolvedAt': appealResolvedAt != null ? Timestamp.fromDate(appealResolvedAt!) : null,
      'appealResolvedByUserId': appealResolvedByUserId,
      'appealDeadline': appealDeadline != null ? Timestamp.fromDate(appealDeadline!) : null,
      'canProcessWithoutAppeal': canProcessWithoutAppeal,
    };
  }

  /// JSONに変換
  Map<String, dynamic> toJson() => toMap();

  /// JSONから変換
  factory ViolationRecord.fromJson(Map<String, dynamic> json) {
    return ViolationRecord.fromMap(json);
  }

  /// コピー作成
  ViolationRecord copyWith({
    String? id,
    String? eventId,
    String? eventName,
    String? violatedUserId,
    String? reportedByUserId,
    String? reportedByUserName,
    ViolationType? violationType,
    String? description,
    ViolationSeverity? severity,
    DateTime? reportedAt,
    ViolationStatus? status,
    String? penalty,
    String? notes,
    DateTime? resolvedAt,
    String? resolvedByUserId,
    String? appealText,
    DateTime? appealedAt,
    AppealStatus? appealStatus,
    String? appealResponse,
    DateTime? appealResolvedAt,
    String? appealResolvedByUserId,
    DateTime? appealDeadline,
    bool? canProcessWithoutAppeal,
  }) {
    return ViolationRecord(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      violatedUserId: violatedUserId ?? this.violatedUserId,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      reportedByUserName: reportedByUserName ?? this.reportedByUserName,
      violationType: violationType ?? this.violationType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      reportedAt: reportedAt ?? this.reportedAt,
      status: status ?? this.status,
      penalty: penalty ?? this.penalty,
      notes: notes ?? this.notes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByUserId: resolvedByUserId ?? this.resolvedByUserId,
      appealText: appealText ?? this.appealText,
      appealedAt: appealedAt ?? this.appealedAt,
      appealStatus: appealStatus ?? this.appealStatus,
      appealResponse: appealResponse ?? this.appealResponse,
      appealResolvedAt: appealResolvedAt ?? this.appealResolvedAt,
      appealResolvedByUserId: appealResolvedByUserId ?? this.appealResolvedByUserId,
      appealDeadline: appealDeadline ?? this.appealDeadline,
      canProcessWithoutAppeal: canProcessWithoutAppeal ?? this.canProcessWithoutAppeal,
    );
  }

  @override
  String toString() {
    return 'ViolationRecord(id: $id, eventId: $eventId, violatedUserId: $violatedUserId, violationType: $violationType, severity: $severity, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ViolationRecord &&
        other.id == id &&
        other.eventId == eventId &&
        other.violatedUserId == violatedUserId &&
        other.reportedByUserId == reportedByUserId &&
        other.violationType == violationType &&
        other.severity == severity &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      eventId,
      violatedUserId,
      reportedByUserId,
      violationType,
      severity,
      status,
    );
  }
}

/// 違反タイプ
enum ViolationType {
  harassment('ハラスメント'),
  cheating('チート・不正行為'),
  spam('スパム・迷惑行為'),
  abusiveLanguage('暴言・不適切な発言'),
  noShow('無断欠席'),
  disruptiveBehavior('妨害行為'),
  ruleViolation('ルール違反'),
  other('その他');

  const ViolationType(this.displayName);

  final String displayName;

  /// 説明文を取得
  String get description {
    switch (this) {
      case ViolationType.harassment:
        return '他の参加者に対する嫌がらせやいじめ行為';
      case ViolationType.cheating:
        return '不正なソフトウェアの使用や規約違反';
      case ViolationType.spam:
        return 'スパムメッセージや迷惑行為';
      case ViolationType.abusiveLanguage:
        return '暴言、差別的発言、不適切な言動';
      case ViolationType.noShow:
        return 'イベント参加申請後の無断不参加';
      case ViolationType.disruptiveBehavior:
        return 'イベント進行を妨害する行為';
      case ViolationType.ruleViolation:
        return 'イベントルールへの違反行為';
      case ViolationType.other:
        return 'その他の規約違反行為';
    }
  }
}

/// 違反の重要度
enum ViolationSeverity {
  minor('軽微'),
  moderate('中程度'),
  severe('重大');

  const ViolationSeverity(this.displayName);

  final String displayName;

  /// 説明文を取得
  String get description {
    switch (this) {
      case ViolationSeverity.minor:
        return '軽微な違反。注意や警告で対応可能';
      case ViolationSeverity.moderate:
        return '中程度の違反。一時的な制限措置が必要';
      case ViolationSeverity.severe:
        return '重大な違反。厳重な処分が必要';
    }
  }

  /// ペナルティレベルを取得
  int get penaltyLevel {
    switch (this) {
      case ViolationSeverity.minor:
        return 1;
      case ViolationSeverity.moderate:
        return 2;
      case ViolationSeverity.severe:
        return 3;
    }
  }
}

/// 違反のステータス
enum ViolationStatus {
  pending('未処理'),
  underReview('調査中'),
  resolved('処理済み'),
  dismissed('却下');

  const ViolationStatus(this.displayName);

  final String displayName;

  /// 説明文を取得
  String get description {
    switch (this) {
      case ViolationStatus.pending:
        return '報告されたが未だ対応していない状態';
      case ViolationStatus.underReview:
        return '詳細調査中の状態';
      case ViolationStatus.resolved:
        return '適切な処分を行い完了した状態';
      case ViolationStatus.dismissed:
        return '調査の結果、違反に該当しないと判断された状態';
    }
  }

  /// 処理が必要かどうか
  bool get requiresAction {
    return this == ViolationStatus.pending || this == ViolationStatus.underReview;
  }
}

/// 違反統計データ
class ViolationStatistics {
  final int totalViolations;
  final int pendingViolations;
  final int resolvedViolations;
  final int dismissedViolations;
  final Map<ViolationType, int> typeDistribution;
  final Map<ViolationSeverity, int> severityDistribution;
  final List<ViolationRecord> recentViolations;

  const ViolationStatistics({
    required this.totalViolations,
    required this.pendingViolations,
    required this.resolvedViolations,
    required this.dismissedViolations,
    required this.typeDistribution,
    required this.severityDistribution,
    required this.recentViolations,
  });

  factory ViolationStatistics.fromViolations(List<ViolationRecord> violations) {
    final typeDistribution = <ViolationType, int>{};
    final severityDistribution = <ViolationSeverity, int>{};

    for (final violation in violations) {
      typeDistribution[violation.violationType] =
          (typeDistribution[violation.violationType] ?? 0) + 1;
      severityDistribution[violation.severity] =
          (severityDistribution[violation.severity] ?? 0) + 1;
    }

    final recentViolations = List<ViolationRecord>.from(violations)
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

    return ViolationStatistics(
      totalViolations: violations.length,
      pendingViolations: violations.where((v) => v.status == ViolationStatus.pending).length,
      resolvedViolations: violations.where((v) => v.status == ViolationStatus.resolved).length,
      dismissedViolations: violations.where((v) => v.status == ViolationStatus.dismissed).length,
      typeDistribution: typeDistribution,
      severityDistribution: severityDistribution,
      recentViolations: recentViolations.take(10).toList(),
    );
  }
}

/// 異議申立のステータス
enum AppealStatus {
  pending('審査待ち'),
  underReview('審査中'),
  approved('承認'),
  rejected('却下');

  const AppealStatus(this.displayName);

  final String displayName;

  /// 説明文を取得
  String get description {
    switch (this) {
      case AppealStatus.pending:
        return '異議申立が提出され、審査待ちの状態';
      case AppealStatus.underReview:
        return '運営による詳細審査中の状態';
      case AppealStatus.approved:
        return '異議が認められ、違反記録が取り消された状態';
      case AppealStatus.rejected:
        return '異議が却下され、違反記録が維持された状態';
    }
  }

  /// 処理が必要かどうか
  bool get requiresAction {
    return this == AppealStatus.pending || this == AppealStatus.underReview;
  }
}