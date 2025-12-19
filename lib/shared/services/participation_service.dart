import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../../data/models/game_profile_model.dart';
import '../../data/models/notification_model.dart';
import 'notification_service.dart';

/// 参加申し込みのステータス
enum ParticipationStatus {
  pending,    // 申し込み中（承認待ち）
  approved,   // 承認済み
  rejected,   // 拒否済み
  waitlisted, // キャンセル待ち
  cancelled,  // ユーザーがキャンセル
}

/// 参加申し込み結果
enum ParticipationResult {
  success,              // 成功
  eventNotFound,        // イベントが見つからない
  cannotApply,          // 申し込み不可（非公開等）
  alreadyApplied,       // 既に申し込み済み
  incorrectPassword,    // パスワードが間違っている
  eventFull,            // イベント満員
  permissionDenied,     // 権限不足
  networkError,         // ネットワークエラー
  unknownError,         // 不明なエラー
}

/// 参加申し込みデータ
class ParticipationApplication {
  final String id;
  final String eventId;
  final String userId;
  final String userDisplayName;
  final ParticipationStatus status;
  final DateTime appliedAt;
  final String? message; // 申し込み時のメッセージ
  final String? approvalMessage; // 承認時のメッセージ
  final String? rejectionReason; // 拒否理由
  final String? gameUsername; // ゲーム内ユーザー名（必須）
  final String? gameUserId; // ゲーム内ユーザーID（任意）
  final Map<String, dynamic>? gameProfileData; // ゲームプロフィール詳細情報
  final int? waitlistPosition; // キャンセル待ち順位
  final DateTime? waitlistedAt; // キャンセル待ちになった日時
  final String? cancellationReason; // キャンセル理由
  final DateTime? cancelledAt; // キャンセル日時

  const ParticipationApplication({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userDisplayName,
    required this.status,
    required this.appliedAt,
    this.message,
    this.approvalMessage,
    this.rejectionReason,
    this.gameUsername,
    this.gameUserId,
    this.gameProfileData,
    this.waitlistPosition,
    this.waitlistedAt,
    this.cancellationReason,
    this.cancelledAt,
  });

  factory ParticipationApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParticipationApplication(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      status: _parseStatus(data['status']),
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      message: data['message'],
      approvalMessage: data['approvalMessage'],
      rejectionReason: data['rejectionReason'],
      gameUsername: data['gameUsername'],
      gameUserId: data['gameUserId'],
      gameProfileData: data['gameProfileData'] as Map<String, dynamic>?,
      waitlistPosition: data['waitlistPosition'] as int?,
      waitlistedAt: data['waitlistedAt'] != null
          ? (data['waitlistedAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'status': status.name,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'message': message,
      'approvalMessage': approvalMessage,
      'rejectionReason': rejectionReason,
      'gameUsername': gameUsername,
      'gameUserId': gameUserId,
      'gameProfileData': gameProfileData,
      'waitlistPosition': waitlistPosition,
      'waitlistedAt': waitlistedAt != null
          ? Timestamp.fromDate(waitlistedAt!)
          : null,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
    };
  }

  static ParticipationStatus _parseStatus(dynamic value) {
    switch (value?.toString()) {
      case 'approved':
        return ParticipationStatus.approved;
      case 'rejected':
        return ParticipationStatus.rejected;
      case 'waitlisted':
        return ParticipationStatus.waitlisted;
      case 'cancelled':
        return ParticipationStatus.cancelled;
      default:
        return ParticipationStatus.pending;
    }
  }
}

/// 参加申し込みサービス
class ParticipationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// イベントに参加申し込みを行う
  static Future<ParticipationResult> applyToEvent({
    required String eventId,
    required String userId,
    required String userDisplayName,
    String? message,
    String? password, // 招待制の場合
    String? gameUsername, // ゲーム内ユーザー名
    String? gameUserId, // ゲーム内ユーザーID
    GameProfile? gameProfile, // ゲームプロフィール情報
  }) async {
    try {

      // イベント情報を取得
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        return ParticipationResult.eventNotFound;
      }

      final event = Event.fromFirestore(eventDoc);

      // 公開範囲に応じた申し込み可能性チェック
      final canApply = _canApplyToEvent(event, password);
      if (!canApply) {
        if (event.visibility == EventVisibility.inviteOnly &&
            (password == null || password != event.eventPassword)) {
          return ParticipationResult.incorrectPassword;
        }
        return ParticipationResult.cannotApply;
      }

      // 既存の申し込み確認
      final existingApplication = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        return ParticipationResult.alreadyApplied;
      }

      // 現在の承認済み参加者数を確認
      final currentApprovedCount = await getApprovedParticipantCount(eventId);

      if (currentApprovedCount >= event.maxParticipants) {
        // 満員の場合はキャンセル待ちとして申請を作成
        if (gameProfile != null) {
          await _createWaitlistApplication(
            userId: userId,
            event: event,
            gameProfile: gameProfile,
            message: message,
          );
          return ParticipationResult.success; // キャンセル待ち登録は成功として扱う
        } else {
          return ParticipationResult.eventFull; // ゲームプロフィールがない場合は従来通り
        }
      }

      // 定員の80%に達した場合は運営者に警告通知
      if (currentApprovedCount >= (event.maxParticipants * 0.8).round()) {
        await _sendCapacityWarningNotification(
          event: event,
          currentCount: currentApprovedCount,
        );
      }

      // 申し込みを作成
      final application = ParticipationApplication(
        id: '',
        eventId: eventId,
        userId: userId,
        userDisplayName: userDisplayName,
        status: _getInitialStatus(event),
        appliedAt: DateTime.now(),
        message: message,
        gameUsername: gameUsername,
        gameUserId: gameUserId,
        gameProfileData: gameProfile?.toFirestore(),
      );

      final docRef = await _firestore
          .collection('participationApplications')
          .add(application.toFirestore());


      // 自動承認の場合は即座に参加者リストに追加
      if (_getInitialStatus(event) == ParticipationStatus.approved) {
        await _addToParticipants(eventId, userId);
      }

      // イベント管理者（createdBy と managerIds）に通知を送信
      await _sendApplicationNotificationToManagers(
        event: event,
        applicantUserId: userId,
        applicantName: userDisplayName,
        applicationId: docRef.id,
      );

      return ParticipationResult.success;
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          return ParticipationResult.permissionDenied;
        case 'unavailable':
        case 'deadline-exceeded':
          return ParticipationResult.networkError;
        default:
          return ParticipationResult.unknownError;
      }
    } catch (e) {
      return ParticipationResult.unknownError;
    }
  }

  /// イベントの公開範囲に応じて申し込み可能かチェック
  static bool _canApplyToEvent(Event event, String? password) {
    switch (event.visibility) {
      case EventVisibility.public:
        return true;
      case EventVisibility.inviteOnly:
        return password != null && password == event.eventPassword;
      case EventVisibility.private:
        return false; // プライベートイベントは廃止予定（レガシー対応）
    }
  }

  /// イベントの設定に応じた初期ステータス
  static ParticipationStatus _getInitialStatus(Event event) {
    // すべてのイベントで手動承認を必要とする
    // 運営側が承認・拒否を判断できるようにする
    return ParticipationStatus.pending;
  }

  /// 参加者リストに追加
  static Future<void> _addToParticipants(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'participantIds': FieldValue.arrayUnion([userId])
    });
  }

  /// 参加者リストから削除
  static Future<void> _removeFromParticipants(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'participantIds': FieldValue.arrayRemove([userId])
    });
  }

  /// イベント管理者に申込通知を送信
  static Future<void> _sendApplicationNotificationToManagers({
    required Event event,
    required String applicantUserId,
    required String applicantName,
    required String applicationId,
  }) async {
    try {
      // 管理者リストを作成（作成者 + 共同編集者）
      final managers = <String>{};

      // 作成者を追加
      if (event.createdBy != null && event.createdBy != applicantUserId) {
        managers.add(event.createdBy!);
      }

      // 共同編集者を追加（申込者自身を除く）
      for (final managerId in event.managerIds) {
        if (managerId != applicantUserId) {
          managers.add(managerId);
        }
      }

      // 各管理者に通知を送信
      for (final managerId in managers) {
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: managerId,
            fromUserId: applicantUserId,
            type: NotificationType.eventApplication,
            title: 'イベント参加申込',
            message: '${applicantName}さんが「${event.name}」に参加申込をしました',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': event.id,
              'eventName': event.name,
              'applicationId': applicationId,
              'applicantUserId': applicantUserId,
              'applicantName': applicantName,
            },
          ),
        );
      }
    } catch (e) {
      // 通知送信の失敗は申込処理自体の失敗とはしない
    }
  }

  /// 申込結果を申込者に通知
  static Future<void> _sendApplicationResultNotification({
    required ParticipationApplication application,
    required ParticipationStatus status,
    String? adminMessage,
    String? adminUserId, // 承認/拒否を行った管理者のID
  }) async {
    try {
      // イベント情報を取得
      final eventDoc = await _firestore.collection('events').doc(application.eventId).get();
      if (!eventDoc.exists) {
        return;
      }

      final event = Event.fromFirestore(eventDoc);

      // ステータスに応じた通知内容を設定
      NotificationType notificationType;
      String title;
      String message;

      switch (status) {
        case ParticipationStatus.approved:
          notificationType = NotificationType.eventApproved;
          title = 'イベント参加承認';
          message = '「${event.name}」への参加が承認されました${adminMessage != null ? '\n管理者メッセージ: $adminMessage' : ''}';
          break;
        case ParticipationStatus.rejected:
          notificationType = NotificationType.eventRejected;
          title = 'イベント参加申込結果';
          message = '「${event.name}」への参加申込が承認されませんでした${adminMessage != null ? '\n理由: $adminMessage' : ''}';
          break;
        case ParticipationStatus.pending:
          notificationType = NotificationType.eventUpdated;
          title = 'イベント参加申込ステータス変更';
          message = '「${event.name}」への参加申込が申請中に戻されました${adminMessage != null ? '\n理由: $adminMessage' : ''}';
          break;
        default:
          // その他のステータスは通知しない
          return;
      }

      await NotificationService.instance.createNotification(
        NotificationData(
          toUserId: application.userId,
          fromUserId: event.createdBy,
          type: notificationType,
          title: title,
          message: message,
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': application.eventId,
            'eventName': event.name,
            'applicationId': application.id,
            'status': status.name,
            'adminMessage': adminMessage,
          },
        ),
      );

      // 承認・拒否の場合のみ運営者にも通知（差し戻しは申込者のみ）
      if (status == ParticipationStatus.approved || status == ParticipationStatus.rejected) {
        await _sendApplicationResultNotificationToManagers(
          event: event,
          application: application,
          status: status,
          adminMessage: adminMessage,
          excludeUserId: adminUserId,
        );
      }
    } catch (e) {
      // 通知送信の失敗は承認処理自体の失敗とはしない
    }
  }

  /// 参加申込の承認/拒否結果を運営者全員に通知
  static Future<void> _sendApplicationResultNotificationToManagers({
    required Event event,
    required ParticipationApplication application,
    required ParticipationStatus status,
    String? adminMessage,
    String? excludeUserId, // 承認/拒否を行った管理者は除外
  }) async {
    try {
      // 管理者リストを作成（作成者 + 共同編集者）
      final managers = <String>{};

      // 作成者を追加
      if (event.createdBy.isNotEmpty) {
        managers.add(event.createdBy);
      }

      // 共同編集者を追加
      for (final managerId in event.managerIds) {
        managers.add(managerId);
      }

      // 承認/拒否を行った管理者と申請者本人を除外
      managers.remove(excludeUserId);
      managers.remove(application.userId);

      if (managers.isEmpty) {
        return;
      }

      // ステータスに応じたアクションテキストを設定
      String actionText;
      switch (status) {
        case ParticipationStatus.approved:
          actionText = '承認';
          break;
        case ParticipationStatus.rejected:
          actionText = '拒否';
          break;
        case ParticipationStatus.pending:
          actionText = '申請中に差し戻し';
          break;
        default:
          return;
      }
      final title = 'イベント参加申込$actionText';
      final message = '${application.userDisplayName}さんの「${event.name}」への参加申込が${actionText}されました';

      // 各管理者に通知を送信
      for (final managerId in managers) {
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: managerId,
            fromUserId: excludeUserId ?? event.createdBy,
            type: NotificationType.eventApplication,
            title: title,
            message: message,
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': event.id,
              'eventName': event.name,
              'applicationId': application.id,
              'applicantUserId': application.userId,
              'applicantName': application.userDisplayName,
              'status': status.name,
              'adminMessage': adminMessage,
              'isResultNotification': true,
            },
          ),
        );
      }
    } catch (e) {
      // 通知送信の失敗は処理自体の失敗とはしない
    }
  }

  /// ユーザーの参加申し込み状況を取得
  static Future<ParticipationApplication?> getUserParticipationStatus(
    String eventId,
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ParticipationApplication.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// イベントの参加申し込み一覧を取得（主催者用）
  static Stream<List<ParticipationApplication>> getEventApplications(String eventId) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Stream.value(<ParticipationApplication>[]);
    }

    try {
      final query = _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .orderBy('appliedAt', descending: true);

      return query.snapshots()
          .map((snapshot) {
            try {
              final applications = snapshot.docs
                  .map((doc) {
                    return ParticipationApplication.fromFirestore(doc);
                  })
                  .toList();

              return applications;
            } catch (e) {
              // パース中のエラー時は空のリストを返す
              return <ParticipationApplication>[];
            }
          })
          .transform(StreamTransformer<List<ParticipationApplication>, List<ParticipationApplication>>.fromHandlers(
            handleData: (data, sink) => sink.add(data),
            handleError: (error, stackTrace, sink) {
              // Firestoreクエリエラー時は空のリストを返す
              sink.add(<ParticipationApplication>[]);
            },
          ));
    } catch (e) {
      // エラーの場合は空のStreamを返す
      return Stream.value(<ParticipationApplication>[]);
    }
  }

  /// イベント申請をサーバーから強制取得（管理画面用）
  /// キャッシュを無効化してサーバーから最新データを取得
  static Future<List<ParticipationApplication>> getEventApplicationsFromServer(
    String eventId, {
    bool forceFromServer = true,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return <ParticipationApplication>[];
    }

    try {
      final query = _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .orderBy('appliedAt', descending: true);

      final GetOptions options = forceFromServer
          ? const GetOptions(source: Source.server)
          : const GetOptions();

      final snapshot = await query.get(options);

      return snapshot.docs
          .map((doc) {
            try {
              return ParticipationApplication.fromFirestore(doc);
            } catch (e) {
              // パース中のエラー時はnullを返してfilterで除外
              return null;
            }
          })
          .where((app) => app != null)
          .cast<ParticipationApplication>()
          .toList();
    } catch (e) {
      // エラーの場合は空のリストを返す
      return <ParticipationApplication>[];
    }
  }

  /// 参加申し込みを承認/拒否
  static Future<bool> updateApplicationStatus(
    String applicationId,
    ParticipationStatus status, {
    String? rejectionReason, // 後方互換性のため残す
    String? adminMessage, // 管理者メッセージ（承認・拒否両方で使用）
    String? adminUserId, // 承認/拒否を行った管理者のID
  }) async {
    try {

      // rejectionReasonかadminMessageのいずれかを使用
      final message = adminMessage ?? rejectionReason;

      // まず対象のアプリケーションを取得して詳細確認
      final appDoc = await _firestore
          .collection('participationApplications')
          .doc(applicationId)
          .get();

      if (!appDoc.exists) {
        return false;
      }

      final app = ParticipationApplication.fromFirestore(appDoc);

      // 承認時は人数制限をチェック
      if (status == ParticipationStatus.approved) {
        final currentApprovedCount = await getApprovedParticipantCount(app.eventId);

        // イベント情報を取得
        final eventDoc = await _firestore.collection('events').doc(app.eventId).get();
        if (eventDoc.exists) {
          final event = Event.fromFirestore(eventDoc);

          if (currentApprovedCount >= event.maxParticipants) {
            // 定員を超過するため承認できない
            throw Exception('定員を超過するため承認できません（現在 ${currentApprovedCount}/${event.maxParticipants}人）');
          }
        }
      }

      // ステータスに応じて適切なフィールドに保存
      final updateData = {
        'status': status.name,
      };

      if (status == ParticipationStatus.approved && message != null) {
        updateData['approvalMessage'] = message;
      } else if (status == ParticipationStatus.rejected && message != null) {
        updateData['rejectionReason'] = message;
      }

      await _firestore.collection('participationApplications').doc(applicationId).update(updateData);

      // ステータスに応じて参加者リストを更新
      if (status == ParticipationStatus.approved) {
        await _addToParticipants(app.eventId, app.userId);
      } else if (status == ParticipationStatus.rejected || status == ParticipationStatus.pending) {
        // 拒否の場合、または申請中に戻す場合は参加者リストから削除
        // （承認済みから申請中に戻すケースに対応）
        await _removeFromParticipants(app.eventId, app.userId);

        // 承認済みユーザーが辞退した場合、キャンセル待ちユーザーを自動昇格
        // ただし、管理者による差し戻し（updateApplicationStatus）は除外
        // 管理者差し戻しの場合は手動で次のユーザーを承認することを想定
        if (app.status == ParticipationStatus.approved) {
          // 運営者への通知でキャンセル待ちユーザーがいることを知らせる
          await _notifyManagersAboutWaitlistOpportunity(app.eventId);
        }
      }

      // 申込者に結果を通知（運営者への通知も内部で行われる）
      await _sendApplicationResultNotification(
        application: app,
        status: status,
        adminMessage: message,
        adminUserId: adminUserId,
      );

      // 承認により満員になった場合は申請中ユーザーに通知
      // ただし、承認済みから他の状態への変更時（差し戻し）は除外
      if (status == ParticipationStatus.approved && app.status != ParticipationStatus.approved) {
        final eventDoc = await _firestore.collection('events').doc(app.eventId).get();
        if (eventDoc.exists) {
          final event = Event.fromFirestore(eventDoc);
          final newApprovedCount = await getApprovedParticipantCount(app.eventId);

          if (newApprovedCount >= event.maxParticipants) {
            await _notifyPendingUsersAboutWaitlist(event);
          }
        }
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// ユーザーのすべての参加申し込みを取得
  static Future<List<ParticipationApplication>> getUserApplications(String userId) async {
    try {

      // 最初に指定されたuserIdで検索
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();


      // デバッグ: 全ての参加申請を確認（最初の5件）
      try {
        final allApplicationsSnapshot = await _firestore
            .collection('participationApplications')
            .limit(5)
            .get();

        for (final doc in allApplicationsSnapshot.docs) {
          final data = doc.data();
        }
      } catch (e) {
      }

      final applications = querySnapshot.docs
          .map((doc) => ParticipationApplication.fromFirestore(doc))
          .toList();

      // デバッグ情報を詳細出力
      for (int i = 0; i < applications.length; i++) {
        final app = applications[i];
      }

      // 承認済みアプリケーションの数を出力
      final approvedCount = applications.where((app) => app.status == ParticipationStatus.approved).length;

      return applications;
    } catch (e) {
      return [];
    }
  }

  /// FirebaseUIDとカスタムユーザーIDの両方で検索を試みる
  static Future<List<ParticipationApplication>> getUserApplicationsWithBothIds({
    String? firebaseUid,
    String? customUserId,
  }) async {
    try {

      List<ParticipationApplication> applications = [];

      // 1. FirebaseUIDで検索
      if (firebaseUid != null) {
        final firebaseResults = await getUserApplications(firebaseUid);
        applications.addAll(firebaseResults);
      }

      // 2. カスタムユーザーIDでも検索（異なる場合のみ）
      if (customUserId != null && customUserId != firebaseUid) {
        final customResults = await getUserApplications(customUserId);
        applications.addAll(customResults);
      }

      // 重複を除去（eventIdが同じものは除く）
      final uniqueApplications = <String, ParticipationApplication>{};
      for (final app in applications) {
        uniqueApplications[app.eventId] = app;
      }

      final finalApplications = uniqueApplications.values.toList();
      final approvedCount = finalApplications.where((app) => app.status == ParticipationStatus.approved).length;

      return finalApplications;
    } catch (e) {
      return [];
    }
  }

  /// イベントの承認済み参加者数を取得
  static Future<int> getApprovedParticipantCount(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'approved')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      // エラー時は安全のため0を返す
      return 0;
    }
  }

  /// 承認済み参加者のユーザーIDリストを取得
  static Future<List<String>> getApprovedParticipants(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'approved')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      // エラー時は安全のため空リストを返す
      return [];
    }
  }

  /// 申請中ユーザーのIDリストを取得
  static Future<List<String>> getPendingApplicants(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      // エラー時は安全のため空リストを返す
      return [];
    }
  }

  /// 承認済み + 申請中のユーザーIDリストを取得
  static Future<List<String>> getApprovedAndPendingApplicants(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', whereIn: ['approved', 'pending'])
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
    } catch (e) {
      // エラー時は安全のため空リストを返す
      return [];
    }
  }

  /// 申請中ユーザーをキャンセル待ちに変更し通知を送信
  static Future<void> _notifyPendingUsersAboutWaitlist(Event event) async {
    try {
      // 申請中のユーザーを取得（orderByを削除してインデックス問題を回避）
      final pendingApplications = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: event.id)
          .where('status', isEqualTo: 'pending')
          .get();


      // 申請日時順でソート（メモリ内でソート）
      final sortedDocs = List.from(pendingApplications.docs);
      sortedDocs.sort((a, b) {
        final aApplication = ParticipationApplication.fromFirestore(a);
        final bApplication = ParticipationApplication.fromFirestore(b);
        return aApplication.appliedAt.compareTo(bApplication.appliedAt);
      });

      // 各申請中ユーザーをキャンセル待ちに変更し通知を送信
      for (int i = 0; i < sortedDocs.length; i++) {
        final applicationDoc = sortedDocs[i];
        final application = ParticipationApplication.fromFirestore(applicationDoc);

        // ステータスをキャンセル待ちに変更
        await _firestore
            .collection('participationApplications')
            .doc(application.id)
            .update({
          'status': ParticipationStatus.waitlisted.name,
          'waitlistedAt': FieldValue.serverTimestamp(),
          'waitlistPosition': i + 1, // 順位を設定
        });

        // 通知を送信
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: application.userId,
            fromUserId: event.createdBy,
            type: NotificationType.eventWaitlist,
            title: 'イベント満員のお知らせ',
            message: '「${event.name}」は満員となりました。あなたの申請はキャンセル待ち${i + 1}番目として受付中です。参加者が辞退した場合、順番に承認いたします。',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': event.id,
              'eventName': event.name,
              'applicationId': application.id,
              'waitlistPosition': i + 1,
            },
          ),
        );
      }
    } catch (e) {
      // エラーはログに記録するが処理を停止させない
    }
  }

  /// キャンセル待ちユーザーを自動昇格
  static Future<void> _promoteWaitlistUser(String eventId) async {
    try {
      // 最も早いキャンセル待ちユーザーを取得（orderByを削除してインデックス問題を回避）
      final waitlistQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .get();

      if (waitlistQuery.docs.isNotEmpty) {
        // メモリ内でwaitlistPositionでソートして最初のユーザーを取得
        final waitlistApplications = waitlistQuery.docs
            .map((doc) => ParticipationApplication.fromFirestore(doc))
            .toList();

        waitlistApplications.sort((a, b) {
          final aPosition = a.waitlistPosition ?? 999999;
          final bPosition = b.waitlistPosition ?? 999999;
          return aPosition.compareTo(bPosition);
        });

        final waitlistApplication = waitlistApplications.first;

        // イベント情報を取得
        final eventDoc = await _firestore.collection('events').doc(eventId).get();
        if (eventDoc.exists) {
          final event = Event.fromFirestore(eventDoc);

          // キャンセル待ちユーザーを承認済みに昇格
          await updateApplicationStatus(
            waitlistApplication.id,
            ParticipationStatus.approved,
            adminMessage: 'キャンセル待ちから自動承認されました',
            adminUserId: 'system',
          );

          // 残りのキャンセル待ちユーザーの順位を更新
          await _updateWaitlistPositions(eventId);

          // 昇格通知を送信
          await NotificationService.instance.createNotification(
            NotificationData(
              toUserId: waitlistApplication.userId,
              fromUserId: event.createdBy,
              type: NotificationType.eventApproved,
              title: 'イベント参加承認（キャンセル待ちから昇格）',
              message: '「${event.name}」への参加が承認されました。キャンセル待ちから正式な参加者に昇格いたします。',
              isRead: false,
              createdAt: DateTime.now(),
              data: {
                'eventId': eventId,
                'eventName': event.name,
                'applicationId': waitlistApplication.id,
                'promotedFromWaitlist': true,
              },
            ),
          );
        }
      }
    } catch (e) {
      // キャンセル待ち自動昇格に失敗
    }
  }

  /// キャンセル待ち順位を更新
  static Future<void> _updateWaitlistPositions(String eventId) async {
    try {
      final waitlistQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .get();

      // メモリ内でwaitlistPositionでソート
      final waitlistData = waitlistQuery.docs.map((doc) {
        return {
          'doc': doc,
          'application': ParticipationApplication.fromFirestore(doc),
        };
      }).toList();

      waitlistData.sort((a, b) {
        final aApp = a['application'] as ParticipationApplication;
        final bApp = b['application'] as ParticipationApplication;
        final aPosition = aApp.waitlistPosition ?? 999999;
        final bPosition = bApp.waitlistPosition ?? 999999;
        return aPosition.compareTo(bPosition);
      });

      for (int i = 0; i < waitlistData.length; i++) {
        final doc = waitlistData[i]['doc'] as DocumentSnapshot<Map<String, dynamic>>;
        await doc.reference.update({
          'waitlistPosition': i + 1,
        });
      }
    } catch (e) {
      // キャンセル待ち順位更新に失敗
    }
  }

  /// キャンセル待ち申請を作成
  static Future<void> _createWaitlistApplication({
    required String userId,
    required Event event,
    required GameProfile gameProfile,
    String? message,
  }) async {
    try {
      // 現在のキャンセル待ち数を取得して順位を決定
      final waitlistQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: event.id)
          .where('status', isEqualTo: 'waitlisted')
          .get();

      final waitlistPosition = waitlistQuery.docs.length + 1;

      // キャンセル待ち申請を作成
      final application = ParticipationApplication(
        id: '', // Firestoreで自動生成
        eventId: event.id!,
        userId: userId,
        userDisplayName: gameProfile.gameUsername.isNotEmpty
            ? gameProfile.gameUsername
            : gameProfile.userId,
        status: ParticipationStatus.waitlisted,
        appliedAt: DateTime.now(),
        message: message,
        gameUsername: gameProfile.gameUsername,
        gameUserId: gameProfile.gameUserId,
        gameProfileData: gameProfile.toFirestore(),
        waitlistPosition: waitlistPosition,
        waitlistedAt: DateTime.now(),
      );

      // Firestoreに保存
      await _firestore.collection('participationApplications').add(application.toFirestore());

      // キャンセル待ち通知を送信
      await NotificationService.instance.createNotification(
        NotificationData(
          toUserId: userId,
          fromUserId: event.createdBy,
          type: NotificationType.eventWaitlist,
          title: 'イベント満員・キャンセル待ち登録完了',
          message: '「${event.name}」は満員のため、キャンセル待ち$waitlistPosition番目として登録されました。参加者が辞退した場合、順番に承認いたします。',
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': event.id,
            'eventName': event.name,
            'waitlistPosition': waitlistPosition,
          },
        ),
      );
    } catch (e) {
      rethrow; // エラーを再throw
    }
  }

  /// 満員通知を送信
  static Future<void> _sendEventFullNotification({
    required String toUserId,
    required Event event,
  }) async {
    try {
      await NotificationService.instance.createNotification(
        NotificationData(
          toUserId: toUserId,
          fromUserId: null, // システム通知
          type: NotificationType.eventFull,
          title: 'イベント満員',
          message: '「${event.name}」は満員のため申込できませんでした',
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': event.id,
            'eventName': event.name,
            'maxParticipants': event.maxParticipants,
          },
        ),
      );
    } catch (e) {
      // 通知送信の失敗は申込処理自体の失敗とはしない
    }
  }

  /// 定員間近警告通知を運営者に送信
  static Future<void> _sendCapacityWarningNotification({
    required Event event,
    required int currentCount,
  }) async {
    try {
      // 管理者リストを作成（作成者 + 共同編集者）
      final managers = <String>{};

      // 作成者を追加
      if (event.createdBy.isNotEmpty) {
        managers.add(event.createdBy);
      }

      // 共同編集者を追加
      for (final managerId in event.managerIds) {
        managers.add(managerId);
      }

      if (managers.isEmpty) {
        return;
      }

      final percentage = ((currentCount / event.maxParticipants) * 100).round();

      // 各管理者に通知を送信
      for (final managerId in managers) {
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: managerId,
            fromUserId: null, // システム通知
            type: NotificationType.eventCapacityWarning,
            title: 'イベント定員間近',
            message: '「${event.name}」の参加者数が定員の${percentage}%に達しました（${currentCount}/${event.maxParticipants}人）',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': event.id,
              'eventName': event.name,
              'currentCount': currentCount,
              'maxParticipants': event.maxParticipants,
              'percentage': percentage,
            },
          ),
        );
      }
    } catch (e) {
      // 通知送信の失敗は申込処理自体の失敗とはしない
    }
  }

  /// ユーザーがキャンセル可能かどうかを判定
  static Future<bool> canUserCancelParticipation({
    required String applicationId,
    required String userId,
  }) async {
    try {
      // 申請情報を取得
      final appDoc = await _firestore
          .collection('participationApplications')
          .doc(applicationId)
          .get();

      if (!appDoc.exists) return false;

      final application = ParticipationApplication.fromFirestore(appDoc);

      // ユーザーIDが一致するかチェック
      if (application.userId != userId) return false;

      // キャンセル可能なステータスかチェック
      if (![ParticipationStatus.pending, ParticipationStatus.approved, ParticipationStatus.waitlisted]
          .contains(application.status)) {
        return false;
      }

      // イベント情報を取得してキャンセル期限をチェック
      final eventDoc = await _firestore
          .collection('events')
          .doc(application.eventId)
          .get();

      if (!eventDoc.exists) return false;

      final event = Event.fromFirestore(eventDoc);

      // キャンセル期限が設定されている場合はチェック
      if (event.participationCancelDeadline != null) {
        final now = DateTime.now();
        if (now.isAfter(event.participationCancelDeadline!)) {
          return false; // キャンセル期限を過ぎている
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ユーザーキャンセルを実行
  static Future<bool> cancelParticipation({
    required String applicationId,
    required String cancellationReason,
    required String userId,
  }) async {
    try {
      // キャンセル可能かチェック
      if (!await canUserCancelParticipation(
        applicationId: applicationId,
        userId: userId,
      )) {
        return false;
      }

      // 申請情報とイベント情報を取得
      final appDoc = await _firestore
          .collection('participationApplications')
          .doc(applicationId)
          .get();

      if (!appDoc.exists) return false;

      final application = ParticipationApplication.fromFirestore(appDoc);

      final eventDoc = await _firestore
          .collection('events')
          .doc(application.eventId)
          .get();

      if (!eventDoc.exists) return false;

      final event = Event.fromFirestore(eventDoc);

      // バッチ処理でアップデートを実行
      final batch = _firestore.batch();

      // 申請をキャンセル済みに更新
      batch.update(appDoc.reference, {
        'status': ParticipationStatus.cancelled.name,
        'cancellationReason': cancellationReason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // approved状態からのキャンセルの場合、waitlistユーザーを昇格
      if (application.status == ParticipationStatus.approved) {
        await _promoteWaitlistUser(application.eventId);
      }

      // 運営側に通知を送信
      await _sendParticipantCancellationNotification(
        event: event,
        application: application,
        cancellationReason: cancellationReason,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 参加者キャンセル通知を運営側に送信
  static Future<void> _sendParticipantCancellationNotification({
    required Event event,
    required ParticipationApplication application,
    required String cancellationReason,
  }) async {
    try {
      final title = '参加者キャンセル';
      final message = 'イベント「${event.name}」で${application.userDisplayName}さんがキャンセルしました。\n\n'
          'キャンセル理由: $cancellationReason';

      // 運営チームに通知
      final allManagers = <String>{};
      allManagers.addAll(event.managerIds);
      if (event.createdBy.isNotEmpty) {
        allManagers.add(event.createdBy);
      }

      for (final managerId in allManagers) {
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: managerId,
            fromUserId: null, // システム通知
            type: NotificationType.participantCancelled,
            title: title,
            message: message,
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': event.id,
              'eventName': event.name,
              'userId': application.userId,
              'userName': application.userDisplayName,
              'cancellationReason': cancellationReason,
              'originalStatus': application.status.name,
            },
          ),
        );
      }
    } catch (e) {
      // キャンセル通知送信失敗
    }
  }

  /// 管理者に空き枠とキャンセル待ちについて通知
  static Future<void> _notifyManagersAboutWaitlistOpportunity(String eventId) async {
    try {
      // イベント情報を取得
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return;

      final event = Event.fromFirestore(eventDoc);

      // キャンセル待ちユーザー数を取得
      final waitlistQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'waitlisted')
          .get();

      final waitlistCount = waitlistQuery.docs.length;
      if (waitlistCount == 0) return; // キャンセル待ちがいない場合は通知しない

      // 管理者リストを作成
      final managers = <String>{};
      managers.add(event.createdBy);
      managers.addAll(event.managerIds);

      // 各管理者に通知を送信
      for (final managerId in managers) {
        await NotificationService.instance.createNotification(
          NotificationData(
            toUserId: managerId,
            fromUserId: 'system',
            type: NotificationType.eventCapacityWarning,
            title: 'イベント空き枠発生',
            message: '「${event.name}」で参加者の差し戻しにより空き枠が発生しました。キャンセル待ち$waitlistCount名の承認をご検討ください。',
            isRead: false,
            createdAt: DateTime.now(),
            data: {
              'eventId': eventId,
              'eventName': event.name,
              'waitlistCount': waitlistCount,
              'actionType': 'review_waitlist',
            },
          ),
        );
      }
    } catch (e) {
      // キャンセル待ち機会通知に失敗
    }
  }
}

/// ParticipationServiceのプロバイダー
final participationServiceProvider = Provider<ParticipationService>((ref) {
  return ParticipationService();
});

/// ユーザーの参加申し込み状況を監視するプロバイダー
final userParticipationStatusProvider = StreamProvider.family<ParticipationApplication?, ({String eventId, String userId})>((ref, params) {
  return ParticipationService._firestore
      .collection('participationApplications')
      .where('eventId', isEqualTo: params.eventId)
      .where('userId', isEqualTo: params.userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return null;
        }
        return ParticipationApplication.fromFirestore(snapshot.docs.first);
      })
      .handleError((error, stackTrace) {
        // エラーを再throwして、UI側でエラーハンドリングできるようにする
        throw error;
      });
});