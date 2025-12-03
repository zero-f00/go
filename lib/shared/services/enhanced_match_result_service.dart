import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/enhanced_match_result_model.dart';

class EnhancedMatchResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'enhanced_match_results';

  /// 指定イベントの拡張試合結果を取得
  Future<List<EnhancedMatchResult>> getEnhancedMatchResultsByEventId(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EnhancedMatchResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('拡張試合結果の取得に失敗しました: $e');
    }
  }

  /// 拡張試合結果を作成
  Future<String> createEnhancedMatchResult(EnhancedMatchResult matchResult) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(matchResult.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('拡張試合結果の作成に失敗しました: $e');
    }
  }

  /// 拡張試合結果を更新
  Future<void> updateEnhancedMatchResult(EnhancedMatchResult matchResult) async {
    try {
      if (matchResult.id == null) {
        throw ArgumentError('拡張試合結果IDが指定されていません');
      }

      await _firestore
          .collection(_collection)
          .doc(matchResult.id)
          .update(matchResult.toFirestore());
    } catch (e) {
      throw Exception('拡張試合結果の更新に失敗しました: $e');
    }
  }

  /// 拡張試合結果を削除
  Future<void> deleteEnhancedMatchResult(String matchResultId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .delete();
    } catch (e) {
      throw Exception('拡張試合結果の削除に失敗しました: $e');
    }
  }

  /// 指定イベントの参加者統計を計算
  Future<List<EnhancedStatistics>> calculateEnhancedStatistics(
    String eventId, {
    required bool isTeamMatch,
  }) async {
    try {
      final matches = await getEnhancedMatchResultsByEventId(eventId);
      final completedMatches = matches.where((m) => m.isCompleted).toList();

      if (completedMatches.isEmpty) {
        return [];
      }

      Map<String, Map<String, dynamic>> participantStats = {};

      for (final match in completedMatches) {
        for (final result in match.results) {
          final participantId = result.participantId;

          if (!participantStats.containsKey(participantId)) {
            participantStats[participantId] = {
              'ranks': <int>[],
              'scores': <int>[],
              'times': <int>[],
              'wins': 0,
              'losses': 0,
              'draws': 0,
              'achievements': 0,
              'totalMatches': 0,
            };
          }

          final stats = participantStats[participantId]!;
          stats['totalMatches']++;

          // 結果タイプに応じて統計を計算
          switch (match.resultType) {
            case ResultType.ranking:
              if (result.rank != null) {
                (stats['ranks'] as List<int>).add(result.rank!);
              }
              break;
            case ResultType.score:
              if (result.score != null) {
                (stats['scores'] as List<int>).add(result.score!);
              }
              break;
            case ResultType.winLoss:
              if (result.winLossResult != null) {
                switch (result.winLossResult!) {
                  case WinLossResult.win:
                    stats['wins']++;
                    break;
                  case WinLossResult.loss:
                    stats['losses']++;
                    break;
                  case WinLossResult.draw:
                    stats['draws']++;
                    break;
                }
              }
              break;
            case ResultType.timeAttack:
              if (result.timeMillis != null) {
                (stats['times'] as List<int>).add(result.timeMillis!);
              }
              break;
            case ResultType.achievement:
              if (result.achievement != null && result.achievement!.achieved) {
                stats['achievements']++;
              }
              break;
            case ResultType.custom:
              break;
          }
        }
      }

      final statisticsList = <EnhancedStatistics>[];

      for (final entry in participantStats.entries) {
        final participantId = entry.key;
        final stats = entry.value;

        // 順位統計
        final ranks = stats['ranks'] as List<int>;
        final averageRank = ranks.isNotEmpty ? ranks.reduce((a, b) => a + b) / ranks.length : 0.0;
        final bestRank = ranks.isNotEmpty ? ranks.reduce((a, b) => a < b ? a : b) : 0;
        final worstRank = ranks.isNotEmpty ? ranks.reduce((a, b) => a > b ? a : b) : 0;

        // スコア統計
        final scores = stats['scores'] as List<int>;
        final totalScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) : 0;
        final averageScore = scores.isNotEmpty ? totalScore / scores.length : 0.0;
        final highScore = scores.isNotEmpty ? scores.reduce((a, b) => a > b ? a : b) : 0;
        final lowScore = scores.isNotEmpty ? scores.reduce((a, b) => a < b ? a : b) : 0;

        // 勝敗統計
        final wins = stats['wins'] as int;
        final losses = stats['losses'] as int;
        final draws = stats['draws'] as int;
        final totalWinLossMatches = wins + losses + draws;
        final winRate = totalWinLossMatches > 0 ? wins / totalWinLossMatches : 0.0;

        // タイム統計
        final times = stats['times'] as List<int>;
        final bestTime = times.isNotEmpty ? times.reduce((a, b) => a < b ? a : b) : null;
        final averageTime = times.isNotEmpty ? (times.reduce((a, b) => a + b) / times.length).round() : null;

        // 達成度統計
        final achievements = stats['achievements'] as int;
        final totalMatches = stats['totalMatches'] as int;
        final achievementRate = totalMatches > 0 ? achievements / totalMatches : 0.0;

        final displayName = await _getDisplayName(participantId, isTeamMatch);

        statisticsList.add(EnhancedStatistics(
          participantId: participantId,
          displayName: displayName,
          ranks: ranks,
          averageRank: averageRank,
          bestRank: bestRank,
          worstRank: worstRank,
          totalScore: totalScore,
          averageScore: averageScore,
          highScore: highScore,
          lowScore: lowScore,
          wins: wins,
          losses: losses,
          draws: draws,
          winRate: winRate,
          bestTime: bestTime,
          averageTime: averageTime,
          achievements: achievements,
          achievementRate: achievementRate,
          totalMatches: totalMatches,
          completedMatches: completedMatches.length,
        ));
      }

      return statisticsList;
    } catch (e) {
      throw Exception('拡張統計計算に失敗しました: $e');
    }
  }

  /// 結果タイプ別ランキングを取得
  Future<List<ParticipantResult>> getRankingByType(
    String eventId,
    ResultType resultType, {
    required bool isTeamMatch,
  }) async {
    try {
      final matches = await getEnhancedMatchResultsByEventId(eventId);
      final targetMatches = matches
          .where((m) => m.resultType == resultType && m.isCompleted)
          .toList();

      if (targetMatches.isEmpty) {
        return [];
      }

      // 結果タイプに応じた集計とソート
      final aggregatedResults = <String, ParticipantResult>{};

      for (final match in targetMatches) {
        for (final result in match.results) {
          final participantId = result.participantId;

          if (!aggregatedResults.containsKey(participantId)) {
            aggregatedResults[participantId] = result;
          } else {
            // 複数試合の結果を集計（今回は最新の結果を使用）
            aggregatedResults[participantId] = result;
          }
        }
      }

      final results = aggregatedResults.values.toList();

      // 結果タイプに応じてソート
      switch (resultType) {
        case ResultType.ranking:
          results.sort((a, b) => (a.rank ?? 999).compareTo(b.rank ?? 999));
          break;
        case ResultType.score:
          results.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
          break;
        case ResultType.timeAttack:
          results.sort((a, b) => (a.timeMillis ?? 999999999).compareTo(b.timeMillis ?? 999999999));
          break;
        case ResultType.winLoss:
        case ResultType.achievement:
        case ResultType.custom:
          // その他は特別なソートなし
          break;
      }

      return results;
    } catch (e) {
      throw Exception('ランキング取得に失敗しました: $e');
    }
  }

  /// 表示名を取得（個人の場合はユーザー名、チームの場合はグループ名）
  Future<String> _getDisplayName(String participantId, bool isTeamMatch) async {
    try {
      if (isTeamMatch) {
        final groupDoc = await _firestore
            .collection('groups')
            .doc(participantId)
            .get();
        if (groupDoc.exists) {
          return groupDoc.data()?['name'] as String? ?? 'Unknown Group';
        }
      } else {
        final userDoc = await _firestore
            .collection('users')
            .doc(participantId)
            .get();
        if (userDoc.exists) {
          return userDoc.data()?['displayName'] as String? ?? 'Unknown User';
        }
      }
      return 'Unknown';
    } catch (e) {
      return 'Error loading name';
    }
  }

  /// 拡張試合結果をリアルタイムで監視
  Stream<List<EnhancedMatchResult>> watchEnhancedMatchResultsByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EnhancedMatchResult.fromFirestore(doc))
            .toList());
  }

  /// レガシー試合結果から拡張試合結果への変換
  Future<void> migrateFromLegacyResult(String eventId, String matchResultId) async {
    try {
      // レガシー結果を取得
      final legacyDoc = await _firestore
          .collection('match_results')
          .doc(matchResultId)
          .get();

      if (!legacyDoc.exists) {
        throw Exception('レガシー試合結果が見つかりません');
      }

      final legacyData = legacyDoc.data() as Map<String, dynamic>;

      // 拡張試合結果に変換
      final enhancedResult = EnhancedMatchResult(
        eventId: eventId,
        matchName: legacyData['matchName'] as String,
        resultType: ResultType.score, // デフォルトはスコア制
        results: _convertLegacyResults(legacyData),
        isTeamMatch: legacyData['isTeamMatch'] as bool? ?? false,
        matchFormat: legacyData['matchFormat'] as String?,
        notes: legacyData['notes'] as String?,
        completedAt: legacyData['completedAt'] != null
            ? (legacyData['completedAt'] as Timestamp).toDate()
            : null,
        createdAt: (legacyData['createdAt'] as Timestamp).toDate(),
        updatedAt: DateTime.now(),
      );

      // 拡張結果を保存
      await createEnhancedMatchResult(enhancedResult);

    } catch (e) {
      throw Exception('レガシー結果の変換に失敗しました: $e');
    }
  }

  /// レガシー結果データを拡張結果形式に変換
  List<ParticipantResult> _convertLegacyResults(Map<String, dynamic> legacyData) {
    final participants = List<String>.from(legacyData['participants'] as List);
    final scores = Map<String, int>.from(legacyData['scores'] as Map);
    final winner = legacyData['winner'] as String?;

    return participants.map((participantId) {
      return ParticipantResult(
        participantId: participantId,
        score: scores[participantId],
        winLossResult: winner != null
            ? (winner == participantId ? WinLossResult.win : WinLossResult.loss)
            : null,
      );
    }).toList();
  }
}