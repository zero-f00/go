import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/services/firestore_service.dart';
import '../../shared/services/user_service.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

/// ユーザーデータリポジトリ（具象実装）
/// Firestore優先、SharedPreferencesフォールバックのデータ管理
class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final FirestoreService _firestore = FirestoreService();
  final UserService _userService = UserService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 現在のユーザーを取得
  /// Firestoreデータのみ取得、存在しない場合はnullを返す
  Future<UserData?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      // Firestoreからユーザーデータを取得
      final firestoreUser = await getUserById(currentUser.uid);
      if (firestoreUser != null) {
        // データ整合性チェックと修正を実行
        _syncAllGameProfilesFavoriteStatus(firestoreUser.id, firestoreUser.favoriteGameIds);
        return firestoreUser;
      }

      // Firestoreにデータがない場合はnullを返す（自動作成しない）
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 明示的なユーザー作成メソッド（初回設定時のみ使用）
  Future<UserData?> createUserFromAuth() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      // 既にFirestoreにデータが存在するかチェック
      final existingUser = await getUserById(currentUser.uid);
      if (existingUser != null) {
        return existingUser;
      }

      // 認証済みユーザーのFirestoreデータを作成
      return await _createUserFromAuth(currentUser);
    } catch (e) {
      return null;
    }
  }

  /// FirebaseAuthのデータからFirestoreにユーザーを作成
  Future<UserData> _createUserFromAuth(User authUser) async {

    // SharedPreferencesからローカルデータを取得
    final customUserId = await _userService.getUserId();
    final displayName = await _userService.getUserName();
    final bio = await _userService.getUserBio();
    final contact = await _userService.getUserContact();

    // Authデータとローカルデータを組み合わせてユーザーデータを作成
    final userData = UserData.create(
      id: authUser.uid,
      userId: customUserId,
      username: displayName.isNotEmpty ? displayName : (authUser.displayName ?? 'ユーザー'),
      email: authUser.email ?? '',
      bio: bio.isNotEmpty ? bio : null,
      photoUrl: authUser.photoURL,
    );

    // ユーザーIDの重複チェック
    bool isDuplicate = await _firestore.isUserIdDuplicate(userData.userId);
    if (isDuplicate) {
      // 重複している場合は新しいIDを生成
      await _userService.resetUserId();
      final newCustomUserId = await _userService.getUserId();
      final updatedUserData = userData.copyWith(userId: newCustomUserId);
      await createUser(updatedUserData);
      return updatedUserData;
    } else {
      await createUser(userData);
      return userData;
    }
  }

  /// ユーザーを作成
  Future<UserData> createUser(UserData userData) async {
    try {
      await _firestore.createDocument(
        'users/${userData.id}',
        userData.toJson(),
      );

      // ローカルストレージも更新
      await _updateLocalStorage(userData);

      return userData;
    } catch (e) {
      throw Exception('ユーザー作成に失敗しました: $e');
    }
  }

  /// ユーザーIDでユーザー情報を取得
  Future<UserData?> getUserById(String userId) async {
    try {
      final doc = await _firestore.getDocument('users/$userId');
      if (!doc.exists) {
        return null;
      }
      return UserData.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// カスタムユーザーIDでユーザーを検索
  Future<UserData?> getUserByCustomId(String customUserId) async {
    try {
      final query = _firestore.usersCollection
          .where('userId', isEqualTo: customUserId)
          .limit(1);

      final snapshot = await _firestore.executeQuery(query);

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final userData = UserData.fromFirestore(snapshot.docs.first);
      return userData;
    } catch (e) {
      return null;
    }
  }

  /// ユーザー情報を更新（存在しない場合は作成）
  Future<UserData> updateUser(String userId, UpdateUserRequest request) async {
    try {

      // カスタムユーザーIDの重複チェック
      if (request.userId != null) {
        bool isDuplicate = await _firestore.isUserIdDuplicate(
          request.userId!,
          excludeUserId: userId,
        );
        if (isDuplicate) {
          throw Exception('このユーザーIDは既に使用されています');
        }
      }

      // 既存ユーザーの確認
      final existingUser = await getUserById(userId);

      if (existingUser == null) {
        // ユーザーが存在しない場合は作成
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception('認証されたユーザーが見つかりません');
        }

        // 基本ユーザーデータを作成してから更新
        final baseUserData = await _createUserFromAuth(currentUser);
        if (baseUserData == null) {
          throw Exception('ユーザーの作成に失敗しました');
        }
      }

      // Firestoreを更新（setを使用してupsert動作にする）
      await _firestore.setDocument('users/$userId', request.toJson(), merge: true);

      // 更新後のデータを取得
      final updatedUser = await getUserById(userId);
      if (updatedUser == null) {
        throw Exception('ユーザーデータの更新後取得に失敗しました');
      }

      // ローカルストレージも更新
      await _updateLocalStorage(updatedUser);

      return updatedUser;
    } catch (e) {
      throw Exception('ユーザー情報の更新に失敗しました: $e');
    }
  }

  /// ユーザーを削除
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.deleteDocument('users/$userId');

      // ローカルストレージもクリア
      await _userService.clearAllUserData();

    } catch (e) {
      throw Exception('ユーザーの削除に失敗しました: $e');
    }
  }

  /// ユーザーIDの重複チェック
  Future<bool> isUserIdAvailable(String customUserId, {String? excludeUserId}) async {
    try {
      return !(await _firestore.isUserIdDuplicate(customUserId, excludeUserId: excludeUserId));
    } catch (e) {
      return false;
    }
  }

  /// ユーザー検索（ユーザー名とカスタムユーザーID両方で検索）
  Future<List<UserData>> searchUsers(String query, {int limit = 20}) async {
    try {
      final results = <UserData>[];
      final seenIds = <String>{};

      // 1. カスタムユーザーIDで完全一致検索（最優先）
      final exactUserIdMatch = await getUserByCustomId(query);
      if (exactUserIdMatch != null && exactUserIdMatch.isActive) {
        results.add(exactUserIdMatch);
        seenIds.add(exactUserIdMatch.id);
      }

      // 2. ユーザー名での部分一致検索（一時的に簡素化）
      try {
        final usernameQuery = _firestore.usersCollection
            .where('username', isGreaterThanOrEqualTo: query)
            .where('username', isLessThan: query + '\uf8ff')
            .limit(limit);

        final usernameSnapshot = await _firestore.executeQuery(usernameQuery);
        for (final doc in usernameSnapshot.docs) {
          final userData = UserData.fromFirestore(doc);
          // isActiveチェックをクライアント側で実行
          if (!seenIds.contains(doc.id) && userData.isActive) {
            results.add(userData);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        // Username search failed - continue with other searches
      }

      // 3. カスタムユーザーIDでの部分一致検索（前方一致）
      if (results.length < limit) {
        try {
          final userIdQuery = _firestore.usersCollection
              .where('userId', isGreaterThanOrEqualTo: query)
              .where('userId', isLessThan: query + '\uf8ff')
              .limit(limit - results.length);

          final userIdSnapshot = await _firestore.executeQuery(userIdQuery);
          for (final doc in userIdSnapshot.docs) {
            final userData = UserData.fromFirestore(doc);
            // isActiveチェックをクライアント側で実行
            if (!seenIds.contains(doc.id) && userData.isActive) {
              results.add(userData);
              seenIds.add(doc.id);
            }
          }
        } catch (e) {
          // UserID search failed - continue
        }
      }

      return results.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// ユーザーのリアルタイム監視
  Stream<UserData?> watchUser(String userId) {
    try {
      return _firestore.watchDocument('users/$userId').map((doc) {
        if (!doc.exists) return null;
        return UserData.fromFirestore(doc);
      });
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// お気に入りゲームを追加
  Future<UserData> addFavoriteGame(String userId, Game game) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      final favoriteGameIds = List<String>.from(user.favoriteGameIds);

      // 重複チェック
      if (favoriteGameIds.contains(game.id)) {
        throw Exception('このゲームは既にお気に入りに追加されています');
      }

      favoriteGameIds.add(game.id);

      // 1. ユーザーのfavoriteGameIdsを更新
      final request = UpdateUserRequest(favoriteGameIds: favoriteGameIds);
      final updatedUser = await updateUser(userId, request);

      // 2. 対応するゲームプロフィールのisFavoriteフィールドも更新
      try {
        await _syncGameProfileFavoriteStatus(userId, game.id, true);
      } catch (e) {
        // プロフィール同期に失敗しても、ユーザーデータは正常に更新されている
      }

      return updatedUser;
    } catch (e) {
      throw Exception('お気に入りゲームの追加に失敗しました: $e');
    }
  }

  /// お気に入りゲームを削除
  Future<UserData> removeFavoriteGame(String userId, String gameId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      final favoriteGameIds = user.favoriteGameIds
          .where((id) => id != gameId)
          .toList();

      // 1. ユーザーのfavoriteGameIdsを更新
      final request = UpdateUserRequest(favoriteGameIds: favoriteGameIds);
      final updatedUser = await updateUser(userId, request);

      // 2. 対応するゲームプロフィールのisFavoriteフィールドも更新
      try {
        await _syncGameProfileFavoriteStatus(userId, gameId, false);
      } catch (e) {
        // プロフィール同期に失敗しても、ユーザーデータは正常に更新されている
      }

      return updatedUser;
    } catch (e) {
      throw Exception('お気に入りゲームの削除に失敗しました: $e');
    }
  }

  /// 初回セットアップ完了（廃止：userIdの有無で判定するため、このメソッドは互換性のために残されている）
  /// 現在は何も行わず、現在のユーザーデータを返すだけ
  Future<UserData> completeInitialSetup(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }
      return user;
    } catch (e) {
      throw Exception('初回セットアップの完了に失敗しました: $e');
    }
  }

  /// ローカルストレージを更新
  Future<void> _updateLocalStorage(UserData userData) async {
    try {
      await _userService.saveUserName(userData.username);
      await _userService.saveUserBio(userData.bio ?? '');
      await _userService.saveUserContact(userData.contact ?? '');

      // ローカルのカスタムユーザーIDも更新
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userData.userId);
    } catch (e) {
      // Failed to update local storage - continue without throwing
    }
  }

  /// オフラインデータとの同期
  Future<void> syncOfflineData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final isOnline = await _firestore.isOnline();
      if (!isOnline) {
        return;
      }

      // ローカルデータとFirestoreデータの同期処理
      final firestoreUser = await getUserById(currentUser.uid);

      if (firestoreUser != null) {
        // Firestoreデータが新しい場合は、ローカルを更新
        await _updateLocalStorage(firestoreUser);
      } else {
        // Firestoreにデータがない場合は同期をスキップ（自動作成しない）
      }

    } catch (e) {
      // Error syncing offline data - continue without throwing
    }
  }

  /// ゲームプロフィールのお気に入り状態を同期
  Future<void> _syncGameProfileFavoriteStatus(String userId, String gameId, bool isFavorite) async {
    try {
      // ゲームプロフィールが存在するかチェック
      final profilePath = 'users/$userId/gameProfiles/$gameId';
      final profileDoc = await _firestore.getDocument(profilePath);

      if (profileDoc.exists) {
        // プロフィールが存在する場合、isFavoriteフィールドを更新
        await _firestore.updateDocument(profilePath, {'isFavorite': isFavorite});
      }
      // プロフィールが存在しない場合は何もしない（作成はしない）
    } catch (e) {
      // エラーが発生しても続行（ログのみ）
    }
  }

  /// 全てのゲームプロフィールのお気に入り状態を同期（データ整合性チェック）
  Future<void> _syncAllGameProfilesFavoriteStatus(String userId, List<String> favoriteGameIds) async {
    // 非同期でバックグラウンド実行（ユーザー体験に影響させない）
    Future.microtask(() async {
      try {
        // ユーザーの全プロフィールを取得
        final profilesCollection = _firestore.usersCollection
            .doc(userId)
            .collection('gameProfiles');

        final snapshot = await _firestore.executeQuery(profilesCollection);

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final gameId = data['gameId'] as String?;
          final currentIsFavorite = data['isFavorite'] as bool? ?? false;

          if (gameId != null) {
            final shouldBeFavorite = favoriteGameIds.contains(gameId);

            // 不整合がある場合のみ更新
            if (currentIsFavorite != shouldBeFavorite) {
              await _syncGameProfileFavoriteStatus(userId, gameId, shouldBeFavorite);
            }
          }
        }
      } catch (e) {
        // エラーが発生してもサイレントに続行
      }
    });
  }

  /// リポジトリのクリーンアップ
  void dispose() {
    _userService.dispose();
  }
}