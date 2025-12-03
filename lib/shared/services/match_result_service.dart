import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/match_result_model.dart';
import 'image_upload_service.dart';

class MatchResultService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'match_results';

  /// 指定イベントの試合結果を取得
  Future<List<MatchResult>> getMatchResultsByEventId(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MatchResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('試合結果の取得に失敗しました: $e');
    }
  }

  /// 試合結果を作成
  Future<String> createMatchResult(MatchResult matchResult) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(matchResult.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('試合結果の作成に失敗しました: $e');
    }
  }

  /// 試合結果を更新
  Future<void> updateMatchResult(MatchResult matchResult) async {
    try {
      if (matchResult.id == null) {
        throw ArgumentError('試合結果IDが指定されていません');
      }

      await _firestore
          .collection(_collection)
          .doc(matchResult.id)
          .update(matchResult.toFirestore());
    } catch (e) {
      throw Exception('試合結果の更新に失敗しました: $e');
    }
  }

  /// 試合結果を削除
  Future<void> deleteMatchResult(String matchResultId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .delete();
    } catch (e) {
      throw Exception('試合結果の削除に失敗しました: $e');
    }
  }

  /// 指定イベントの参加者ランキングを計算
  Future<List<ParticipantRanking>> calculateRanking(
    String eventId, {
    required bool isTeamMatch,
    String rankingType = 'team', // 'team' or 'individual'
  }) async {
    try {
      final matches = await getMatchResultsByEventId(eventId);
      final completedMatches = matches.where((m) => m.isCompleted).toList();

      if (completedMatches.isEmpty) {
        return [];
      }

      Map<String, Map<String, dynamic>> participantStats = {};

      if (isTeamMatch && rankingType == 'individual') {
        // チーム戦での個人戦績計算
        participantStats = await _calculateIndividualStatsInTeamMatches(completedMatches);
      } else {
        // 通常のチーム戦績または個人戦戦績計算
        participantStats = _calculateStandardStats(completedMatches);
      }

      final rankingList = <ParticipantRanking>[];

      for (final entry in participantStats.entries) {
        final participantId = entry.key;
        final stats = entry.value;

        final isTeamRanking = isTeamMatch && rankingType != 'individual';

        rankingList.add(ParticipantRanking(
          participantId: participantId,
          displayName: await _getDisplayName(participantId, isTeamRanking),
          rank: 0,
          totalScore: stats['totalScore'] as int,
          wins: stats['wins'] as int,
          losses: stats['losses'] as int,
          draws: stats['draws'] as int,
          isTeam: isTeamRanking,
          teamMembers: isTeamRanking
              ? await _getTeamMembers(participantId)
              : null,
          rankingType: rankingType,
          additionalStats: stats['additionalStats'] as Map<String, dynamic>?,
        ));
      }

      rankingList.sort((a, b) {
        if (a.totalScore != b.totalScore) {
          return b.totalScore.compareTo(a.totalScore);
        }
        if (a.wins != b.wins) {
          return b.wins.compareTo(a.wins);
        }
        return a.losses.compareTo(b.losses);
      });

      for (int i = 0; i < rankingList.length; i++) {
        final participant = rankingList[i];
        rankingList[i] = ParticipantRanking(
          participantId: participant.participantId,
          displayName: participant.displayName,
          rank: i + 1,
          totalScore: participant.totalScore,
          wins: participant.wins,
          losses: participant.losses,
          draws: participant.draws,
          isTeam: participant.isTeam,
          teamMembers: participant.teamMembers,
        );
      }

      return rankingList;
    } catch (e) {
      throw Exception('ランキング計算に失敗しました: $e');
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

  /// チームメンバーのリストを取得
  Future<List<String>?> _getTeamMembers(String groupId) async {
    try {
      final groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (groupDoc.exists) {
        final data = groupDoc.data();
        return List<String>.from(data?['memberIds'] as List? ?? []);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 標準的な戦績計算（チーム戦績または個人戦戦績）
  Map<String, Map<String, dynamic>> _calculateStandardStats(List<MatchResult> completedMatches) {
    final Map<String, Map<String, dynamic>> participantStats = {};

    for (final match in completedMatches) {
      for (final participantId in match.participants) {
        if (!participantStats.containsKey(participantId)) {
          participantStats[participantId] = {
            'totalScore': 0,
            'wins': 0,
            'losses': 0,
            'draws': 0,
            'additionalStats': <String, dynamic>{},
          };
        }

        final score = match.scores[participantId] ?? 0;
        participantStats[participantId]!['totalScore'] += score;

        if (match.winner == participantId) {
          participantStats[participantId]!['wins']++;
        } else if (match.winner == null) {
          participantStats[participantId]!['draws']++;
        } else {
          participantStats[participantId]!['losses']++;
        }
      }
    }

    return participantStats;
  }

  /// チーム戦での個人戦績計算
  Future<Map<String, Map<String, dynamic>>> _calculateIndividualStatsInTeamMatches(List<MatchResult> completedMatches) async {
    final Map<String, Map<String, dynamic>> participantStats = {};

    for (final match in completedMatches) {
      // 個人スコアがある場合は個人戦績を計算
      if (match.individualScores != null) {
        for (final entry in match.individualScores!.entries) {
          final userId = entry.key;
          final score = entry.value;

          if (!participantStats.containsKey(userId)) {
            participantStats[userId] = {
              'totalScore': 0,
              'wins': 0,
              'losses': 0,
              'draws': 0,
              'additionalStats': <String, dynamic>{},
            };
          }

          participantStats[userId]!['totalScore'] += score;

          // チームの勝敗に基づいて個人の勝敗を決定
          final userTeam = await _getUserTeamInMatch(userId, match);
          if (userTeam != null) {
            if (match.winner == userTeam) {
              participantStats[userId]!['wins']++;
            } else if (match.winner == null) {
              participantStats[userId]!['draws']++;
            } else {
              participantStats[userId]!['losses']++;
            }
          }

          // 追加統計データの処理
          if (match.individualStats != null && match.individualStats!.containsKey(userId)) {
            final stats = participantStats[userId]!['additionalStats'] as Map<String, dynamic>;
            final matchStats = match.individualStats![userId]!;

            for (final statEntry in matchStats.entries) {
              final key = statEntry.key;
              final value = statEntry.value;

              if (value is num) {
                stats[key] = (stats[key] as num? ?? 0) + value;
              }
            }
          }
        }
      }
    }

    return participantStats;
  }

  /// ユーザーがどのチームに所属しているかを取得
  Future<String?> _getUserTeamInMatch(String userId, MatchResult match) async {
    try {
      // グループメンバーからユーザーのチームを特定
      for (final participantId in match.participants) {
        final teamMembers = await _getTeamMembers(participantId);
        if (teamMembers != null && teamMembers.contains(userId)) {
          return participantId;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 試合結果をリアルタイムで監視
  Stream<List<MatchResult>> watchMatchResultsByEventId(String eventId) {
    return _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MatchResult.fromFirestore(doc))
            .toList());
  }

  /// エビデンス画像をアップロードして試合結果に追加
  Future<void> addEvidenceImages({
    required String matchResultId,
    required List<File> imageFiles,
    required String uploaderId,
    String? uploaderName,
  }) async {
    try {
      // 現在の試合結果を取得
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        throw Exception('試合結果が見つかりません');
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);

      // 画像をアップロード
      final uploadResults = await ImageUploadService.uploadMultipleEvidenceImages(
        imageFiles,
        matchResult.eventId,
        matchResultId,
        uploaderId,
      );

      // 現在のエビデンス画像リストとメタデータを取得
      final currentImages = List<String>.from(matchResult.evidenceImages);
      final currentMetadata = Map<String, Map<String, dynamic>>.from(
        matchResult.evidenceImageMetadata ?? {},
      );

      // 新しい画像URLとメタデータを追加
      for (final result in uploadResults) {
        currentImages.add(result.downloadUrl);
        currentMetadata[result.downloadUrl] = {
          'uploaderId': uploaderId,
          'uploaderName': uploaderName ?? 'Unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
          'filePath': result.filePath,
          'originalSize': result.originalSize,
          'compressedSize': result.compressedSize,
          'compressionRatio': result.compressionRatio,
        };
      }

      // 試合結果を更新
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .update({
        'evidenceImages': currentImages,
        'evidenceImageMetadata': currentMetadata,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('エビデンス画像の追加に失敗しました: $e');
    }
  }

  /// エビデンス画像を削除
  Future<void> removeEvidenceImage({
    required String matchResultId,
    required String imageUrl,
  }) async {
    try {
      // 現在の試合結果を取得
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        throw Exception('試合結果が見つかりません');
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);

      // 画像リストから削除
      final updatedImages = matchResult.evidenceImages
          .where((url) => url != imageUrl)
          .toList();

      // メタデータからも削除
      final updatedMetadata = Map<String, Map<String, dynamic>>.from(
        matchResult.evidenceImageMetadata ?? {},
      );
      final filePath = updatedMetadata[imageUrl]?['filePath'] as String?;
      updatedMetadata.remove(imageUrl);

      // Storageから画像を削除（エラーが発生してもメタデータの更新は継続）
      if (filePath != null) {
        try {
          await ImageUploadService.deleteImage(filePath);
        } catch (e) {
          // ログのみ出力、処理は継続
          print('Warning: Failed to delete image from storage: $e');
        }
      }

      // 試合結果を更新
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .update({
        'evidenceImages': updatedImages,
        'evidenceImageMetadata': updatedMetadata,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('エビデンス画像の削除に失敗しました: $e');
    }
  }

  /// エビデンス画像を置き換え（古い画像を自動削除）
  Future<void> replaceEvidenceImage({
    required String matchResultId,
    required String oldImageUrl,
    required File newImageFile,
    required String uploaderId,
    String? uploaderName,
  }) async {
    try {
      // 現在の試合結果を取得
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        throw Exception('試合結果が見つかりません');
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);

      // 新しい画像をアップロード
      final uploadResult = await ImageUploadService.uploadEvidenceImage(
        newImageFile,
        matchResult.eventId,
        matchResultId,
        uploaderId,
      );

      // 現在の画像リストとメタデータを更新
      final updatedImages = List<String>.from(matchResult.evidenceImages);
      final updatedMetadata = Map<String, Map<String, dynamic>>.from(
        matchResult.evidenceImageMetadata ?? {},
      );

      // 古い画像のファイルパスを取得
      final oldFilePath = updatedMetadata[oldImageUrl]?['filePath'] as String?;

      // 古い画像のURLを新しいURLに置き換え
      final oldIndex = updatedImages.indexOf(oldImageUrl);
      if (oldIndex != -1) {
        updatedImages[oldIndex] = uploadResult.downloadUrl;
      }

      // 古い画像のメタデータを削除し、新しいメタデータを追加
      updatedMetadata.remove(oldImageUrl);
      updatedMetadata[uploadResult.downloadUrl] = {
        'uploaderId': uploaderId,
        'uploaderName': uploaderName ?? 'Unknown',
        'uploadedAt': DateTime.now().toIso8601String(),
        'filePath': uploadResult.filePath,
        'originalSize': uploadResult.originalSize,
        'compressedSize': uploadResult.compressedSize,
        'compressionRatio': uploadResult.compressionRatio,
        'replacedAt': DateTime.now().toIso8601String(),
        'replacedFrom': oldImageUrl,
      };

      // 試合結果を更新
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .update({
        'evidenceImages': updatedImages,
        'evidenceImageMetadata': updatedMetadata,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 古い画像をStorageから削除（非同期で実行、エラーでも処理は継続）
      if (oldFilePath != null) {
        _deleteImageFromStorageAsync(oldFilePath, oldImageUrl);
      }
    } catch (e) {
      throw Exception('エビデンス画像の置き換えに失敗しました: $e');
    }
  }

  /// 非同期でStorageから画像を削除（エラーログのみ出力）
  void _deleteImageFromStorageAsync(String filePath, String imageUrl) {
    Future.delayed(Duration.zero, () async {
      try {
        await ImageUploadService.deleteImage(filePath);
        print('✅ Successfully deleted old evidence image from storage: $imageUrl');
      } catch (e) {
        print('⚠️ Warning: Failed to delete old evidence image from storage: $imageUrl, Error: $e');
      }
    });
  }

  /// 複数のエビデンス画像を一括置き換え（全ての古い画像を削除）
  Future<void> replaceAllEvidenceImages({
    required String matchResultId,
    required List<File> newImageFiles,
    required String uploaderId,
    String? uploaderName,
  }) async {
    try {
      // 現在の試合結果を取得
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        throw Exception('試合結果が見つかりません');
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);

      // 古い画像のファイルパスを保存（後で削除用）
      final oldFilePaths = <String>[];
      final oldImageUrls = List<String>.from(matchResult.evidenceImages);

      for (final imageUrl in oldImageUrls) {
        final filePath = matchResult.evidenceImageMetadata?[imageUrl]?['filePath'] as String?;
        if (filePath != null) {
          oldFilePaths.add(filePath);
        }
      }

      // 新しい画像をアップロード
      final uploadResults = await ImageUploadService.uploadMultipleEvidenceImages(
        newImageFiles,
        matchResult.eventId,
        matchResultId,
        uploaderId,
      );

      // 新しい画像リストとメタデータを構築
      final newImages = <String>[];
      final newMetadata = <String, Map<String, dynamic>>{};

      for (final result in uploadResults) {
        newImages.add(result.downloadUrl);
        newMetadata[result.downloadUrl] = {
          'uploaderId': uploaderId,
          'uploaderName': uploaderName ?? 'Unknown',
          'uploadedAt': DateTime.now().toIso8601String(),
          'filePath': result.filePath,
          'originalSize': result.originalSize,
          'compressedSize': result.compressedSize,
          'compressionRatio': result.compressionRatio,
          'replacementType': 'bulk_replace',
          'replacedImagesCount': oldImageUrls.length,
        };
      }

      // 試合結果を更新
      await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .update({
        'evidenceImages': newImages,
        'evidenceImageMetadata': newMetadata,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // 古い画像をStorageから一括削除（非同期で実行）
      _deleteMultipleImagesFromStorageAsync(oldFilePaths, oldImageUrls);
    } catch (e) {
      throw Exception('エビデンス画像の一括置き換えに失敗しました: $e');
    }
  }

  /// 非同期で複数の画像をStorageから削除
  void _deleteMultipleImagesFromStorageAsync(List<String> filePaths, List<String> imageUrls) {
    Future.delayed(Duration.zero, () async {
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < filePaths.length; i++) {
        try {
          await ImageUploadService.deleteImage(filePaths[i]);
          successCount++;
        } catch (e) {
          errorCount++;
          print('⚠️ Warning: Failed to delete old evidence image from storage: ${imageUrls.length > i ? imageUrls[i] : filePaths[i]}, Error: $e');
        }
      }

      print('📊 Bulk deletion complete: $successCount succeeded, $errorCount failed');
    });
  }

  /// エビデンス画像のメタデータを取得
  Future<Map<String, dynamic>?> getEvidenceImageMetadata({
    required String matchResultId,
    required String imageUrl,
  }) async {
    try {
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        return null;
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);
      return matchResult.evidenceImageMetadata?[imageUrl];
    } catch (e) {
      return null;
    }
  }

  /// 試合のすべてのエビデンス画像とメタデータを取得
  Future<List<Map<String, dynamic>>> getAllEvidenceImages(String matchResultId) async {
    try {
      final matchDoc = await _firestore
          .collection(_collection)
          .doc(matchResultId)
          .get();

      if (!matchDoc.exists) {
        return [];
      }

      final matchResult = MatchResult.fromFirestore(matchDoc);
      final results = <Map<String, dynamic>>[];

      for (final imageUrl in matchResult.evidenceImages) {
        final metadata = matchResult.evidenceImageMetadata?[imageUrl] ?? {};
        results.add({
          'url': imageUrl,
          'metadata': metadata,
        });
      }

      // アップロード日時順でソート（新しい順）
      results.sort((a, b) {
        final aUploadedAt = DateTime.tryParse(
          a['metadata']['uploadedAt'] as String? ?? '',
        );
        final bUploadedAt = DateTime.tryParse(
          b['metadata']['uploadedAt'] as String? ?? '',
        );

        if (aUploadedAt != null && bUploadedAt != null) {
          return bUploadedAt.compareTo(aUploadedAt);
        }
        return 0;
      });

      return results;
    } catch (e) {
      throw Exception('エビデンス画像の取得に失敗しました: $e');
    }
  }
}