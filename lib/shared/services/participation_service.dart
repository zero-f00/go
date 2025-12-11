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
  pending,   // 申し込み中（承認待ち）
  approved,  // 承認済み
  rejected,  // 拒否済み
}

/// 参加申し込み結果
enum ParticipationResult {
  success,              // 成功
  eventNotFound,        // イベントが見つからない
  cannotApply,          // 申し込み不可（非公開等）
  alreadyApplied,       // 既に申し込み済み
  incorrectPassword,    // パスワードが間違っている
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
    };
  }

  static ParticipationStatus _parseStatus(dynamic value) {
    switch (value?.toString()) {
      case 'approved':
        return ParticipationStatus.approved;
      case 'rejected':
        return ParticipationStatus.rejected;
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
  }) async {
    try {
      // イベント情報を取得
      final eventDoc = await _firestore.collection('events').doc(application.eventId).get();
      if (!eventDoc.exists) {
        return;
      }

      final event = Event.fromFirestore(eventDoc);

      final notificationType = status == ParticipationStatus.approved
          ? NotificationType.eventApproved
          : NotificationType.eventRejected;

      final title = status == ParticipationStatus.approved
          ? 'イベント参加承認'
          : 'イベント参加申込結果';

      final message = status == ParticipationStatus.approved
          ? '「${event.name}」への参加が承認されました${adminMessage != null ? '\n管理者メッセージ: $adminMessage' : ''}'
          : '「${event.name}」への参加申込が承認されませんでした${adminMessage != null ? '\n理由: $adminMessage' : ''}';

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
    } catch (e) {
      // 通知送信の失敗は承認処理自体の失敗とはしない
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

  /// 参加申し込みを承認/拒否
  static Future<bool> updateApplicationStatus(
    String applicationId,
    ParticipationStatus status, {
    String? rejectionReason, // 後方互換性のため残す
    String? adminMessage, // 管理者メッセージ（承認・拒否両方で使用）
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
      }

      // 申込者に結果を通知
      await _sendApplicationResultNotification(
        application: app,
        status: status,
        adminMessage: message,
      );

      return true;
    } catch (e) {
      return false;
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