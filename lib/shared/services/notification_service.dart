import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/notification_model.dart';
import 'push_notification_service.dart';

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
      // Firestoreに通知を保存
      await _firestore
          .collection(_collectionName)
          .add(notification.toFirestore());

      // プッシュ通知も送信
      await _sendPushNotification(notification);

      // バッジ数を更新
      await _updateBadgeCount(notification.toUserId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// プッシュ通知を送信
  Future<void> _sendPushNotification(NotificationData notification) async {
    try {
      // 実際のプッシュ通知送信（サーバーサイド実装が必要）
      await PushNotificationService.sendPushNotification(
        toUserId: notification.toUserId,
        title: notification.title,
        body: notification.message,
        data: {
          'type': notification.type.name,
          'notificationId': notification.id,
          ...?notification.data,
        },
      );

      // 受信者が現在ログインしている場合のみローカル通知を表示
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == notification.toUserId) {
        final pushService = PushNotificationService.instance;
        if (pushService.isInitialized) {
          await pushService.showTestLocalNotification(
            title: notification.title,
            body: notification.message,
            data: {
              'type': notification.type.name,
              'notificationId': notification.id,
              ...?notification.data,
            },
          );
        }
      }
    } catch (e) {
      // プッシュ通知送信エラーは無視
    }
  }

  /// バッジ数を更新
  Future<void> _updateBadgeCount(String userId) async {
    try {
      final pushService = PushNotificationService.instance;
      if (pushService.isInitialized) {
        // PushNotificationServiceのupdateBadgeCountメソッドを呼び出し
        await pushService.updateBadgeCount();
      }
    } catch (e) {
      // バッジ更新エラーは無視
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

  /// フォロー通知を送信
  Future<bool> sendFollowNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    final notification = NotificationData.follow(
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

  /// イベントの招待通知を無効化（visibility変更時に使用）
  /// 招待制からパブリックに変更された場合、既存の招待通知を無効化する
  Future<bool> invalidateEventInviteNotifications({
    required String eventId,
    required String eventName,
  }) async {
    try {
      // イベントIDでeventInvite通知を検索
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('type', isEqualTo: 'eventInvite')
          .get();

      if (querySnapshot.docs.isEmpty) return true;

      final batch = _firestore.batch();
      int updateCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final notificationData = data['data'] as Map<String, dynamic>?;

        // eventIdが一致する通知のみ更新
        if (notificationData != null && notificationData['eventId'] == eventId) {
          // 通知タイプを一般的なイベント更新に変更し、無効化フラグを設定
          batch.update(doc.reference, {
            'type': 'eventUpdated',
            'title': 'イベント公開設定変更',
            'message': '「$eventName」の公開設定がパブリックに変更されました。パスワードなしで参加申請できます。',
            'data': {
              ...notificationData,
              'inviteInvalidated': true,
              'invalidatedAt': Timestamp.now(),
              'originalType': 'eventInvite',
            },
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
      }
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

  /// 未読通知数を直接取得（キャッシュを使わずサーバーから取得）
  Future<int> getUnreadNotificationCountFromServer(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('toUserId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get(const GetOptions(source: Source.server));

      return querySnapshot.docs.length;
    } catch (e) {
      // サーバーから取得できない場合はキャッシュから取得
      return getUnreadNotificationCount(userId);
    }
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
        case 'event_updated':
          notificationType = NotificationType.eventUpdated;
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

  /// イベントリマインダー通知を送信
  Future<bool> sendEventReminderNotification({
    required String toUserId,
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    int? hoursUntilEvent,
  }) async {
    try {
      final String timeText = hoursUntilEvent != null
          ? '${hoursUntilEvent}時間後'
          : 'まもなく';

      final notification = NotificationData(
        toUserId: toUserId,
        fromUserId: null, // システム通知
        type: NotificationType.eventReminder,
        title: 'イベントリマインダー',
        message: 'イベント「$eventName」が$timeText に開始されます。',
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'eventDate': eventDate.toIso8601String(),
          'hoursUntilEvent': hoursUntilEvent,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      return false;
    }
  }

  /// イベント更新通知を送信
  Future<bool> sendEventUpdateNotification({
    required String toUserId,
    required String eventId,
    required String eventName,
    required String updatedByUserId,
    required String updatedByUserName,
    required String changesSummary,
    required String changesDetail,
    required bool hasCriticalChanges,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final String title = hasCriticalChanges
          ? 'イベント内容の重要な変更'
          : 'イベント内容が更新されました';

      final String message = 'イベント「$eventName」が$updatedByUserName により更新されました。\n\n'
          '変更内容：$changesSummary\n\n'
          'タップして詳細を確認してください。';

      final notification = NotificationData(
        toUserId: toUserId,
        fromUserId: updatedByUserId,
        type: NotificationType.eventUpdated,
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
        data: {
          'eventId': eventId,
          'eventName': eventName,
          'updatedByUserId': updatedByUserId,
          'updatedByUserName': updatedByUserName,
          'changesSummary': changesSummary,
          'changesDetail': changesDetail,
          'hasCriticalChanges': hasCriticalChanges,
          'action': 'view_event_details',
          ...?additionalData,
        },
      );

      return await createNotification(notification);
    } catch (e) {
      return false;
    }
  }

  /// イベント更新通知を参加者と運営者に一括送信
  Future<bool> sendEventUpdateNotifications({
    required String eventId,
    required String eventName,
    required String updatedByUserId,
    required String updatedByUserName,
    required List<String> participantIds,
    required List<String> managerIds,
    required String changesSummary,
    required String changesDetail,
    required bool hasCriticalChanges,
  }) async {
    try {
      // 通知対象者リストを作成（重複を除去）
      final Set<String> recipients = {};
      recipients.addAll(participantIds);
      recipients.addAll(managerIds);

      // 更新者自身は除外
      recipients.remove(updatedByUserId);

      if (recipients.isEmpty) {
        return true; // 通知対象者がいない場合は成功として扱う
      }

      // 各受信者に通知を送信
      int successCount = 0;
      for (final recipientId in recipients) {
        try {
          final success = await sendEventUpdateNotification(
            toUserId: recipientId,
            eventId: eventId,
            eventName: eventName,
            updatedByUserId: updatedByUserId,
            updatedByUserName: updatedByUserName,
            changesSummary: changesSummary,
            changesDetail: changesDetail,
            hasCriticalChanges: hasCriticalChanges,
            additionalData: {
              'isParticipant': participantIds.contains(recipientId),
              'isManager': managerIds.contains(recipientId),
            },
          );

          if (success) {
            successCount++;
          }
        } catch (e) {
          // 個別の送信失敗は続行
        }
      }

      // 半数以上成功していれば成功とみなす
      return successCount >= (recipients.length / 2).ceil();
    } catch (e) {
      return false;
    }
  }
}