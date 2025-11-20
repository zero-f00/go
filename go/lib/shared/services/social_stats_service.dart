import '../../data/models/user_model.dart';
import 'friend_service.dart';
import '../../data/repositories/user_repository.dart';

/// ソーシャル統計管理サービス
class SocialStatsService {
  static final SocialStatsService _instance = SocialStatsService._internal();
  factory SocialStatsService() => _instance;
  SocialStatsService._internal();

  static SocialStatsService get instance => _instance;

  /// フレンド数を取得
  Future<int> getFriendCount(String userId) async {
    try {
      final friendships = await FriendService.instance.getFriends(userId);
      return friendships.length;
    } catch (e) {
      print('Error getting friend count: $e');
      return 0;
    }
  }

  /// フォロワー数を取得（現在は双方向フレンド関係のみ）
  Future<int> getFollowerCount(String userId) async {
    try {
      // 現在の実装では、フレンド = フォロワーとして扱う
      return await getFriendCount(userId);
    } catch (e) {
      print('Error getting follower count: $e');
      return 0;
    }
  }

  /// フレンドリストを取得（UserDataとして）
  Future<List<UserData>> getFriendsList(String userId) async {
    try {
      final friendships = await FriendService.instance.getFriends(userId);
      final userRepository = UserRepository();
      final List<UserData> friends = [];

      for (final friendship in friendships) {
        // friendship.user1Id か user2Id のうち、userIdでない方を取得
        String friendUserId;
        if (friendship.user1Id == userId) {
          friendUserId = friendship.user2Id;
        } else {
          friendUserId = friendship.user1Id;
        }

        final friendData = await userRepository.getUserByCustomId(friendUserId);
        if (friendData != null) {
          friends.add(friendData);
        }
      }

      return friends;
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }

  /// フォロワーリストを取得（現在は双方向フレンド関係のみ）
  Future<List<UserData>> getFollowersList(String userId) async {
    try {
      // 現在の実装では、フレンドリスト = フォロワーリストとして扱う
      return await getFriendsList(userId);
    } catch (e) {
      print('Error getting followers list: $e');
      return [];
    }
  }

  /// ソーシャル統計データをまとめて取得
  Future<SocialStats> getSocialStats(String userId) async {
    try {
      final friendCount = await getFriendCount(userId);
      final followerCount = await getFollowerCount(userId);

      return SocialStats(
        friendCount: friendCount,
        followerCount: followerCount,
        followingCount: friendCount, // 現在は双方向なので同じ
      );
    } catch (e) {
      print('Error getting social stats: $e');
      return const SocialStats(
        friendCount: 0,
        followerCount: 0,
        followingCount: 0,
      );
    }
  }
}

/// ソーシャル統計データモデル
class SocialStats {
  final int friendCount;
  final int followerCount;
  final int followingCount;

  const SocialStats({
    required this.friendCount,
    required this.followerCount,
    required this.followingCount,
  });

  @override
  String toString() {
    return 'SocialStats(friends: $friendCount, followers: $followerCount, following: $followingCount)';
  }
}

/// ソーシャルリストの種類
enum SocialListType {
  friends,    // フレンド
  followers,  // フォロワー
  following,  // フォロー中
}

extension SocialListTypeExtension on SocialListType {
  String get displayName {
    switch (this) {
      case SocialListType.friends:
        return 'フレンド';
      case SocialListType.followers:
        return 'フォロワー';
      case SocialListType.following:
        return 'フォロー中';
    }
  }

  String get emptyMessage {
    switch (this) {
      case SocialListType.friends:
        return 'まだフレンドがいません';
      case SocialListType.followers:
        return 'まだフォロワーがいません';
      case SocialListType.following:
        return 'まだ誰もフォローしていません';
    }
  }
}