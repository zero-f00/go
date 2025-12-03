import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import 'auth_service.dart';

/// Firebase連携でユーザーデータを管理するサービス
class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザーデータを更新
  Future<void> updateCurrentUser({
    String? username,
    String? userId,
    String? bio,
    String? contact,
    List<String>? favoriteGameIds,
    String? photoUrl,
    bool? isSetupCompleted,
    bool? showHostedEvents,
    bool? showParticipatingEvents,
  }) async {
    try {
      // 現在のユーザー認証情報を取得
      final authService = AuthService();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // 更新用のリクエストオブジェクトを作成
      final updateRequest = UpdateUserRequest(
        username: username,
        userId: userId,
        bio: bio,
        contact: contact,
        favoriteGameIds: favoriteGameIds,
        photoUrl: photoUrl,
        isSetupCompleted: isSetupCompleted,
        showHostedEvents: showHostedEvents,
        showParticipatingEvents: showParticipatingEvents,
      );

      // 更新するデータがない場合は何もしない
      if (!updateRequest.hasUpdates) {
        return;
      }

      // Firestoreドキュメントを更新
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateRequest.toJson());

    } catch (e) {
      throw Exception('ユーザーデータの更新に失敗しました: $e');
    }
  }

  /// 指定したユーザーIDでユーザーデータを取得
  Future<UserData?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserData.fromFirestore(doc);
    } catch (e) {
      throw Exception('ユーザーデータの取得に失敗しました: $e');
    }
  }

  /// 現在のユーザーデータを取得
  Future<UserData?> getCurrentUserData() async {
    try {
      final authService = AuthService();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        return null;
      }

      return await getUserData(currentUser.uid);
    } catch (e) {
      throw Exception('現在のユーザーデータの取得に失敗しました: $e');
    }
  }

  /// ユーザーデータをリアルタイムで監視
  Stream<UserData?> watchUserData(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserData.fromFirestore(doc);
    });
  }

  /// 現在のユーザーデータをリアルタイムで監視
  Stream<UserData?> watchCurrentUserData() async* {
    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      yield null;
      return;
    }

    yield* watchUserData(currentUser.uid);
  }
}

/// FirebaseUserService のプロバイダー
final userServiceProvider = Provider<FirebaseUserService>((ref) {
  return FirebaseUserService();
});

/// 現在のユーザーデータを取得する非同期プロバイダー
final currentUserDataProvider = StreamProvider<UserData?>((ref) {
  final userService = ref.read(userServiceProvider);
  return userService.watchCurrentUserData();
});

/// 特定ユーザーのデータを取得するファミリープロバイダー
final userDataProvider = StreamProvider.family<UserData?, String>((ref, userId) {
  final userService = ref.read(userServiceProvider);
  return userService.watchUserData(userId);
});