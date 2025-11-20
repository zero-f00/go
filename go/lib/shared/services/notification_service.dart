import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/notification_model.dart';

/// 通知管理サービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notifications';

  /// 通知を作成
  Future<bool> createNotification(NotificationData notification) async {
    try {
      print('🔄 NotificationService: Creating notification...');
      print('   - To: ${notification.toUserId}');
      print('   - From: ${notification.fromUserId ?? 'system'}');
      print('   - Type: ${notification.type.name}');
      print('   - Title: ${notification.title}');

      final docRef = await _firestore
          .collection(_collectionName)
          .add(notification.toFirestore());

      print('✅ NotificationService: Notification created with ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('❌ NotificationService: 通知作成エラー: $e');
      return false;
    }
  }

  /// 通知を更新
  Future<bool> updateNotification(String notificationId, {
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🔄 NotificationService: Updating notification $notificationId...');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type.name;
      if (data != null) updateData['data'] = data;

      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update(updateData);

      print('✅ NotificationService: Notification updated successfully');
      return true;
    } catch (e) {
      print('❌ NotificationService: 通知更新エラー: $e');
      return false;
    }
  }

  /// フレンドリクエストの結果で通知を更新
  Future<bool> updateFriendRequestNotification({
    required String notificationId,
    required bool isAccepted,
    required String fromUserName,
  }) async {
    try {
      print('🔄 NotificationService: Updating friend request notification to ${isAccepted ? 'accepted' : 'rejected'}...');

      final title = isAccepted ? 'フレンドリクエスト承認済み' : 'フレンドリクエスト拒否済み';
      final message = isAccepted
          ? '${fromUserName}さんのフレンドリクエストを承認しました'
          : '${fromUserName}さんのフレンドリクエストを拒否しました';
      final type = isAccepted ? NotificationType.friendAccepted : NotificationType.friendRejected;

      return await updateNotification(
        notificationId,
        title: title,
        message: message,
        type: type,
        data: {
          'fromUserName': fromUserName,
          'status': isAccepted ? 'accepted' : 'rejected',
        },
      );
    } catch (e) {
      print('❌ NotificationService: フレンドリクエスト通知更新エラー: $e');
      return false;
    }
  }

  /// フレンドリクエストIDから通知を検索
  Future<NotificationData?> findFriendRequestNotification({
    required String toUserId,
    required String friendRequestId,
  }) async {
    try {
      print('🔍 NotificationService: Searching for friend request notification...');
      print('   - toUserId: $toUserId');
      print('   - friendRequestId: $friendRequestId');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: toUserId)
          .where('type', isEqualTo: NotificationType.friendRequest.name)
          .get();

      for (final doc in querySnapshot.docs) {
        final notification = NotificationData.fromFirestore(doc);
        final data = notification.data;
        if (data != null && data['friendRequestId'] == friendRequestId) {
          print('✅ NotificationService: Found friend request notification: ${notification.id}');
          return notification;
        }
      }

      print('⚠️ NotificationService: Friend request notification not found');
      return null;
    } catch (e) {
      print('❌ NotificationService: フレンドリクエスト通知検索エラー: $e');
      return null;
    }
  }

  /// フレンドリクエスト通知を送信
  Future<bool> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String friendRequestId,
  }) async {
    final notification = NotificationData.friendRequest(
      toUserId: toUserId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      friendRequestId: friendRequestId,
    );

    return await createNotification(notification);
  }

  /// フレンドリクエスト承認通知を送信
  Future<bool> sendFriendAcceptedNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    final notification = NotificationData.friendAccepted(
      toUserId: toUserId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
    );

    return await createNotification(notification);
  }

  /// フレンドリクエスト拒否通知を送信
  Future<bool> sendFriendRejectedNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    final notification = NotificationData.friendRejected(
      toUserId: toUserId,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
    );

    return await createNotification(notification);
  }

  /// ユーザーの通知一覧を取得
  Future<List<NotificationData>> getUserNotifications(String userId) async {
    try {
      print('🔄 NotificationService: Fetching notifications for user: $userId');

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ NotificationService: Found ${querySnapshot.docs.length} notifications');

      final notifications = querySnapshot.docs
          .map((doc) => NotificationData.fromFirestore(doc))
          .toList();

      for (final notification in notifications) {
        print('   - ${notification.id}: ${notification.type.name} - ${notification.title}');
      }

      return notifications;
    } catch (e) {
      print('❌ NotificationService: 通知取得エラー: $e');
      print('   - userId: $userId');
      print('   - collection: $_collectionName');
      return [];
    }
  }

  /// ユーザーの未読通知数を取得
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('未読通知数取得エラー: $e');
      return 0;
    }
  }

  /// 通知を既読にマーク
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('既読マークエラー: $e');
      return false;
    }
  }

  /// 複数の通知を既読にマーク
  Future<bool> markMultipleAsRead(List<String> notificationIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in notificationIds) {
        final docRef = _firestore.collection(_collectionName).doc(id);
        batch.update(docRef, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('一括既読マークエラー: $e');
      return false;
    }
  }

  /// すべての通知を既読にマーク
  Future<bool> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('全て既読マークエラー: $e');
      return false;
    }
  }

  /// 通知を削除
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .delete();
      return true;
    } catch (e) {
      print('通知削除エラー: $e');
      return false;
    }
  }

  /// 古い通知を削除（30日以上経過）
  Future<bool> deleteOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('古い通知削除エラー: $e');
      return false;
    }
  }

  /// ユーザーの通知をリアルタイムで監視
  Stream<List<NotificationData>> watchUserNotifications(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationData.fromFirestore(doc))
            .toList());
  }

  /// 未読通知数をリアルタイムで監視
  Stream<int> watchUnreadNotificationCount(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('toUserId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// イベント参加承認通知を送信
  Future<bool> sendEventApprovedNotification({
    required String toUserId,
    required String eventId,
    required String eventName,
    String? adminMessage,
  }) async {
    try {
      String message = 'イベント「$eventName」への参加申請が承認されました。';
      if (adminMessage != null && adminMessage.isNotEmpty) {
        message += '\n\n運営からのメッセージ:\n$adminMessage';
      }

      final notification = NotificationData(
        toUserId: toUserId,
        fromUserId: null, // システム通知
        type: NotificationType.eventApproved,
        title: 'イベント参加申請が承認されました',
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'adminMessage': adminMessage ?? '',
        },
      );

      return await createNotification(notification);
    } catch (e) {
      print('❌ NotificationService: Error sending event approved notification: $e');
      return false;
    }
  }

  /// イベント参加拒否通知を送信
  Future<bool> sendEventRejectedNotification({
    required String toUserId,
    required String eventId,
    required String eventName,
    String? adminMessage,
  }) async {
    try {
      String message = 'イベント「$eventName」への参加申請が拒否されました。';
      if (adminMessage != null && adminMessage.isNotEmpty) {
        message += '\n\n運営からのメッセージ:\n$adminMessage';
      }

      final notification = NotificationData(
        toUserId: toUserId,
        fromUserId: null, // システム通知
        type: NotificationType.eventRejected,
        title: 'イベント参加申請が拒否されました',
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'adminMessage': adminMessage ?? '',
        },
      );

      return await createNotification(notification);
    } catch (e) {
      print('❌ NotificationService: Error sending event rejected notification: $e');
      return false;
    }
  }

  /// イベント申込み通知を運営者に送信
  Future<bool> sendEventApplicationNotification({
    required String eventId,
    required String eventTitle,
    required String applicantUserId,
    required String applicantUsername,
    required List<String> managerIds,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📧 NotificationService: Sending event application notification...');
      print('   - Event: $eventTitle ($eventId)');
      print('   - Applicant: $applicantUsername ($applicantUserId)');
      print('   - Managers: $managerIds');

      // 各運営者に通知を送信
      for (final managerId in managerIds) {
        final notification = NotificationData(
          toUserId: managerId,
          fromUserId: applicantUserId,
          type: NotificationType.eventApplication,
          title: 'イベント申込みがありました',
          message: '$applicantUsernameさんが「$eventTitle」に申込みをしました',
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': eventId,
            'eventTitle': eventTitle,
            'applicantUserId': applicantUserId,
            'applicantUsername': applicantUsername,
            'applicationId': additionalData?['applicationId'],
            ...?additionalData,
          },
        );

        final success = await createNotification(notification);
        if (!success) {
          print('❌ NotificationService: Failed to send notification to manager: $managerId');
        } else {
          print('✅ NotificationService: Notification sent to manager: $managerId');
        }
      }

      print('✅ NotificationService: Event application notifications sent successfully');
      return true;
    } catch (e) {
      print('❌ NotificationService: Error sending event application notification: $e');
      return false;
    }
  }

  /// 汎用通知送信メソッド（静的メソッド）
  static Future<bool> sendNotification({
    required String toUserId,
    required String type,
    required String title,
    required String message,
    String? fromUserId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // タイプ文字列をNotificationTypeに変換
      NotificationType notificationType;
      switch (type) {
        case 'event_approved':
          notificationType = NotificationType.eventApproved;
          break;
        case 'event_rejected':
          notificationType = NotificationType.eventRejected;
          break;
        case 'friend_request':
          notificationType = NotificationType.friendRequest;
          break;
        case 'friend_accepted':
          notificationType = NotificationType.friendAccepted;
          break;
        case 'friend_rejected':
          notificationType = NotificationType.friendRejected;
          break;
        case 'event_invite':
          notificationType = NotificationType.eventInvite;
          break;
        case 'event_reminder':
          notificationType = NotificationType.eventReminder;
          break;
        default:
          notificationType = NotificationType.system;
      }

      final notification = NotificationData(
        toUserId: toUserId,
        fromUserId: fromUserId,
        type: notificationType,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      return await NotificationService.instance.createNotification(notification);
    } catch (e) {
      print('❌ NotificationService: Error sending notification: $e');
      return false;
    }
  }
}