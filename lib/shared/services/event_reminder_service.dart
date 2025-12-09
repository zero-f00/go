import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../../data/models/event_model.dart';
import '../../shared/services/participation_service.dart';

/// イベントリマインダーサービス
/// 参加者にイベント開催前に自動的にリマインダー通知を送信
class EventReminderService {
  static final EventReminderService _instance = EventReminderService._internal();
  factory EventReminderService() => _instance;
  EventReminderService._internal();

  static EventReminderService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _reminderTimer;

  /// リマインダーサービスを開始
  void startReminderService() {
    print('🔔 EventReminderService: Starting reminder service...');

    // 30分ごとにリマインダーチェックを実行
    _reminderTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkAndSendReminders();
    });

    // サービス開始時にも一度チェック
    _checkAndSendReminders();
  }

  /// リマインダーサービスを停止
  void stopReminderService() {
    print('🔔 EventReminderService: Stopping reminder service...');
    _reminderTimer?.cancel();
    _reminderTimer = null;
  }

  /// リマインダーをチェックして送信
  Future<void> _checkAndSendReminders() async {
    try {
      print('🔔 EventReminderService: Checking for upcoming events...');

      final now = DateTime.now();

      // 今から1時間後〜25時間後の範囲のイベントを取得
      final oneHourLater = now.add(const Duration(hours: 1));
      final twentyFiveHoursLater = now.add(const Duration(hours: 25));

      // 公開中のイベントを取得（一時的にクライアント側でフィルタリング）
      final eventsQuery = await _firestore
          .collection('events')
          .where('status', isEqualTo: 'published')
          .get();

      // クライアント側で日時範囲をフィルタリング
      final filteredDocs = eventsQuery.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final eventDate = (data['eventDate'] as Timestamp).toDate();
        return eventDate.isAfter(oneHourLater) && eventDate.isBefore(twentyFiveHoursLater);
      }).toList();

      for (final eventDoc in filteredDocs) {
        final event = Event.fromFirestore(eventDoc);
        await _processEventReminders(event, now);
      }

    } catch (e) {
      print('❌ EventReminderService: Error checking reminders: $e');
    }
  }

  /// 特定のイベントのリマインダーを処理
  Future<void> _processEventReminders(Event event, DateTime now) async {
    try {
      final eventDate = event.eventDate;
      final hoursUntilEvent = eventDate.difference(now).inHours;

      // リマインダーを送信すべき時間かチェック
      List<int> reminderHours = [24, 1]; // 24時間前と1時間前

      for (final reminderHour in reminderHours) {
        if (hoursUntilEvent <= reminderHour && hoursUntilEvent > (reminderHour - 1)) {
          await _sendEventReminders(event, reminderHour);
        }
      }

    } catch (e) {
      print('❌ EventReminderService: Error processing event reminders: $e');
    }
  }

  /// イベントの参加者にリマインダーを送信
  Future<void> _sendEventReminders(Event event, int hoursUntilEvent) async {
    try {
      print('🔔 EventReminderService: Sending ${hoursUntilEvent}h reminders for event: ${event.name}');

      // このリマインダーが既に送信済みかチェック
      final reminderKey = '${event.id}_${hoursUntilEvent}h';
      final reminderDoc = await _firestore
          .collection('eventReminders')
          .doc(reminderKey)
          .get();

      if (reminderDoc.exists) {
        print('🔔 EventReminderService: Reminder already sent for $reminderKey');
        return;
      }

      // 参加者リストを取得
      final participants = await _getEventParticipants(event.id);

      if (participants.isEmpty) {
        print('🔔 EventReminderService: No participants for event: ${event.name}');
        return;
      }

      // 各参加者にリマインダー通知を送信
      for (final participantId in participants) {
        try {
          await NotificationService.instance.sendEventReminderNotification(
            toUserId: participantId,
            eventId: event.id,
            eventName: event.name,
            eventDate: event.eventDate,
            hoursUntilEvent: hoursUntilEvent,
          );

          print('✅ EventReminderService: Sent reminder to user: $participantId');
        } catch (e) {
          print('❌ EventReminderService: Failed to send reminder to user $participantId: $e');
        }
      }

      // リマインダー送信記録を保存
      await _firestore.collection('eventReminders').doc(reminderKey).set({
        'eventId': event.id,
        'eventName': event.name,
        'eventDate': event.eventDate,
        'hoursUntilEvent': hoursUntilEvent,
        'sentAt': FieldValue.serverTimestamp(),
        'participantCount': participants.length,
      });

      print('✅ EventReminderService: Reminder batch completed for event: ${event.name}');

    } catch (e) {
      print('❌ EventReminderService: Error sending event reminders: $e');
    }
  }

  /// イベントの参加者IDリストを取得
  Future<List<String>> _getEventParticipants(String eventId) async {
    try {
      // 承認済みの参加申請を取得
      final applicationsQuery = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'approved')
          .get();

      return applicationsQuery.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

    } catch (e) {
      print('❌ EventReminderService: Error getting participants: $e');
      return [];
    }
  }

  /// 手動でリマインダーをトリガー（テスト用）
  Future<void> triggerRemindersForEvent(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        print('❌ EventReminderService: Event not found: $eventId');
        return;
      }

      final event = Event.fromFirestore(eventDoc);
      await _processEventReminders(event, DateTime.now());

    } catch (e) {
      print('❌ EventReminderService: Error triggering manual reminder: $e');
    }
  }

  /// 特定の時間前のリマインダーを手動送信（テスト用）
  Future<void> sendTestReminder(String eventId, int hoursUntilEvent) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        print('❌ EventReminderService: Event not found: $eventId');
        return;
      }

      final event = Event.fromFirestore(eventDoc);
      await _sendEventReminders(event, hoursUntilEvent);

    } catch (e) {
      print('❌ EventReminderService: Error sending test reminder: $e');
    }
  }

  /// リマインダー履歴を取得
  Future<List<Map<String, dynamic>>> getReminderHistory(String eventId) async {
    try {
      final remindersQuery = await _firestore
          .collection('eventReminders')
          .where('eventId', isEqualTo: eventId)
          .orderBy('sentAt', descending: true)
          .get();

      return remindersQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();

    } catch (e) {
      print('❌ EventReminderService: Error getting reminder history: $e');
      return [];
    }
  }

  /// リマインダー設定を取得（将来の拡張用）
  Future<Map<String, dynamic>?> getReminderSettings(String userId) async {
    try {
      final settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('reminders')
          .get();

      return settingsDoc.exists ? settingsDoc.data() : null;
    } catch (e) {
      print('❌ EventReminderService: Error getting reminder settings: $e');
      return null;
    }
  }

  /// リマインダー設定を更新（将来の拡張用）
  Future<void> updateReminderSettings(String userId, {
    bool? enabled,
    List<int>? reminderHours,
    bool? emailNotifications,
    bool? pushNotifications,
  }) async {
    try {
      final settings = <String, dynamic>{};

      if (enabled != null) settings['enabled'] = enabled;
      if (reminderHours != null) settings['reminderHours'] = reminderHours;
      if (emailNotifications != null) settings['emailNotifications'] = emailNotifications;
      if (pushNotifications != null) settings['pushNotifications'] = pushNotifications;

      settings['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('reminders')
          .set(settings, SetOptions(merge: true));

    } catch (e) {
      print('❌ EventReminderService: Error updating reminder settings: $e');
    }
  }
}