import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/friend_model.dart';
import 'error_handler_service.dart';

/// フレンド機能を管理するサービスクラス
///
/// このクラスは廃止されました。
/// 代わりに FollowService を使用してください。
/// 相互フォロー（mutual follow）がフレンドと同等の機能を提供します。
@Deprecated('フレンドリクエスト機能は廃止されました。FollowServiceを使用してください。')
class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  static FriendService get instance => _instance;

  /// フレンドリクエストのコレクション参照
  CollectionReference get friendRequestsCollection =>
      FirebaseFirestore.instance.collection('friendRequests');

  /// フレンド関係のコレクション参照
  CollectionReference get friendshipsCollection =>
      FirebaseFirestore.instance.collection('friendships');

  /// フレンドリクエストを送信
  Future<bool> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    String? message,
  }) async {
    try {
      // 自分自身にリクエストを送信しようとしていないかチェック
      if (fromUserId == toUserId) {
        throw Exception('自分自身にフレンドリクエストを送信することはできません');
      }

      // 既にフレンドでないかチェック（先にチェックする）
      final isAlreadyFriend = await areFriends(fromUserId, toUserId);
      if (isAlreadyFriend) {
        throw Exception('既にフレンドです');
      }

      // 既存のリクエストがないかチェック
      final existingRequest = await _getExistingRequest(fromUserId, toUserId);
      if (existingRequest != null) {
        if (existingRequest.isPending) {
          throw Exception('既にフレンドリクエストを送信済みです');
        } else if (existingRequest.isAccepted) {
          // acceptedステータスでもフレンド関係が存在しない場合は
          // フレンド解除済みなので再申請を許可
          // （上のareFriendsチェックで既にフレンドでないことは確認済み）
        } else if (existingRequest.isRejected || existingRequest.isRemoved) {
          // 拒否されたリクエストまたはフレンド解除されたリクエストがある場合は、
          // 新しいリクエストの送信を許可
        }
      }

      // フレンドリクエストを作成
      final request = FriendRequest.create(
        fromUserId: fromUserId,
        toUserId: toUserId,
        message: message,
      );

      await friendRequestsCollection.add(request.toJson());

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フレンドリクエストの送信', e);
      return false;
    }
  }

  /// フレンドリクエストを承認
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final requestDoc = await friendRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('フレンドリクエストが見つかりません');
      }

      final request = FriendRequest.fromFirestore(requestDoc);

      if (!request.isPending) {
        throw Exception('このリクエストは既に処理済みです');
      }

      // フレンドリクエストのステータスを更新
      await friendRequestsCollection.doc(requestId).update(
        request.updateStatus(FriendRequestStatus.accepted).toJson(),
      );

      // フレンド関係を作成
      final friendship = Friendship.create(
        userId1: request.fromUserId,
        userId2: request.toUserId,
      );

      await friendshipsCollection.add(friendship.toJson());

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フレンドリクエストの承認', e);
      return false;
    }
  }

  /// フレンドリクエストを拒否
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      final requestDoc = await friendRequestsCollection.doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('フレンドリクエストが見つかりません');
      }

      final request = FriendRequest.fromFirestore(requestDoc);

      if (!request.isPending) {
        throw Exception('このリクエストは既に処理済みです');
      }

      // フレンドリクエストのステータスを更新
      await friendRequestsCollection.doc(requestId).update(
        request.updateStatus(FriendRequestStatus.rejected).toJson(),
      );

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フレンドリクエストの拒否', e);
      return false;
    }
  }

  /// フレンド関係を削除
  Future<bool> removeFriend(String userId1, String userId2) async {
    try {
      // フレンド関係を検索して削除
      final friendshipQuery = friendshipsCollection
          .where('user1Id', isEqualTo: userId1.compareTo(userId2) < 0 ? userId1 : userId2)
          .where('user2Id', isEqualTo: userId1.compareTo(userId2) < 0 ? userId2 : userId1)
          .limit(1);

      final snapshot = await friendshipQuery.get();
      if (snapshot.docs.isEmpty) {
        throw Exception('フレンド関係が見つかりません');
      }

      await snapshot.docs.first.reference.delete();

      // 対応するフレンドリクエストのステータスを'removed'に更新
      // （再度フレンド申請を可能にするため）
      await _updateFriendRequestStatusToRemoved(userId1, userId2);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('フレンドの削除', e);
      return false;
    }
  }

  /// フレンド解除時にフレンドリクエストのステータスを'removed'に更新
  Future<void> _updateFriendRequestStatusToRemoved(String userId1, String userId2) async {
    try {
      // userId1 -> userId2 方向のリクエストを検索
      final query1 = friendRequestsCollection
          .where('fromUserId', isEqualTo: userId1)
          .where('toUserId', isEqualTo: userId2)
          .where('status', isEqualTo: 'accepted');

      // userId2 -> userId1 方向のリクエストを検索
      final query2 = friendRequestsCollection
          .where('fromUserId', isEqualTo: userId2)
          .where('toUserId', isEqualTo: userId1)
          .where('status', isEqualTo: 'accepted');

      final snapshots = await Future.wait([query1.get(), query2.get()]);

      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          await doc.reference.update({
            'status': 'removed',
            'removedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // エラーが発生してもフレンド削除自体は成功しているのでログのみ
      ErrorHandlerService.logError('フレンドリクエストステータスの更新', e);
    }
  }

  /// 受信したフレンドリクエストを取得
  Future<List<FriendRequest>> getIncomingRequests(String userId) async {
    try {
      final query = friendRequestsCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 送信したフレンドリクエストを取得
  Future<List<FriendRequest>> getOutgoingRequests(String userId) async {
    try {
      final query = friendRequestsCollection
          .where('fromUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => FriendRequest.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// フレンドリストを取得
  Future<List<Friendship>> getFriends(String userId) async {
    try {
      // user1Id または user2Id にユーザーIDが含まれるフレンド関係を検索
      final query1 = friendshipsCollection
          .where('user1Id', isEqualTo: userId);

      final query2 = friendshipsCollection
          .where('user2Id', isEqualTo: userId);

      final snapshots = await Future.wait([
        query1.get(),
        query2.get(),
      ]);

      final friendships = <Friendship>[];
      for (final snapshot in snapshots) {
        friendships.addAll(
          snapshot.docs.map((doc) => Friendship.fromFirestore(doc)),
        );
      }

      return friendships;
    } catch (e) {
      return [];
    }
  }

  /// 二人がフレンドかどうかを確認
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final sortedIds = [userId1, userId2]..sort();

      final query = friendshipsCollection
          .where('user1Id', isEqualTo: sortedIds[0])
          .where('user2Id', isEqualTo: sortedIds[1])
          .limit(1);

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// フレンド関係のステータスを取得
  Future<FriendshipStatus> getFriendshipStatus(String currentUserId, String targetUserId) async {
    try {
      // フレンドかどうかをチェック
      if (await areFriends(currentUserId, targetUserId)) {
        return FriendshipStatus.friends;
      }

      // 送信済みリクエストがあるかチェック
      final outgoingRequest = await _getExistingRequest(currentUserId, targetUserId);
      if (outgoingRequest != null && outgoingRequest.isPending) {
        return FriendshipStatus.requestSent;
      }

      // 受信したリクエストがあるかチェック
      final incomingRequest = await _getExistingRequest(targetUserId, currentUserId);
      if (incomingRequest != null && incomingRequest.isPending) {
        return FriendshipStatus.requestReceived;
      }

      return FriendshipStatus.none;
    } catch (e) {
      return FriendshipStatus.none;
    }
  }

  /// 既存のリクエストを取得
  Future<FriendRequest?> _getExistingRequest(String fromUserId, String toUserId) async {
    try {
      final query = friendRequestsCollection
          .where('fromUserId', isEqualTo: fromUserId)
          .where('toUserId', isEqualTo: toUserId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FriendRequest.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// フレンドリクエストを監視
  Stream<List<FriendRequest>> watchIncomingRequests(String userId) {
    return friendRequestsCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromFirestore(doc))
            .toList());
  }

  /// フレンドリストを監視
  Stream<List<Friendship>> watchFriends(String userId) {
    // 複数のクエリを組み合わせるため、Stream.combineLatest を使用
    final stream1 = friendshipsCollection
        .where('user1Id', isEqualTo: userId)
        .snapshots();

    final stream2 = friendshipsCollection
        .where('user2Id', isEqualTo: userId)
        .snapshots();

    return stream1.asyncExpand((snapshot1) {
      return stream2.map((snapshot2) {
        final friendships = <Friendship>[];
        friendships.addAll(
          snapshot1.docs.map((doc) => Friendship.fromFirestore(doc)),
        );
        friendships.addAll(
          snapshot2.docs.map((doc) => Friendship.fromFirestore(doc)),
        );
        return friendships;
      });
    });
  }
}

/// フレンドシップのステータス
enum FriendshipStatus {
  none,           // フレンドでない
  friends,        // フレンド
  requestSent,    // リクエスト送信済み
  requestReceived, // リクエスト受信済み
}