import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
          .where('isActive', isEqualTo: true) // アクティブなユーザーのみ取得
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
        await _createUserFromAuth(currentUser);
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

  /// ユーザーを削除（危険なため無効化）
  @Deprecated('deleteUser is dangerous and deprecated. Use deactivateUser instead.')
  Future<void> deleteUser(String userId) async {
    throw Exception('deleteUser is deprecated due to safety concerns. Use deactivateUser instead.');
  }

  /// 安全なユーザー退会処理（退会時完結型）
  /// 個人情報を即座に匿名化し、isActiveをfalseに設定
  Future<void> deactivateUser(String userId) async {
    try {
      // 認証状態の確認
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw Exception('認証されていないか、ユーザーIDが一致しません');
      }

      // ステップ1: Firestoreユーザーデータの匿名化（認証が有効な間に実行）
      final anonymizedUsername = 'deleted_user_${DateTime.now().millisecondsSinceEpoch}';

      final deactivationTime = DateTime.now();
      await _firestore.updateDocument('users/$userId', {
        'isActive': false,
        'updatedAt': deactivationTime,
        'deactivatedAt': deactivationTime, // 退会日時を記録
        // 個人識別情報の即座削除
        'userId': null, // ユーザーIDをnullにして再利用可能にする
        'username': anonymizedUsername,
        'email': null,
        'bio': null,
        'contact': null,
        'photoUrl': null,
      });

      // ステップ2: Firebase Storageファイルを削除（認証が有効な間に実行）
      await _deleteUserImages(userId);

      // ステップ3: 関連データのクリーンアップ（認証が有効な間に実行）
      await _cleanupRelatedData(userId);

      // ステップ4: Firebase Authentication アカウントの削除（最後に実行）
      try {
        await currentUser.delete();
      } catch (authError) {
        // requires-recent-loginエラーの場合の処理
        if (authError.toString().contains('requires-recent-login')) {
          // 再認証が必要なことを示すエラーをスロー
          throw Exception('REQUIRES_REAUTHENTICATION: セキュリティのため再認証が必要です。もう一度ログインしてから退会処理を行ってください。');
        } else {
          // その他のエラーはそのままスロー
          throw authError;
        }
      }

      // ステップ5: ローカルストレージもクリア
      await _userService.clearAllUserData();


    } catch (e) {

      // エラー時はサインアウトして状態をクリア
      try {
        await _auth.signOut();
        await _userService.clearAllUserData();
      } catch (cleanupError) {
      }

      throw Exception('ユーザーの退会処理に失敗しました: $e');
    }
  }

  /// Firebase Storage内のユーザー画像を削除
  Future<void> _deleteUserImages(String userId) async {
    try {
      final storage = FirebaseStorage.instance;

      // プロフィール画像（レガシーパス）
      try {
        await storage.ref('profile_images/$userId').delete();
      } catch (e) {
        // ファイルが存在しない場合のエラーハンドリング
      }

      // 現在のアバター画像（正確なパス）
      try {
        final avatarsRef = storage.ref('users/$userId/avatars');
        final avatarListResult = await avatarsRef.listAll();

        for (final item in avatarListResult.items) {
          await item.delete();
        }
      } catch (e) {
        // ファイルが存在しない場合のエラーハンドリング
      }

      // ユーザーフォルダ内の全画像（サブフォルダ含む）
      try {
        final userFolderRef = storage.ref('users/$userId');
        final listResult = await userFolderRef.listAll();

        // フォルダ内のファイルを全削除
        for (final item in listResult.items) {
          await item.delete();
        }

        // サブフォルダも再帰的に削除
        for (final prefix in listResult.prefixes) {
          await _deleteStorageFolder(prefix);
        }
      } catch (e) {
        // ファイルが存在しない場合のエラーハンドリング
      }

    } catch (e) {
      // Storage削除失敗は退会処理全体を停止させない
    }
  }

  /// Firebase Storageフォルダを再帰的に削除
  Future<void> _deleteStorageFolder(Reference folderRef) async {
    try {
      final listResult = await folderRef.listAll();

      // フォルダ内のファイルを削除
      for (final item in listResult.items) {
        await item.delete();
      }

      // サブフォルダも再帰的に削除
      for (final prefix in listResult.prefixes) {
        await _deleteStorageFolder(prefix);
      }
    } catch (e) {
      // フォルダ削除エラーは無視して続行
    }
  }

  /// 退会時の関連データクリーンアップ処理
  Future<void> _cleanupRelatedData(String userId) async {
    try {
      // 匿名化IDを生成（一貫した使用のため）
      final anonymizedId = _generateAnonymizedId(userId);
      // 並行実行で効率化
      await Future.wait([
        _deleteUserGameProfiles(userId),
        _cleanupUserNotifications(userId, anonymizedId),
        _cleanupParticipationApplications(userId, anonymizedId),
        _cleanupFriendRequests(userId, anonymizedId),
        _handleEventOwnershipTransfer(userId, anonymizedId),
        _removeUserFromEvents(userId),
      ]);

    } catch (e) {
      // クリーンアップエラーもログは取るが、メイン処理は継続
    }
  }

  /// 匿名化IDを生成
  String _generateAnonymizedId(String originalUserId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'anon_user_${timestamp}_${originalUserId.substring(0, 8)}';
  }

  /// イベント作成者が退会する場合の権限移譲処理
  Future<void> _handleEventOwnershipTransfer(String deletedUserId, String anonymizedId) async {
    try {
      final ownedEvents = await FirebaseFirestore.instance
          .collection('events')
          .where('createdBy', isEqualTo: deletedUserId)
          .where('status', whereIn: ['published', 'draft'])
          .get();

      for (final doc in ownedEvents.docs) {
        final eventData = doc.data();
        final managerIds = List<String>.from(eventData['managerIds'] ?? []);

        // 退会ユーザーをマネージャーリストからも削除
        managerIds.remove(deletedUserId);

        if (managerIds.isNotEmpty) {
          // 最初の運営者に権限移譲
          await doc.reference.update({
            'createdBy': managerIds.first,
            'managerIds': managerIds.where((id) => id != managerIds.first).toList(),
            'originalCreator': anonymizedId, // 統計目的で匿名化IDを保持
            'ownershipTransferredAt': DateTime.now(),
            'ownershipTransferReason': 'user_withdrawal',
          });
        } else {
          // 運営者がいない場合はイベントを下書きに戻し、匿名化
          await doc.reference.update({
            'status': 'draft',
            'createdBy': anonymizedId, // 匿名化IDに置換
            'ownershipTransferredAt': DateTime.now(),
            'ownershipTransferReason': 'user_withdrawal_no_managers',
          });
        }
      }
    } catch (e) {
    }
  }

  /// イベント参加者・管理者リストから退会ユーザーを削除
  Future<void> _removeUserFromEvents(String userId) async {
    try {
      // 管理者として参加しているイベント
      final managedEvents = await FirebaseFirestore.instance
          .collection('events')
          .where('managerIds', arrayContains: userId)
          .get();

      for (final doc in managedEvents.docs) {
        final eventData = doc.data();
        final managerIds = List<String>.from(eventData['managerIds'] ?? [])
          ..remove(userId);

        await doc.reference.update({
          'managerIds': managerIds,
        });
      }

      // 参加者として参加しているイベント
      final participantEvents = await FirebaseFirestore.instance
          .collection('events')
          .where('participantIds', arrayContains: userId)
          .get();

      for (final doc in participantEvents.docs) {
        final eventData = doc.data();
        final participantIds = List<String>.from(eventData['participantIds'] ?? [])
          ..remove(userId);

        await doc.reference.update({
          'participantIds': participantIds,
        });
      }
    } catch (e) {
    }
  }

  /// ユーザーのゲームプロフィールを削除
  Future<void> _deleteUserGameProfiles(String userId) async {
    try {
      final gameProfiles = await _firestore.usersCollection
          .doc(userId)
          .collection('gameProfiles')
          .get();

      for (final doc in gameProfiles.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
    }
  }

  /// ユーザーの通知データをクリーンアップ
  Future<void> _cleanupUserNotifications(String userId, String anonymizedId) async {
    try {
      // 退会ユーザー宛ての通知を全削除（過去の受信通知含む）
      final toUserNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .get();

      for (final doc in toUserNotifications.docs) {
        await doc.reference.delete();
      }

      // 退会ユーザーからの通知は送信者名を匿名化
      final fromUserNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('fromUserId', isEqualTo: userId)
          .get();

      for (final doc in fromUserNotifications.docs) {
        await doc.reference.update({
          'fromUserId': anonymizedId, // 匿名化IDを使用
          'data.fromUserName': '退会したユーザー',
        });
      }
    } catch (e) {
    }
  }

  /// 参加申込みデータの処理
  Future<void> _cleanupParticipationApplications(String userId, String anonymizedId) async {
    try {
      // 進行中の申込みを取り下げ状態に
      final applications = await FirebaseFirestore.instance
          .collection('participationApplications')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in applications.docs) {
        await doc.reference.update({
          'status': 'withdrawn',
          'userId': anonymizedId, // 匿名化IDで置換
          'userDisplayName': '退会したユーザー',
          'withdrawnAt': DateTime.now(),
          'withdrawnReason': 'user_withdrawal',
        });
      }
    } catch (e) {
    }
  }

  /// フレンドリクエストの処理
  Future<void> _cleanupFriendRequests(String userId, String anonymizedId) async {
    try {
      // 送信済みリクエストをキャンセル
      final sentRequests = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in sentRequests.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'fromUserId': anonymizedId, // 匿名化IDで置換
          'cancelledAt': DateTime.now(),
          'cancelledReason': 'user_withdrawal',
        });
      }

      // 受信済みリクエストも処理
      final receivedRequests = await FirebaseFirestore.instance
          .collection('friendRequests')
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in receivedRequests.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'toUserId': anonymizedId, // 匿名化IDで置換
          'cancelledAt': DateTime.now(),
          'cancelledReason': 'user_withdrawal',
        });
      }
    } catch (e) {
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
      } else {
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