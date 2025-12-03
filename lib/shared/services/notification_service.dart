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

      final docRef = await _firestore
          .collection(_collectionName)
          .add(notification.toFirestore());

      return true;
    } catch (e) {
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

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type.name;
      if (data != null) updateData['data'] = data;

      await _firestore
          .collection(_collectionName)
          .doc(notificationId)
          .update(updateData);

      return true;
    } catch (e) {
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
      return false;
    }
  }

  /// フレンドリクエストIDから通知を検索
  Future<NotificationData?> findFriendRequestNotification({
    required String toUserId,
    required String friendRequestId,
  }) async {
    try {

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: toUserId)
          .where('type', isEqualTo: NotificationType.friendRequest.name)
          .get();

      for (final doc in querySnapshot.docs) {
        final notification = NotificationData.fromFirestore(doc);
        final data = notification.data;
        if (data != null && data['friendRequestId'] == friendRequestId) {
          return notification;
        }
      }

      return null;
    } catch (e) {
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

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();


      final notifications = querySnapshot.docs
          .map((doc) => NotificationData.fromFirestore(doc))
          .toList();

      for (final notification in notifications) {
      }

      return notifications;
    } catch (e) {
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
        } else {
        }
      }

      return true;
    } catch (e) {
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
        case 'violation_reported':
          notificationType = NotificationType.violationReported;
          break;
        case 'violation_processed':
          notificationType = NotificationType.violationProcessed;
          break;
        case 'appeal_submitted':
          notificationType = NotificationType.appealSubmitted;
          break;
        case 'appeal_processed':
          notificationType = NotificationType.appealProcessed;
          break;
        case 'violation_dismissed':
          notificationType = NotificationType.violationDismissed;
          break;
        case 'violation_deleted':
          notificationType = NotificationType.violationDeleted;
          break;
        case 'match_report':
          notificationType = NotificationType.matchReport;
          break;
        case 'match_report_response':
          notificationType = NotificationType.matchReportResponse;
          break;
        case 'event_draft_reverted':
          notificationType = NotificationType.eventDraftReverted;
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
      return false;
    }
  }

  /// 違反報告時の通知を送信
  Future<bool> sendViolationReportedNotification({
    required String violatedUserId,
    required String eventId,
    required String eventName,
    required String violationId,
    String? reportedByUserId,
    String? violationType,
    String? severity,
  }) async {
    try {

      // 違反者への匿名通知
      final violatedNotification = NotificationData(
        toUserId: violatedUserId,
        fromUserId: null, // システム通知として匿名化
        type: NotificationType.violationReported,
        title: 'イベントでの違反報告',
        message: 'イベント「$eventName」で違反の報告がありました。内容を確認し、必要に応じて異議申立を行うことができます。タップして詳細を確認してください。',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'isAnonymous': true,
        },
      );

      final success = await createNotification(violatedNotification);
      if (!success) {
        return false;
      }

      // イベント運営者への詳細通知
      await _sendOrganizerViolationNotification(
        eventId: eventId,
        eventName: eventName,
        violationId: violationId,
        reportedByUserId: reportedByUserId,
        violationType: violationType,
        severity: severity,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// イベント運営者への違反報告通知
  Future<void> _sendOrganizerViolationNotification({
    required String eventId,
    required String eventName,
    required String violationId,
    String? reportedByUserId,
    String? violationType,
    String? severity,
  }) async {
    try {
      // イベント情報を取得して運営者を特定
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        final organizerId = eventData['organizerId'] as String?;
        final managerIds = List<String>.from(eventData['managerIds'] ?? []);

        // 運営者リストを作成（主催者 + 管理者）
        final allOrganizerIds = <String>{};
        if (organizerId != null) {
          allOrganizerIds.add(organizerId);
        }
        allOrganizerIds.addAll(managerIds);


        // 各運営者に通知を送信
        for (final orgId in allOrganizerIds) {
          final organizerNotification = NotificationData(
            toUserId: orgId,
            fromUserId: reportedByUserId,
            type: NotificationType.violationReported,
            title: '違反報告の受信',
            message: 'イベント「$eventName」で新しい違反報告がありました。管理画面で確認してください。',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': eventId,
              'eventName': eventName,
              'violationId': violationId,
              'violationType': violationType,
              'severity': severity,
              'isAnonymous': false,
            },
          );

          final success = await createNotification(organizerNotification);
          if (success) {
          } else {
          }
        }
      }
    } catch (e) {
    }
  }

  /// 違反処理完了通知を送信
  Future<bool> sendViolationProcessedNotification({
    required String violatedUserId,
    required String eventId,
    required String eventName,
    required String violationId,
    required String status,
    String? penalty,
    String? processorUserId,
  }) async {
    try {
      String title = '';
      String message = '';

      switch (status) {
        case 'resolved':
          title = '違反報告の処理完了';
          message = 'イベント「$eventName」での違反報告が処理されました。';
          if (penalty != null && penalty.isNotEmpty) {
            message += '\nペナルティ: $penalty';
          }
          break;
        case 'dismissed':
          title = '違反報告の却下';
          message = 'イベント「$eventName」での違反報告が調査の結果、却下されました。';
          break;
        default:
          return false; // その他のステータスは通知しない
      }

      final notification = NotificationData(
        toUserId: violatedUserId,
        fromUserId: processorUserId,
        type: NotificationType.violationProcessed,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'status': status,
          'penalty': penalty,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      return false;
    }
  }

  /// 異議申立提出通知を送信
  Future<bool> sendAppealSubmittedNotification({
    required String eventId,
    required String eventName,
    required String violationId,
    required String appealText,
    required String appellantUserId,
  }) async {
    try {
      // イベント運営者への通知
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        final organizerId = eventData['organizerId'] as String?;
        final managerIds = List<String>.from(eventData['managerIds'] ?? []);

        // 運営者リストを作成（主催者 + 管理者）
        final allOrganizerIds = <String>{};
        if (organizerId != null) {
          allOrganizerIds.add(organizerId);
        }
        allOrganizerIds.addAll(managerIds);


        bool allSuccess = true;

        // 各運営者に通知を送信
        for (final orgId in allOrganizerIds) {
          final notification = NotificationData(
            toUserId: orgId,
            fromUserId: appellantUserId,
            type: NotificationType.appealSubmitted,
            title: '異議申立の受信',
            message: 'イベント「$eventName」の違反報告に対する異議申立がありました。管理画面で確認してください。',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': eventId,
              'eventName': eventName,
              'violationId': violationId,
              'appealText': appealText,
              'appellantUserId': appellantUserId,
            },
          );

          final success = await createNotification(notification);
          if (success) {
          } else {
            allSuccess = false;
          }
        }

        return allSuccess;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 異議申立処理完了通知を送信
  Future<bool> sendAppealProcessedNotification({
    required String violatedUserId,
    required String eventId,
    required String eventName,
    required String violationId,
    required String appealStatus,
    String? appealResponse,
    String? processorUserId,
  }) async {
    try {
      String title = '';
      String message = '';

      switch (appealStatus) {
        case 'approved':
          title = '異議申立が承認されました';
          message = 'イベント「$eventName」での異議申立が承認され、違反記録が取り消されました。';
          break;
        case 'rejected':
          title = '異議申立が却下されました';
          message = 'イベント「$eventName」での異議申立が却下され、違反記録が維持されます。';
          break;
        default:
          return false; // その他のステータスは通知しない
      }

      if (appealResponse != null && appealResponse.isNotEmpty) {
        message += '\n\n運営からの回答:\n$appealResponse';
      }

      final notification = NotificationData(
        toUserId: violatedUserId,
        fromUserId: processorUserId,
        type: NotificationType.appealProcessed,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'appealStatus': appealStatus,
          'appealResponse': appealResponse,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      return false;
    }
  }

  /// 違反記録削除通知を送信
  Future<bool> sendViolationDeletedNotification({
    required String violatedUserId,
    required String reportedByUserId,
    required String eventId,
    required String eventName,
    required String violationId,
    required String deletedByUserId,
    required List<String> organizerIds,
    String? reason,
  }) async {
    try {

      // 1. 違反報告されたユーザーへの通知
      final violatedNotification = NotificationData(
        toUserId: violatedUserId,
        fromUserId: null, // システム通知
        type: NotificationType.violationDeleted,
        title: '違反記録が削除されました',
        message: 'イベント「$eventName」での違反記録が運営により削除されました。${reason != null ? '\n理由: $reason' : ''}',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'deletedByUserId': deletedByUserId,
        },
      );
      await createNotification(violatedNotification);

      // 2. 報告者への通知
      final reporterNotification = NotificationData(
        toUserId: reportedByUserId,
        fromUserId: null, // システム通知
        type: NotificationType.violationDeleted,
        title: '報告した違反記録が削除されました',
        message: 'イベント「$eventName」で報告された違反記録が運営により削除されました。',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'deletedByUserId': deletedByUserId,
        },
      );
      await createNotification(reporterNotification);

      // 3. 全ての運営者への通知
      for (final organizerId in organizerIds) {
        if (organizerId != deletedByUserId) { // 削除実行者以外に通知
          final organizerNotification = NotificationData(
            toUserId: organizerId,
            fromUserId: deletedByUserId,
            type: NotificationType.violationDeleted,
            title: '違反記録が削除されました',
            message: 'イベント「$eventName」の違反記録が削除されました。${reason != null ? '\n理由: $reason' : ''}',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': eventId,
              'eventName': eventName,
              'violationId': violationId,
              'deletedByUserId': deletedByUserId,
            },
          );
          await createNotification(organizerNotification);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 違反記録却下通知を送信
  Future<bool> sendViolationDismissedNotification({
    required String violatedUserId,
    required String reportedByUserId,
    required String eventId,
    required String eventName,
    required String violationId,
    required String dismissedByUserId,
    required List<String> organizerIds,
    String? reason,
  }) async {
    try {

      // 1. 違反報告されたユーザーへの通知
      final violatedNotification = NotificationData(
        toUserId: violatedUserId,
        fromUserId: null, // システム通知
        type: NotificationType.violationDismissed,
        title: '違反記録が却下されました',
        message: 'イベント「$eventName」での違反記録が運営により却下されました。今後、この記録は違反として扱われません。${reason != null ? '\n理由: $reason' : ''}',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'dismissedByUserId': dismissedByUserId,
        },
      );
      await createNotification(violatedNotification);

      // 2. 報告者への通知
      final reporterNotification = NotificationData(
        toUserId: reportedByUserId,
        fromUserId: null, // システム通知
        type: NotificationType.violationDismissed,
        title: '報告した違反記録が却下されました',
        message: 'イベント「$eventName」で報告された違反記録が運営により却下されました。調査の結果、違反に該当しないと判断されました。',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'violationId': violationId,
          'dismissedByUserId': dismissedByUserId,
        },
      );
      await createNotification(reporterNotification);

      // 3. 全ての運営者への通知
      for (final organizerId in organizerIds) {
        if (organizerId != dismissedByUserId) { // 却下実行者以外に通知
          final organizerNotification = NotificationData(
            toUserId: organizerId,
            fromUserId: dismissedByUserId,
            type: NotificationType.violationDismissed,
            title: '違反記録が却下されました',
            message: 'イベント「$eventName」の違反記録が却下されました。${reason != null ? '\n理由: $reason' : ''}',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': eventId,
              'eventName': eventName,
              'violationId': violationId,
              'dismissedByUserId': dismissedByUserId,
            },
          );
          await createNotification(organizerNotification);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// イベント中止通知を参加者に送信
  static Future<bool> sendEventCancellationNotification({
    required String userId,
    required String eventId,
    required String eventName,
    required String reason,
    required bool isApproved,
  }) async {
    try {
      final String title = 'イベント中止のお知らせ';
      String message;

      if (isApproved) {
        message = '参加が確定していたイベント「$eventName」が主催者の都合により中止となりました。\n\n中止理由:\n$reason';
      } else {
        message = '参加申込みをされていたイベント「$eventName」が主催者の都合により中止となりました。\n\n中止理由:\n$reason';
      }

      final notification = NotificationData(
        toUserId: userId,
        fromUserId: null, // システム通知
        type: NotificationType.system,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'reason': reason,
          'isApproved': isApproved,
          'isCancellation': true,
        },
      );

      return await NotificationService.instance.createNotification(notification);
    } catch (e) {
      print('NotificationService: Error sending cancellation notification: $e');
      return false;
    }
  }

  /// イベント中止通知を運営者に送信
  static Future<bool> sendEventCancellationNotificationToManager({
    required String managerId,
    required String eventId,
    required String eventName,
    required String reason,
    required int participantCount,
    required int pendingCount,
  }) async {
    try {
      final String title = 'イベント中止処理完了';
      final String message = 'イベント「$eventName」の中止処理が完了しました。\n\n'
          '参加確定者: ${participantCount}人\n'
          '申込み待ち: ${pendingCount}人\n\n'
          '全ての関係者に通知を送信しました。\n\n'
          '中止理由:\n$reason';

      final notification = NotificationData(
        toUserId: managerId,
        fromUserId: null, // システム通知
        type: NotificationType.system,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'reason': reason,
          'participantCount': participantCount,
          'pendingCount': pendingCount,
          'isManagerNotification': true,
        },
      );

      return await NotificationService.instance.createNotification(notification);
    } catch (e) {
      print('NotificationService: Error sending manager cancellation notification: $e');
      return false;
    }
  }

  /// イベント下書き化通知を参加者に送信
  Future<bool> sendEventDraftRevertedNotification({
    required String toUserId,
    required String eventId,
    required String eventName,
    required String organizerName,
  }) async {
    final notification = NotificationData.eventDraftReverted(
      toUserId: toUserId,
      eventId: eventId,
      eventName: eventName,
      organizerName: organizerName,
    );

    return await createNotification(notification);
  }
}