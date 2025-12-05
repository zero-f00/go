import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 試合ステータス
enum MatchStatus {
  scheduled('scheduled', '開催予定'),
  inProgress('in_progress', '進行中'),
  completed('completed', '完了');

  const MatchStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MatchStatus.scheduled,
    );
  }
}

/// 試合結果モデル
class MatchResult extends Equatable {
  /// ドキュメントID
  final String? id;

  /// イベントID
  final String eventId;

  /// 試合名
  final String matchName;

  /// 参加者（個人戦の場合はユーザーID、チーム戦の場合はグループID）
  final List<String> participants;

  /// 勝者（個人戦の場合はユーザーID、チーム戦の場合はグループID）
  final String? winner;

  /// スコア（参加者ID -> スコア）
  final Map<String, int> scores;

  /// 個人スコア（チーム戦の場合のみ使用: ユーザーID -> スコア）
  final Map<String, int>? individualScores;

  /// 個人成績詳細（MVP、キル数など任意のデータ）
  final Map<String, Map<String, dynamic>>? individualStats;

  /// 試合完了日時
  final DateTime? completedAt;

  /// 試合作成日時
  final DateTime createdAt;

  /// 試合更新日時
  final DateTime updatedAt;

  /// チーム戦かどうか
  final bool isTeamMatch;

  /// 試合形式（例: トーナメント、リーグ戦、フリー対戦）
  final String? matchFormat;

  /// 備考
  final String? notes;

  /// 運営側メモ（ユーザー閲覧可能）
  final String? adminPublicNotes;

  /// 運営側メモ（運営者のみ閲覧可能）
  final String? adminPrivateNotes;

  /// 試合ステータス
  final MatchStatus status;

  /// エビデンス画像URL一覧
  final List<String> evidenceImages;

  /// エビデンス画像のメタデータ（アップロード者、アップロード日時など）
  final Map<String, Map<String, dynamic>>? evidenceImageMetadata;

  const MatchResult({
    this.id,
    required this.eventId,
    required this.matchName,
    required this.participants,
    this.winner,
    required this.scores,
    this.individualScores,
    this.individualStats,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isTeamMatch,
    this.matchFormat,
    this.notes,
    this.adminPublicNotes,
    this.adminPrivateNotes,
    this.status = MatchStatus.scheduled,
    this.evidenceImages = const [],
    this.evidenceImageMetadata,
  });

  /// Firestoreドキュメントから作成
  factory MatchResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchResult(
      id: doc.id,
      eventId: data['eventId'] as String,
      matchName: data['matchName'] as String,
      participants: List<String>.from(data['participants'] as List),
      winner: data['winner'] as String?,
      scores: Map<String, int>.from(data['scores'] as Map),
      individualScores: data['individualScores'] != null
          ? Map<String, int>.from(data['individualScores'] as Map)
          : null,
      individualStats: data['individualStats'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (data['individualStats'] as Map).map(
                (key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
              ),
            )
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isTeamMatch: data['isTeamMatch'] as bool? ?? false,
      matchFormat: data['matchFormat'] as String?,
      notes: data['notes'] as String?,
      adminPublicNotes: data['adminPublicNotes'] as String?,
      adminPrivateNotes: data['adminPrivateNotes'] as String?,
      status: data['status'] != null
          ? MatchStatus.fromString(data['status'] as String)
          : MatchStatus.scheduled,
      evidenceImages: data['evidenceImages'] != null
          ? List<String>.from(data['evidenceImages'] as List)
          : [],
      evidenceImageMetadata: data['evidenceImageMetadata'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (data['evidenceImageMetadata'] as Map).map(
                (key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
              ),
            )
          : null,
    );
  }

  /// JSONから作成
  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      id: json['id'] as String?,
      eventId: json['eventId'] as String,
      matchName: json['matchName'] as String,
      participants: List<String>.from(json['participants'] as List),
      winner: json['winner'] as String?,
      scores: Map<String, int>.from(json['scores'] as Map),
      individualScores: json['individualScores'] != null
          ? Map<String, int>.from(json['individualScores'] as Map)
          : null,
      individualStats: json['individualStats'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (json['individualStats'] as Map).map(
                (key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
              ),
            )
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isTeamMatch: json['isTeamMatch'] as bool? ?? false,
      matchFormat: json['matchFormat'] as String?,
      notes: json['notes'] as String?,
      adminPublicNotes: json['adminPublicNotes'] as String?,
      adminPrivateNotes: json['adminPrivateNotes'] as String?,
      status: json['status'] != null
          ? MatchStatus.fromString(json['status'] as String)
          : MatchStatus.scheduled,
      evidenceImages: json['evidenceImages'] != null
          ? List<String>.from(json['evidenceImages'] as List)
          : [],
      evidenceImageMetadata: json['evidenceImageMetadata'] != null
          ? Map<String, Map<String, dynamic>>.from(
              (json['evidenceImageMetadata'] as Map).map(
                (key, value) => MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
              ),
            )
          : null,
    );
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'matchName': matchName,
      'participants': participants,
      'winner': winner,
      'scores': scores,
      'individualScores': individualScores,
      'individualStats': individualStats,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isTeamMatch': isTeamMatch,
      'matchFormat': matchFormat,
      'notes': notes,
      'adminPublicNotes': adminPublicNotes,
      'adminPrivateNotes': adminPrivateNotes,
      'status': status.value,
      'evidenceImages': evidenceImages,
      'evidenceImageMetadata': evidenceImageMetadata,
    };
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'eventId': eventId,
      'matchName': matchName,
      'participants': participants,
      'winner': winner,
      'scores': scores,
      'individualScores': individualScores,
      'individualStats': individualStats,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isTeamMatch': isTeamMatch,
      'matchFormat': matchFormat,
      'notes': notes,
      'adminPublicNotes': adminPublicNotes,
      'adminPrivateNotes': adminPrivateNotes,
      'status': status.value,
      'evidenceImages': evidenceImages,
      'evidenceImageMetadata': evidenceImageMetadata,
    };
  }

  /// コピーを作成
  MatchResult copyWith({
    String? id,
    String? eventId,
    String? matchName,
    List<String>? participants,
    String? winner,
    Map<String, int>? scores,
    Map<String, int>? individualScores,
    Map<String, Map<String, dynamic>>? individualStats,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isTeamMatch,
    String? matchFormat,
    String? notes,
    String? adminPublicNotes,
    String? adminPrivateNotes,
    MatchStatus? status,
    List<String>? evidenceImages,
    Map<String, Map<String, dynamic>>? evidenceImageMetadata,
  }) {
    return MatchResult(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      matchName: matchName ?? this.matchName,
      participants: participants ?? this.participants,
      winner: winner ?? this.winner,
      scores: scores ?? this.scores,
      individualScores: individualScores ?? this.individualScores,
      individualStats: individualStats ?? this.individualStats,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTeamMatch: isTeamMatch ?? this.isTeamMatch,
      matchFormat: matchFormat ?? this.matchFormat,
      notes: notes ?? this.notes,
      adminPublicNotes: adminPublicNotes ?? this.adminPublicNotes,
      adminPrivateNotes: adminPrivateNotes ?? this.adminPrivateNotes,
      status: status ?? this.status,
      evidenceImages: evidenceImages ?? this.evidenceImages,
      evidenceImageMetadata: evidenceImageMetadata ?? this.evidenceImageMetadata,
    );
  }

  /// 試合が完了しているかどうか
  bool get isCompleted => status == MatchStatus.completed;

  /// 試合が進行中かどうか
  bool get isInProgress => status == MatchStatus.inProgress;

  /// 試合が開催予定かどうか
  bool get isScheduled => status == MatchStatus.scheduled;

  @override
  List<Object?> get props => [
        id,
        eventId,
        matchName,
        participants,
        winner,
        scores,
        individualScores,
        individualStats,
        completedAt,
        createdAt,
        updatedAt,
        isTeamMatch,
        matchFormat,
        notes,
        adminPublicNotes,
        adminPrivateNotes,
        status,
        evidenceImages,
        evidenceImageMetadata,
      ];

  @override
  String toString() {
    return 'MatchResult(id: $id, matchName: $matchName, isCompleted: $isCompleted)';
  }
}

/// ランキング情報モデル
class ParticipantRanking extends Equatable {
  /// 参加者ID（個人戦の場合はユーザーID、チーム戦の場合はグループID）
  final String participantId;

  /// 表示名
  final String displayName;

  /// 順位
  final int rank;

  /// 合計スコア
  final int totalScore;

  /// 勝利数
  final int wins;

  /// 敗北数
  final int losses;

  /// 引き分け数
  final int draws;

  /// チーム戦かどうか
  final bool isTeam;

  /// チームメンバー（チーム戦の場合のみ）
  final List<String>? teamMembers;

  /// ランキング種別（team, individual）
  final String rankingType;

  /// 追加統計（MVP回数、キル数など）
  final Map<String, dynamic>? additionalStats;

  const ParticipantRanking({
    required this.participantId,
    required this.displayName,
    required this.rank,
    required this.totalScore,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.isTeam,
    this.teamMembers,
    this.rankingType = 'team',
    this.additionalStats,
  });

  /// 試合総数
  int get totalMatches => wins + losses + draws;

  /// 勝率
  double get winRate => totalMatches > 0 ? wins / totalMatches : 0.0;

  @override
  List<Object?> get props => [
        participantId,
        displayName,
        rank,
        totalScore,
        wins,
        losses,
        draws,
        isTeam,
        teamMembers,
        rankingType,
        additionalStats,
      ];

  @override
  String toString() {
    return 'ParticipantRanking(participantId: $participantId, rank: $rank, totalScore: $totalScore, type: $rankingType)';
  }
}