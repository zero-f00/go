import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_game_model.dart';
import '../../shared/models/game.dart';

/// 共有ゲームデータのリポジトリ
/// Firestoreでゲーム情報を管理し、全ユーザー間で効率的にデータを共有
class SharedGameRepository {
  static const String _collection = 'shared_games';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ゲームIDで既存の共有ゲームデータを検索
  /// iTunes APIの重複呼び出しを避けるための検索機能
  Future<SharedGameData?> findExistingGame(String gameId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('game.id', isEqualTo: gameId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final sharedGame = SharedGameData.fromJson(
          doc.data(),
          doc.id,
        );

        // 最終アクセス時刻を更新
        await _updateLastAccessed(doc.id);

        return sharedGame;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// ゲーム名とプラットフォームで類似のゲームを検索
  /// より柔軟な検索による重複防止
  Future<List<SharedGameData>> findSimilarGames(String name, List<String> platforms) async {
    try {
      // ゲーム名の部分一致で検索
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('game.name', isGreaterThanOrEqualTo: name.toLowerCase())
          .where('game.name', isLessThanOrEqualTo: name.toLowerCase() + '\uf8ff')
          .limit(5)
          .get();

      final results = <SharedGameData>[];
      for (final doc in querySnapshot.docs) {
        final sharedGame = SharedGameData.fromJson(doc.data() as Map<String, dynamic>, doc.id);

        // プラットフォームが一致するかチェック
        final hasCommonPlatform = sharedGame.game.platforms.any(
          (platform) => platforms.contains(platform),
        );

        if (hasCommonPlatform) {
          results.add(sharedGame);
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// 新しいゲームデータをFirestoreに保存
  Future<SharedGameData?> saveNewGame(Game game) async {
    try {
      // 認証状態を確認
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return null;
      }

      final sharedGame = SharedGameData.fromItunesGame(game);

      await _firestore
          .collection(_collection)
          .doc(sharedGame.documentId)
          .set(sharedGame.toJson());

      return sharedGame;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        // Handle permission denied error
      }
      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// 既存のゲームデータの使用回数を増やす
  Future<void> incrementGameUsage(String documentId) async {
    try {
      final docRef = _firestore.collection(_collection).doc(documentId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final data = snapshot.data()!;
          final currentUsage = data['usageCount'] as int? ?? 0;

          transaction.update(docRef, {
            'usageCount': currentUsage + 1,
            'lastAccessedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  /// 人気のあるゲーム一覧を取得
  Future<List<SharedGameData>> getPopularGames({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('usageCount', descending: true)
          .limit(limit)
          .get();

      final games = querySnapshot.docs.map((doc) =>
        SharedGameData.fromJson(doc.data(), doc.id)
      ).toList();

      return games;
    } catch (e) {
      return [];
    }
  }

  /// 最近使用されたゲーム一覧を取得
  Future<List<SharedGameData>> getRecentGames({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('lastAccessedAt', descending: true)
          .limit(limit)
          .get();

      final games = querySnapshot.docs.map((doc) =>
        SharedGameData.fromJson(doc.data(), doc.id)
      ).toList();

      return games;
    } catch (e) {
      return [];
    }
  }

  /// クエリパラメータでゲームを検索
  Future<List<SharedGameData>> searchGames(GameSearchQuery query) async {
    try {
      Query firestoreQuery = _firestore.collection(_collection);

      // 名前での検索
      if (query.name != null && query.name!.isNotEmpty) {
        final searchName = query.name!.toLowerCase();
        firestoreQuery = firestoreQuery
            .where('game.name', isGreaterThanOrEqualTo: searchName)
            .where('game.name', isLessThanOrEqualTo: searchName + '\uf8ff');
      }

      // 開発者での検索
      if (query.developer != null && query.developer!.isNotEmpty) {
        firestoreQuery = firestoreQuery
            .where('game.developer', isEqualTo: query.developer);
      }

      // 人気ゲームでの絞り込み
      if (query.isPopular != null) {
        firestoreQuery = firestoreQuery
            .where('game.isPopular', isEqualTo: query.isPopular);
      }

      // 評価での絞り込み
      if (query.minRating != null) {
        firestoreQuery = firestoreQuery
            .where('game.rating', isGreaterThanOrEqualTo: query.minRating);
      }

      final querySnapshot = await firestoreQuery.limit(20).get();

      final results = <SharedGameData>[];

      for (final doc in querySnapshot.docs) {
        final sharedGame = SharedGameData.fromJson(doc.data() as Map<String, dynamic>, doc.id);

        // プラットフォームでの絞り込み（クライアント側で実行）
        if (query.platforms != null && query.platforms!.isNotEmpty) {
          final hasMatchingPlatform = sharedGame.game.platforms.any(
            (platform) => query.platforms!.contains(platform),
          );

          if (!hasMatchingPlatform) {
            continue;
          }
        }

        results.add(sharedGame);
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// 古いキャッシュデータをクリーンアップ
  /// 30日間使用されていないデータを削除
  Future<void> cleanupOldCache() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final timestampThreshold = thirtyDaysAgo.millisecondsSinceEpoch;

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lastAccessedAt', isLessThan: timestampThreshold)
          .get();

      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      if (deleteCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// 内部メソッド: 最終アクセス時刻を更新
  Future<void> _updateLastAccessed(String documentId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(documentId)
          .update({'lastAccessedAt': DateTime.now().millisecondsSinceEpoch});
    } catch (e) {
      // Handle error silently
    }
  }
}