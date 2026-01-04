import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/follow_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import 'error_handler_service.dart';
import 'notification_service.dart';

/// フォロー機能を管理するサービスクラス
class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  static FollowService get instance => _instance;

  /// フォローのコレクション参照
  CollectionReference get followsCollection =>
      FirebaseFirestore.instance.collection('follows');

  /// ユーザーをフォローする
  Future<bool> follow({
    required String followerId,
    required String followeeId,
  }) async {
    try {
      // 自分自身をフォローしようとしていないかチェック
      if (followerId == followeeId) {
        throw Exception('Cannot follow yourself');
      }

      // 既にフォローしていないかチェック
      final isAlreadyFollowing = await isFollowing(followerId, followeeId);
      if (isAlreadyFollowing) {
        throw Exception('Already following');
      }

      // フォロー関係を作成
      final follow = Follow.create(
        followerId: followerId,
        followeeId: followeeId,
      );

      await followsCollection.add(follow.toFirestore());

      // フォロー通知を送信（オプション）
      await _sendFollowNotification(followerId, followeeId);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フォロー', e);
      return false;
    }
  }

  /// フォローを解除する
  Future<bool> unfollow({
    required String followerId,
    required String followeeId,
  }) async {
    try {
      // フォロー関係を検索して削除
      final query = followsCollection
          .where('followerId', isEqualTo: followerId)
          .where('followeeId', isEqualTo: followeeId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        throw Exception('Follow relationship not found');
      }

      await snapshot.docs.first.reference.delete();

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フォロー解除', e);
      return false;
    }
  }

  /// フォローしているかどうかを確認
  Future<bool> isFollowing(String followerId, String followeeId) async {
    try {
      final query = followsCollection
          .where('followerId', isEqualTo: followerId)
          .where('followeeId', isEqualTo: followeeId)
          .limit(1);

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// フォロー中のユーザー数を取得
  Future<int> getFollowingCount(String userId) async {
    try {
      final query = followsCollection
          .where('followerId', isEqualTo: userId);

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// フォロワー数を取得
  Future<int> getFollowerCount(String userId) async {
    try {
      final query = followsCollection
          .where('followeeId', isEqualTo: userId);

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// フォロー中のユーザーリストを取得
  Future<List<Follow>> getFollowing(String userId) async {
    try {
      final query = followsCollection
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Follow.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// フォロワーリストを取得
  Future<List<Follow>> getFollowers(String userId) async {
    try {
      final query = followsCollection
          .where('followeeId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Follow.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// フォロー中のユーザーリストをUserDataとして取得
  Future<List<UserData>> getFollowingList(String userId) async {
    try {
      final follows = await getFollowing(userId);
      final userRepository = UserRepository();
      final List<UserData> users = [];

      for (final follow in follows) {
        final userData = await userRepository.getUserByCustomId(follow.followeeId);
        if (userData != null) {
          users.add(userData);
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  /// フォロワーリストをUserDataとして取得
  Future<List<UserData>> getFollowersList(String userId) async {
    try {
      final follows = await getFollowers(userId);
      final userRepository = UserRepository();
      final List<UserData> users = [];

      for (final follow in follows) {
        final userData = await userRepository.getUserByCustomId(follow.followerId);
        if (userData != null) {
          users.add(userData);
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  /// フォロー中のユーザーIDリストを取得
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final follows = await getFollowing(userId);
      return follows.map((f) => f.followeeId).toList();
    } catch (e) {
      return [];
    }
  }

  /// フォロワーのユーザーIDリストを取得
  Future<List<String>> getFollowerIds(String userId) async {
    try {
      final follows = await getFollowers(userId);
      return follows.map((f) => f.followerId).toList();
    } catch (e) {
      return [];
    }
  }

  /// 相互フォローかどうかを確認
  Future<bool> isMutualFollow(String userId1, String userId2) async {
    try {
      final isFollowing1 = await isFollowing(userId1, userId2);
      final isFollowing2 = await isFollowing(userId2, userId1);
      return isFollowing1 && isFollowing2;
    } catch (e) {
      return false;
    }
  }

  /// 相互フォロー（=フレンド）のユーザーIDリストを取得
  Future<List<String>> getMutualFollowIds(String userId) async {
    try {
      // 自分がフォローしているユーザーIDリスト
      final followingIds = await getFollowingIds(userId);
      if (followingIds.isEmpty) {
        return [];
      }

      // 自分をフォローしているユーザーIDリスト
      final followerIds = await getFollowerIds(userId);
      if (followerIds.isEmpty) {
        return [];
      }

      // 両方に含まれるユーザーID = 相互フォロー
      final mutualIds = followingIds
          .where((id) => followerIds.contains(id))
          .toList();

      return mutualIds;
    } catch (e) {
      return [];
    }
  }

  /// 相互フォロー（=フレンド）のユーザーリストをUserDataとして取得
  Future<List<UserData>> getMutualFollowsList(String userId) async {
    try {
      final mutualIds = await getMutualFollowIds(userId);
      if (mutualIds.isEmpty) {
        return [];
      }

      final userRepository = UserRepository();
      final List<UserData> users = [];

      for (final id in mutualIds) {
        final userData = await userRepository.getUserByCustomId(id);
        if (userData != null) {
          users.add(userData);
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }

  /// 相互フォロー数を取得
  Future<int> getMutualFollowCount(String userId) async {
    try {
      final mutualIds = await getMutualFollowIds(userId);
      return mutualIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// フォロー中のユーザーを監視
  Stream<List<Follow>> watchFollowing(String userId) {
    return followsCollection
        .where('followerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Follow.fromFirestore(doc))
            .toList());
  }

  /// フォロワーを監視
  Stream<List<Follow>> watchFollowers(String userId) {
    return followsCollection
        .where('followeeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Follow.fromFirestore(doc))
            .toList());
  }

  /// フォロー通知を送信
  Future<void> _sendFollowNotification(String followerId, String followeeId) async {
    try {
      final userRepository = UserRepository();
      final followerData = await userRepository.getUserByCustomId(followerId);
      final followeeData = await userRepository.getUserByCustomId(followeeId);

      if (followerData != null && followeeData != null) {
        await NotificationService.instance.sendFollowNotification(
          toUserId: followeeData.id, // Firebase UID
          fromUserId: followerData.id, // Firebase UID
          fromUserName: followerData.username,
        );
      }
    } catch (e) {
      // 通知送信の失敗はフォロー処理自体には影響させない
      ErrorHandlerService.logError('フォロー通知の送信', e);
    }
  }
}

/// フォロー状態
enum FollowStatus {
  notFollowing,  // フォローしていない
  following,     // フォロー中
  mutual,        // 相互フォロー
}
