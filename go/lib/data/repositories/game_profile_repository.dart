import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_profile_model.dart';

/// ゲームプロフィールリポジトリの抽象クラス
abstract class GameProfileRepository {
  /// ユーザーの全ゲームプロフィールを取得
  Future<List<GameProfile>> getUserGameProfiles(String userId);

  /// 特定のゲームプロフィールを取得
  Future<GameProfile?> getGameProfile(String userId, String gameId);

  /// ゲームプロフィールを作成
  Future<void> createGameProfile(GameProfile profile);

  /// ゲームプロフィールを更新
  Future<void> updateGameProfile(GameProfile profile);

  /// ゲームプロフィールを削除
  Future<void> deleteGameProfile(String userId, String gameId);


  /// ユーザーのお気に入りゲームプロフィールを取得
  Future<List<GameProfile>> getFavoriteGameProfiles(String userId, List<String> gameIds);

  /// プロフィールIDで特定のゲームプロフィールを取得
  Future<GameProfile?> getGameProfileById(String profileId);
}

/// Firestore実装
class FirestoreGameProfileRepository implements GameProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreGameProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<GameProfile>> getUserGameProfiles(String userId) async {
    try {
      print('🔄 FirestoreGameProfileRepository: Getting profiles for user: $userId');
      print('   Full path: users/$userId/gameProfiles');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gameProfiles')
          .get();

      print('✅ FirestoreGameProfileRepository: Found ${snapshot.docs.length} documents');
      for (final doc in snapshot.docs) {
        print('   - Document: ${doc.id}, data: ${doc.data()}');
        print('   - Document path: ${doc.reference.path}');
      }

      final profiles = snapshot.docs
          .map((doc) => GameProfile.fromFirestore(doc))
          .toList();

      print('✅ FirestoreGameProfileRepository: Converted to ${profiles.length} GameProfile objects');
      return profiles;
    } catch (e) {
      print('❌ FirestoreGameProfileRepository: Error getting profiles: $e');
      throw Exception('ゲームプロフィールの取得に失敗しました: $e');
    }
  }

  @override
  Future<GameProfile?> getGameProfile(String userId, String gameId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('gameProfiles')
          .doc(gameId)
          .get();

      if (doc.exists) {
        return GameProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('ゲームプロフィールの取得に失敗しました: $e');
    }
  }

  @override
  Future<void> createGameProfile(GameProfile profile) async {
    final batch = _firestore.batch();

    try {
      print('🔄 FirestoreGameProfileRepository: Creating profile');
      print('   userId: ${profile.userId}');
      print('   gameId: ${profile.gameId}');
      print('   path: users/${profile.userId}/gameProfiles/${profile.gameId}');

      // 1. ユーザーサブコレクションに保存
      final profileRef = _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('gameProfiles')
          .doc(profile.gameId);

      final firestoreData = profile.toFirestore();
      print('   data: $firestoreData');
      print('   profileRef path: ${profileRef.path}');

      batch.set(profileRef, firestoreData);


      await batch.commit();
      print('✅ FirestoreGameProfileRepository: Profile created successfully');

      // 作成後の確認
      final verifyDoc = await _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('gameProfiles')
          .doc(profile.gameId)
          .get();

      print('🔍 Verification: Document exists after creation: ${verifyDoc.exists}');
      if (verifyDoc.exists) {
        print('   Created document data: ${verifyDoc.data()}');
      }

    } catch (e) {
      print('❌ FirestoreGameProfileRepository: Failed to create profile: $e');
      throw Exception('ゲームプロフィールの作成に失敗しました: $e');
    }
  }

  @override
  Future<void> updateGameProfile(GameProfile profile) async {
    final batch = _firestore.batch();

    try {
      // 1. ユーザーサブコレクションを更新
      final profileRef = _firestore
          .collection('users')
          .doc(profile.userId)
          .collection('gameProfiles')
          .doc(profile.gameId);

      batch.update(profileRef, profile.toFirestore());


      await batch.commit();
    } catch (e) {
      throw Exception('ゲームプロフィールの更新に失敗しました: $e');
    }
  }

  @override
  Future<void> deleteGameProfile(String userId, String gameId) async {
    final batch = _firestore.batch();

    try {
      // 1. ユーザーサブコレクションから削除
      final profileRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('gameProfiles')
          .doc(gameId);

      batch.delete(profileRef);


      await batch.commit();
    } catch (e) {
      throw Exception('ゲームプロフィールの削除に失敗しました: $e');
    }
  }


  @override
  Future<List<GameProfile>> getFavoriteGameProfiles(String userId, List<String> gameIds) async {
    if (gameIds.isEmpty) return [];

    try {
      final profiles = <GameProfile>[];

      // 各お気に入りゲームのプロフィールを取得
      for (final gameId in gameIds) {
        final profile = await getGameProfile(userId, gameId);
        if (profile != null) {
          profiles.add(profile);
        }
      }

      return profiles;
    } catch (e) {
      throw Exception('お気に入りゲームプロフィールの取得に失敗しました: $e');
    }
  }

  @override
  Future<GameProfile?> getGameProfileById(String profileId) async {
    try {
      // プロフィールIDの形式: users/{userId}/gameProfiles/{gameId}
      // CollectionGroupクエリを使用してプロフィールIDで検索
      final snapshot = await _firestore
          .collectionGroup('gameProfiles')
          .where(FieldPath.documentId, isEqualTo: profileId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return GameProfile.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('❌ FirestoreGameProfileRepository: Error getting profile by ID: $e');
      return null;
    }
  }
}