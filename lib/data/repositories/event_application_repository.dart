import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_application_model.dart';
import '../models/game_profile_model.dart';
import '../models/user_model.dart';
// import '../../shared/services/notification_service.dart';

/// イベント参加申込リポジトリ
class EventApplicationRepository {
  static final EventApplicationRepository _instance =
      EventApplicationRepository._internal();
  factory EventApplicationRepository() => _instance;
  EventApplicationRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// イベントの全申込を取得
  Future<List<EventApplication>> getEventApplications(String eventId) async {
    try {
      final query = _firestore
          .collection('event_applications')
          .where('eventId', isEqualTo: eventId)
          .orderBy('appliedAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EventApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 特定ステータスの申込を取得
  Future<List<EventApplication>> getApplicationsByStatus(
    String eventId,
    ApplicationStatus status,
  ) async {
    try {
      final query = _firestore
          .collection('event_applications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: status.name)
          .orderBy('appliedAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => EventApplication.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 申込を作成
  Future<EventApplication?> createApplication(EventApplication application) async {
    try {
      final docRef = await _firestore
          .collection('event_applications')
          .add(application.toFirestore());

      // 申込み作成後、運営者に通知を送信
      await _sendApplicationNotification(application.copyWith(id: docRef.id));

      return application.copyWith(id: docRef.id);
    } catch (e) {
      return null;
    }
  }

  /// 申込ステータスを更新
  Future<EventApplication?> updateApplicationStatus(
    String applicationId,
    ApplicationStatus newStatus, {
    String? processedBy,
    String? adminComment,
  }) async {
    try {
      final updateData = {
        'status': newStatus.name,
        'processedAt': Timestamp.now(),
        if (processedBy != null) 'processedBy': processedBy,
        if (adminComment != null) 'adminComment': adminComment,
      };

      await _firestore
          .collection('event_applications')
          .doc(applicationId)
          .update(updateData);

      // 更新後のデータを取得して返す
      final doc = await _firestore
          .collection('event_applications')
          .doc(applicationId)
          .get();

      if (doc.exists) {
        return EventApplication.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ユーザーの申込を取得
  Future<EventApplication?> getUserApplication(
    String eventId,
    String userId,
  ) async {
    try {
      final query = _firestore
          .collection('event_applications')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .limit(1);

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      return EventApplication.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// 申込を削除
  Future<bool> deleteApplication(String applicationId) async {
    try {
      await _firestore
          .collection('event_applications')
          .doc(applicationId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 申込数の統計を取得
  Future<Map<ApplicationStatus, int>> getApplicationStats(String eventId) async {
    try {
      final applications = await getEventApplications(eventId);
      final stats = <ApplicationStatus, int>{};

      for (final status in ApplicationStatus.values) {
        stats[status] = applications.where((app) => app.status == status).length;
      }

      return stats;
    } catch (e) {
      return {};
    }
  }

  /// リアルタイム監視
  Stream<List<EventApplication>> watchEventApplications(String eventId) {
    try {
      return _firestore
          .collection('event_applications')
          .where('eventId', isEqualTo: eventId)
          .orderBy('appliedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => EventApplication.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  void dispose() {
    // No-op
  }

  /// 申込み通知を運営者に送信
  Future<void> _sendApplicationNotification(EventApplication application) async {
    try {
      // イベント情報を取得
      final eventDoc = await _firestore
          .collection('events')
          .doc(application.eventId)
          .get();

      if (!eventDoc.exists) {
        return;
      }

      // 申込者情報を取得
      final applicantDoc = await _firestore
          .collection('users')
          .where('userId', isEqualTo: application.userId)
          .limit(1)
          .get();

      if (applicantDoc.docs.isEmpty) {
        return;
      }

      // TODO: 通知サービスを使用して通知を送信（一時的に削除）
      // eventDoc.data()とapplicantDoc.docs.first.data()でイベント・申込者情報が取得可能

    } catch (e) {
      // 通知送信失敗は申込み作成自体は成功とする
    }
  }
}

/// 詳細情報付きの申込データ
class ApplicationWithDetails {
  final EventApplication application;
  final UserData? userData;
  final GameProfile? gameProfile;

  const ApplicationWithDetails({
    required this.application,
    this.userData,
    this.gameProfile,
  });
}