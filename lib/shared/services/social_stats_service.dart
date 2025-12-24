import '../../data/models/user_model.dart';
import 'follow_service.dart';

/// ソーシャル統計管理サービス
class SocialStatsService {
  static final SocialStatsService _instance = SocialStatsService._internal();
  factory SocialStatsService() => _instance;
  SocialStatsService._internal();

  static SocialStatsService get instance => _instance;

  /// 相互フォロー数を取得
  Future<int> getFriendCount(String userId) async {
    try {
      return await FollowService.instance.getMutualFollowCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// フォロワー数を取得（follows コレクションから取得）
  Future<int> getFollowerCount(String userId) async {
    try {
      return await FollowService.instance.getFollowerCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// フォロー中の数を取得（follows コレクションから取得）
  Future<int> getFollowingCount(String userId) async {
    try {
      return await FollowService.instance.getFollowingCount(userId);
    } catch (e) {
      return 0;
    }
  }

  /// 相互フォローリストを取得
  Future<List<UserData>> getFriendsList(String userId) async {
    try {
      return await FollowService.instance.getMutualFollowsList(userId);
    } catch (e) {
      return [];
    }
  }

  /// フォロワーリストを取得（follows コレクションから取得）
  Future<List<UserData>> getFollowersList(String userId) async {
    try {
      return await FollowService.instance.getFollowersList(userId);
    } catch (e) {
      return [];
    }
  }

  /// フォロー中リストを取得（follows コレクションから取得）
  Future<List<UserData>> getFollowingList(String userId) async {
    try {
      return await FollowService.instance.getFollowingList(userId);
    } catch (e) {
      return [];
    }
  }

  /// ソーシャル統計データをまとめて取得
  Future<SocialStats> getSocialStats(String userId) async {
    try {
      final friendCount = await getFriendCount(userId);
      final followerCount = await getFollowerCount(userId);
      final followingCount = await getFollowingCount(userId);

      return SocialStats(
        friendCount: friendCount,
        followerCount: followerCount,
        followingCount: followingCount,
      );
    } catch (e) {
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
  friends,    // 相互フォロー
  followers,  // フォロワー
  following,  // フォロー中
}

extension SocialListTypeExtension on SocialListType {
  String get displayName {
    switch (this) {
      case SocialListType.friends:
        return '相互フォロー';
      case SocialListType.followers:
        return 'フォロワー';
      case SocialListType.following:
        return 'フォロー中';
    }
  }

  String get emptyMessage {
    switch (this) {
      case SocialListType.friends:
        return 'まだ相互フォローがいません';
      case SocialListType.followers:
        return 'まだフォロワーがいません';
      case SocialListType.following:
        return 'まだ誰もフォローしていません';
    }
  }
}
