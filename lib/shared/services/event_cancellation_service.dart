import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/participation_service.dart';
import '../services/notification_service.dart';
import '../services/event_service.dart';
import '../../data/models/event_model.dart';

/// イベント中止サービス
class EventCancellationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// イベントを中止する
  static Future<bool> cancelEvent({
    required String eventId,
    required String reason,
  }) async {
    try {
      // バッチ処理でトランザクションを実行
      final batch = _firestore.batch();

      // 1. イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        throw Exception('イベントが見つかりません');
      }

      // 2. イベントステータスを「中止」に更新（eventsコレクション）
      final eventRef = _firestore.collection('events').doc(eventId);
      batch.update(eventRef, {
        'status': EventStatus.cancelled.name,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. game_eventsコレクションも確認して更新
      try {
        final gameEventDoc = await _firestore.collection('game_events').doc(eventId).get();
        print('EventCancellationService: GameEvent exists: ${gameEventDoc.exists}');
        if (gameEventDoc.exists) {
          print('EventCancellationService: Updating game_events collection with status: cancelled');
          final gameEventRef = _firestore.collection('game_events').doc(eventId);
          batch.update(gameEventRef, {
            'status': 'cancelled',
            'cancellationReason': reason,
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          print('EventCancellationService: No corresponding game event found');
        }
      } catch (e) {
        print('EventCancellationService: Game event update error (continuing): $e');
      }

      // 3. 参加申請者一覧を取得
      final applicationsStream = ParticipationService.getEventApplications(eventId);
      final applications = await applicationsStream.first;

      // 4. バッチ処理を実行
      await batch.commit();

      // 5. 通知を非同期で送信（バッチ外で実行）
      _sendCancellationNotifications(event, applications, reason);

      return true;
    } catch (e) {
      print('EventCancellationService: Error cancelling event: $e');
      return false;
    }
  }

  /// 中止通知を送信
  static Future<void> _sendCancellationNotifications(
    Event event,
    List<ParticipationApplication> applications,
    String reason,
  ) async {
    try {
      // 承認済み参加者への通知
      final approvedParticipants = applications
          .where((app) => app.status == ParticipationStatus.approved)
          .toList();

      for (final application in approvedParticipants) {
        await NotificationService.sendEventCancellationNotification(
          userId: application.userId,
          eventId: event.id,
          eventName: event.name,
          reason: reason,
          isApproved: true,
        );
      }

      // 申込み待ちユーザーへの通知
      final pendingParticipants = applications
          .where((app) => app.status == ParticipationStatus.pending)
          .toList();

      for (final application in pendingParticipants) {
        await NotificationService.sendEventCancellationNotification(
          userId: application.userId,
          eventId: event.id,
          eventName: event.name,
          reason: reason,
          isApproved: false,
        );
      }

      // 運営チームへの通知
      final allManagers = <String>{};
      allManagers.addAll(event.managerIds);
      if (event.createdBy.isNotEmpty) {
        allManagers.add(event.createdBy);
      }

      for (final managerId in allManagers) {
        await NotificationService.sendEventCancellationNotificationToManager(
          managerId: managerId,
          eventId: event.id,
          eventName: event.name,
          reason: reason,
          participantCount: approvedParticipants.length,
          pendingCount: pendingParticipants.length,
        );
      }

      print('EventCancellationService: All notifications sent successfully');
    } catch (e) {
      print('EventCancellationService: Error sending notifications: $e');
    }
  }

  /// イベントが中止可能かチェック
  static Future<bool> canCancelEvent(String eventId) async {
    try {
      final event = await EventService.getEventById(eventId);
      if (event == null) return false;

      // 既に中止されているイベントは中止できない
      if (event.status == EventStatus.cancelled) {
        return false;
      }

      // 完了済みイベントは中止できない
      if (event.status == EventStatus.completed) {
        return false;
      }

      // 開催日が過去のイベントは基本的に中止できない
      if (event.eventDate.isBefore(DateTime.now())) {
        return false;
      }

      return true;
    } catch (e) {
      print('EventCancellationService: Error checking cancellation eligibility: $e');
      return false;
    }
  }

  /// 中止されたイベントの情報を取得
  static Future<Map<String, dynamic>?> getCancellationInfo(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return null;

      final data = eventDoc.data();
      if (data == null) return null;

      return {
        'reason': data['cancellationReason'],
        'cancelledAt': data['cancelledAt'],
        'status': data['status'],
      };
    } catch (e) {
      print('EventCancellationService: Error getting cancellation info: $e');
      return null;
    }
  }
}