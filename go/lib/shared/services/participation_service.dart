import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../../data/models/game_profile_model.dart';

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
      print('🎫 ParticipationService: Applying to event $eventId for user $userId');

      // イベント情報を取得
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        print('❌ Event not found: $eventId');
        return ParticipationResult.eventNotFound;
      }

      final event = Event.fromFirestore(eventDoc);

      // 公開範囲に応じた申し込み可能性チェック
      final canApply = _canApplyToEvent(event, password);
      if (!canApply) {
        print('❌ Cannot apply to this event due to visibility settings');
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
        print('⚠️ User has already applied to this event');
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

      print('✅ Application created with ID: ${docRef.id}');

      // 自動承認の場合は即座に参加者リストに追加
      if (_getInitialStatus(event) == ParticipationStatus.approved) {
        await _addToParticipants(eventId, userId);
      }

      return ParticipationResult.success;
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code} - ${e.message}');
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
      print('❌ ParticipationService Error: $e');
      return ParticipationResult.unknownError;
    }
  }

  /// イベントの公開範囲に応じて申し込み可能かチェック
  static bool _canApplyToEvent(Event event, String? password) {
    switch (event.visibility) {
      case EventVisibility.public:
        return true;
      case EventVisibility.private:
        return false; // プライベートイベントは申し込み不可
      case EventVisibility.inviteOnly:
        return password != null && password == event.eventPassword;
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
    print('✅ Added user $userId to participants of event $eventId');
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
      print('❌ Error getting participation status: $e');
      return null;
    }
  }

  /// イベントの参加申し込み一覧を取得（主催者用）
  static Stream<List<ParticipationApplication>> getEventApplications(String eventId) {
    print('🔍 ParticipationService: Getting applications for event: $eventId');

    // 認証状態をチェック
    final currentUser = FirebaseAuth.instance.currentUser;
    print('🔐 ParticipationService: Current user: ${currentUser?.uid}');
    print('🔐 ParticipationService: Is authenticated: ${currentUser != null}');

    if (currentUser == null) {
      print('❌ ParticipationService: No authenticated user');
      return Stream.value(<ParticipationApplication>[]);
    }

    try {
      print('🔍 ParticipationService: Creating Firestore query...');
      final query = _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .orderBy('appliedAt', descending: true);

      print('🔍 ParticipationService: Executing snapshots() query...');

      return query.snapshots()
          .handleError((error) {
            print('❌ ParticipationService: Snapshots error: $error');
            print('❌ ParticipationService: Error type: ${error.runtimeType}');
            if (error is FirebaseException) {
              print('❌ ParticipationService: Firebase error code: ${error.code}');
              print('❌ ParticipationService: Firebase error message: ${error.message}');
            }
            throw error;
          })
          .map((snapshot) {
            print('📊 ParticipationService: Received snapshot with ${snapshot.docs.length} documents');

            try {
              final applications = snapshot.docs
                  .map((doc) {
                    print('📄 ParticipationService: Processing document: ${doc.id}');
                    return ParticipationApplication.fromFirestore(doc);
                  })
                  .toList();

              print('✅ ParticipationService: Successfully processed ${applications.length} applications');
              return applications;
            } catch (e) {
              print('❌ ParticipationService: Error processing documents: $e');
              throw e;
            }
          });
    } catch (e) {
      print('❌ ParticipationService Error in getEventApplications: $e');
      print('❌ ParticipationService Error type: ${e.runtimeType}');
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
      print('🔄 ParticipationService: Starting update for application: $applicationId');
      print('🔄 ParticipationService: New status: ${status.name}');
      print('🔄 ParticipationService: Current user: ${FirebaseAuth.instance.currentUser?.uid}');

      // rejectionReasonかadminMessageのいずれかを使用
      final message = adminMessage ?? rejectionReason;

      // まず対象のアプリケーションを取得して詳細確認
      final appDoc = await _firestore
          .collection('participationApplications')
          .doc(applicationId)
          .get();

      if (!appDoc.exists) {
        print('❌ ParticipationService: Application document not found: $applicationId');
        return false;
      }

      final app = ParticipationApplication.fromFirestore(appDoc);
      print('🔄 ParticipationService: Application event ID: ${app.eventId}');
      print('🔄 ParticipationService: Application user ID: ${app.userId}');

      // イベントデータを確認
      print('🔄 ParticipationService: Checking event data for: ${app.eventId}');

      // eventsコレクションを確認
      final eventDoc = await _firestore.collection('events').doc(app.eventId).get();
      if (eventDoc.exists) {
        final eventData = eventDoc.data()!;
        print('🔄 ParticipationService: Found in events collection');
        print('🔄 ParticipationService: Event createdBy: ${eventData['createdBy']}');
        print('🔄 ParticipationService: Event managerIds: ${eventData['managerIds']}');
        print('🔄 ParticipationService: Current user matches createdBy: ${FirebaseAuth.instance.currentUser?.uid == eventData['createdBy']}');
      } else {
        print('🔄 ParticipationService: Not found in events collection, checking gameEvents...');

        // gameEventsコレクションを確認
        final gameEventDoc = await _firestore.collection('gameEvents').doc(app.eventId).get();
        if (gameEventDoc.exists) {
          final gameEventData = gameEventDoc.data()!;
          print('🔄 ParticipationService: Found in gameEvents collection');
          print('🔄 ParticipationService: GameEvent createdBy: ${gameEventData['createdBy']}');
          print('🔄 ParticipationService: Current user matches createdBy: ${FirebaseAuth.instance.currentUser?.uid == gameEventData['createdBy']}');
        } else {
          print('❌ ParticipationService: Event not found in any collection: ${app.eventId}');
        }
      }

      print('🔄 ParticipationService: Attempting to update application status...');

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

      print('✅ ParticipationService: Successfully updated application status');

      // 承認の場合は参加者リストに追加
      if (status == ParticipationStatus.approved) {
        await _addToParticipants(app.eventId, app.userId);
      }

      return true;
    } catch (e) {
      print('❌ Error updating application status: $e');
      if (e is FirebaseException) {
        print('❌ Firebase error code: ${e.code}');
        print('❌ Firebase error message: ${e.message}');
        print('❌ Firebase error details: ${e.toString()}');
      }
      return false;
    }
  }

  /// ユーザーのすべての参加申し込みを取得
  static Future<List<ParticipationApplication>> getUserApplications(String userId) async {
    try {
      print('🔍 ParticipationService: Getting applications for user: $userId');

      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('userId', isEqualTo: userId)
          .orderBy('appliedAt', descending: true)
          .get();

      print('✅ ParticipationService: Found ${querySnapshot.docs.length} applications for user');

      return querySnapshot.docs
          .map((doc) => ParticipationApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting user applications: $e');
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
      });
});