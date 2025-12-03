import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 結果記録タイプ
enum ResultType {
  ranking,      // 順位制（1位、2位、3位...）
  score,        // スコア制（点数で競う）
  winLoss,      // 勝敗制（勝ち/負け/引き分け）
  timeAttack,   // タイム制（時間を競う）
  achievement,  // 達成度制（クリア/未クリア、星の数など）
  custom,       // カスタム（自由形式）
}

/// 結果記録タイプの拡張
extension ResultTypeExtension on ResultType {
  String get displayName {
    switch (this) {
      case ResultType.ranking:
        return '順位制';
      case ResultType.score:
        return 'スコア制';
      case ResultType.winLoss:
        return '勝敗制';
      case ResultType.timeAttack:
        return 'タイム制';
      case ResultType.achievement:
        return '達成度制';
      case ResultType.custom:
        return 'カスタム';
    }
  }

  String get description {
    switch (this) {
      case ResultType.ranking:
        return '参加者の順位を記録（1位、2位、3位...）';
      case ResultType.score:
        return '獲得スコア・ポイントを記録';
      case ResultType.winLoss:
        return '勝敗結果を記録（勝ち/負け/引き分け）';
      case ResultType.timeAttack:
        return 'クリアタイムや記録時間を記録';
      case ResultType.achievement:
        return '達成度や評価を記録（星の数、ランク等）';
      case ResultType.custom:
        return '自由形式で結果を記録';
    }
  }

  IconData get icon {
    switch (this) {
      case ResultType.ranking:
        return Icons.emoji_events;
      case ResultType.score:
        return Icons.score;
      case ResultType.winLoss:
        return Icons.sports_score;
      case ResultType.timeAttack:
        return Icons.timer;
      case ResultType.achievement:
        return Icons.star;
      case ResultType.custom:
        return Icons.edit_note;
    }
  }
}

/// 参加者の結果詳細
class ParticipantResult extends Equatable {
  /// 参加者ID（個人戦の場合はユーザーID、チーム戦の場合はグループID）
  final String participantId;

  /// 順位（順位制の場合）
  final int? rank;

  /// スコア（スコア制の場合）
  final int? score;

  /// 勝敗結果（勝敗制の場合）
  final WinLossResult? winLossResult;

  /// タイム（タイム制の場合、ミリ秒単位）
  final int? timeMillis;

  /// 達成度（達成度制の場合）
  final AchievementResult? achievement;

  /// カスタムデータ（任意のデータ）
  final Map<String, dynamic>? customData;

  /// 個人統計（チーム戦での個人成績等）
  final Map<String, dynamic>? individualStats;

  const ParticipantResult({
    required this.participantId,
    this.rank,
    this.score,
    this.winLossResult,
    this.timeMillis,
    this.achievement,
    this.customData,
    this.individualStats,
  });

  factory ParticipantResult.fromJson(Map<String, dynamic> json) {
    return ParticipantResult(
      participantId: json['participantId'] as String,
      rank: json['rank'] as int?,
      score: json['score'] as int?,
      winLossResult: json['winLossResult'] != null
          ? WinLossResult.values[json['winLossResult'] as int]
          : null,
      timeMillis: json['timeMillis'] as int?,
      achievement: json['achievement'] != null
          ? AchievementResult.fromJson(json['achievement'] as Map<String, dynamic>)
          : null,
      customData: json['customData'] as Map<String, dynamic>?,
      individualStats: json['individualStats'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      if (rank != null) 'rank': rank,
      if (score != null) 'score': score,
      if (winLossResult != null) 'winLossResult': winLossResult!.index,
      if (timeMillis != null) 'timeMillis': timeMillis,
      if (achievement != null) 'achievement': achievement!.toJson(),
      if (customData != null) 'customData': customData,
      if (individualStats != null) 'individualStats': individualStats,
    };
  }

  @override
  List<Object?> get props => [
    participantId,
    rank,
    score,
    winLossResult,
    timeMillis,
    achievement,
    customData,
    individualStats,
  ];
}

/// 勝敗結果
enum WinLossResult { win, loss, draw }

/// 達成度結果
class AchievementResult extends Equatable {
  /// 達成したかどうか
  final bool achieved;

  /// 評価（星の数、S/A/B/Cランク等）
  final String? rating;

  /// 達成度（パーセンテージ）
  final double? completionRate;

  /// 詳細データ
  final Map<String, dynamic>? details;

  const AchievementResult({
    required this.achieved,
    this.rating,
    this.completionRate,
    this.details,
  });

  factory AchievementResult.fromJson(Map<String, dynamic> json) {
    return AchievementResult(
      achieved: json['achieved'] as bool,
      rating: json['rating'] as String?,
      completionRate: json['completionRate'] as double?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achieved': achieved,
      if (rating != null) 'rating': rating,
      if (completionRate != null) 'completionRate': completionRate,
      if (details != null) 'details': details,
    };
  }

  @override
  List<Object?> get props => [achieved, rating, completionRate, details];
}

/// 拡張された試合結果モデル
class EnhancedMatchResult extends Equatable {
  /// ドキュメントID
  final String? id;

  /// イベントID
  final String eventId;

  /// 試合名
  final String matchName;

  /// 結果記録タイプ
  final ResultType resultType;

  /// 参加者の結果詳細
  final List<ParticipantResult> results;

  /// チーム戦かどうか
  final bool isTeamMatch;

  /// 試合形式（トーナメント、リーグ戦、フリー対戦等）
  final String? matchFormat;

  /// ゲームタイトル
  final String? gameTitle;

  /// ゲーム固有の設定（ルール、マップ、モード等）
  final Map<String, dynamic>? gameSettings;

  /// メモ・備考
  final String? notes;

  /// 試合完了日時
  final DateTime? completedAt;

  /// 試合作成日時
  final DateTime createdAt;

  /// 試合更新日時
  final DateTime updatedAt;

  const EnhancedMatchResult({
    this.id,
    required this.eventId,
    required this.matchName,
    required this.resultType,
    required this.results,
    required this.isTeamMatch,
    this.matchFormat,
    this.gameTitle,
    this.gameSettings,
    this.notes,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから作成
  factory EnhancedMatchResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedMatchResult(
      id: doc.id,
      eventId: data['eventId'] as String,
      matchName: data['matchName'] as String,
      resultType: ResultType.values[data['resultType'] as int],
      results: (data['results'] as List)
          .map((r) => ParticipantResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      isTeamMatch: data['isTeamMatch'] as bool? ?? false,
      matchFormat: data['matchFormat'] as String?,
      gameTitle: data['gameTitle'] as String?,
      gameSettings: data['gameSettings'] as Map<String, dynamic>?,
      notes: data['notes'] as String?,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore保存用のMapに変換
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'matchName': matchName,
      'resultType': resultType.index,
      'results': results.map((r) => r.toJson()).toList(),
      'isTeamMatch': isTeamMatch,
      'matchFormat': matchFormat,
      'gameTitle': gameTitle,
      'gameSettings': gameSettings,
      'notes': notes,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// コピーを作成
  EnhancedMatchResult copyWith({
    String? id,
    String? eventId,
    String? matchName,
    ResultType? resultType,
    List<ParticipantResult>? results,
    bool? isTeamMatch,
    String? matchFormat,
    String? gameTitle,
    Map<String, dynamic>? gameSettings,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnhancedMatchResult(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      matchName: matchName ?? this.matchName,
      resultType: resultType ?? this.resultType,
      results: results ?? this.results,
      isTeamMatch: isTeamMatch ?? this.isTeamMatch,
      matchFormat: matchFormat ?? this.matchFormat,
      gameTitle: gameTitle ?? this.gameTitle,
      gameSettings: gameSettings ?? this.gameSettings,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 試合が完了しているかどうか
  bool get isCompleted => completedAt != null;

  /// 順位制の結果を取得（順位順にソート済み）
  List<ParticipantResult> get rankedResults {
    if (resultType != ResultType.ranking) return results;
    return List<ParticipantResult>.from(results)
      ..sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));
  }

  /// スコア制の結果を取得（スコア順にソート済み）
  List<ParticipantResult> get scoredResults {
    if (resultType != ResultType.score) return results;
    return List<ParticipantResult>.from(results)
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
  }

  @override
  List<Object?> get props => [
    id,
    eventId,
    matchName,
    resultType,
    results,
    isTeamMatch,
    matchFormat,
    gameTitle,
    gameSettings,
    notes,
    completedAt,
    createdAt,
    updatedAt,
  ];
}

/// 統計情報の集計
class EnhancedStatistics extends Equatable {
  final String participantId;
  final String displayName;

  // 順位制の統計
  final List<int> ranks;
  final double averageRank;
  final int bestRank;
  final int worstRank;

  // スコア制の統計
  final int totalScore;
  final double averageScore;
  final int highScore;
  final int lowScore;

  // 勝敗制の統計
  final int wins;
  final int losses;
  final int draws;
  final double winRate;

  // タイム制の統計
  final int? bestTime;
  final int? averageTime;

  // 達成度制の統計
  final int achievements;
  final double achievementRate;

  // 共通統計
  final int totalMatches;
  final int completedMatches;

  const EnhancedStatistics({
    required this.participantId,
    required this.displayName,
    required this.ranks,
    required this.averageRank,
    required this.bestRank,
    required this.worstRank,
    required this.totalScore,
    required this.averageScore,
    required this.highScore,
    required this.lowScore,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.winRate,
    this.bestTime,
    this.averageTime,
    required this.achievements,
    required this.achievementRate,
    required this.totalMatches,
    required this.completedMatches,
  });

  @override
  List<Object?> get props => [
    participantId,
    displayName,
    ranks,
    averageRank,
    bestRank,
    worstRank,
    totalScore,
    averageScore,
    highScore,
    lowScore,
    wins,
    losses,
    draws,
    winRate,
    bestTime,
    averageTime,
    achievements,
    achievementRate,
    totalMatches,
    completedMatches,
  ];
}