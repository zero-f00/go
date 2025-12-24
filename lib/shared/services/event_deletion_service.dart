import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/event_model.dart';
import 'event_service.dart';
import 'image_upload_service.dart';

/// イベント削除可否チェック結果
class EventDeletionCheck {
  final bool canDelete;
  final bool isDraft;
  final int applicationCount;
  final String? reason;

  const EventDeletionCheck({
    required this.canDelete,
    required this.isDraft,
    required this.applicationCount,
    this.reason,
  });
}

/// イベント削除サービス
/// 下書きイベントまたは参加申込者がいない公開イベントの完全削除を担当
class EventDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// イベントが削除可能かチェック
  static Future<EventDeletionCheck> canDeleteEvent(String eventId) async {
    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        return const EventDeletionCheck(
          canDelete: false,
          isDraft: false,
          applicationCount: 0,
          reason: 'イベントが見つかりません',
        );
      }

      // 中止済みイベントは削除不可
      if (event.status == EventStatus.cancelled) {
        return const EventDeletionCheck(
          canDelete: false,
          isDraft: false,
          applicationCount: 0,
          reason: '中止済みのイベントは削除できません',
        );
      }

      // 完了済みイベントは削除不可
      if (event.status == EventStatus.completed) {
        return const EventDeletionCheck(
          canDelete: false,
          isDraft: false,
          applicationCount: 0,
          reason: '完了済みのイベントは削除できません',
        );
      }

      final isDraft = event.status == EventStatus.draft;

      // 下書きイベントは常に削除可能（参加申込は存在しない）
      if (isDraft) {
        return const EventDeletionCheck(
          canDelete: true,
          isDraft: true,
          applicationCount: 0,
        );
      }

      // 公開中イベントの場合、参加申込者数をチェック
      final applicationCount = await _getApplicationCount(eventId);

      if (applicationCount > 0) {
        return EventDeletionCheck(
          canDelete: false,
          isDraft: false,
          applicationCount: applicationCount,
          reason: '参加申込者がいるイベントは削除できません。中止機能をご利用ください。',
        );
      }

      // 参加申込者がいない公開イベントは削除可能
      return const EventDeletionCheck(
        canDelete: true,
        isDraft: false,
        applicationCount: 0,
      );
    } catch (e) {
      return EventDeletionCheck(
        canDelete: false,
        isDraft: false,
        applicationCount: 0,
        reason: '削除可否の確認中にエラーが発生しました: $e',
      );
    }
  }

  /// イベントを削除（関連データも全て削除）
  static Future<bool> deleteEvent(String eventId) async {
    try {
      // 削除可能かチェック
      final check = await canDeleteEvent(eventId);
      if (!check.canDelete) {
        return false;
      }

      // イベント情報を取得（画像削除用）
      final event = await EventService.getEventById(eventId);

      // 関連データを削除（バッチ処理）
      final batch = _firestore.batch();

      // 1. 参加申込を削除（念のため）
      await _deleteEventApplications(eventId, batch);

      // 2. グループ分けデータを削除
      await _deleteEventGroups(eventId, batch);

      // 3. 試合結果を削除
      await _deleteMatchResults(eventId, batch);

      // 4. リマインダーを削除
      await _deleteEventReminders(eventId, batch);

      // 5. イベント本体を削除
      final eventRef = _firestore.collection('events').doc(eventId);
      batch.delete(eventRef);

      // バッチ処理を実行
      await batch.commit();

      // 6. 画像を削除（バッチ外で実行）
      if (event != null && event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        await _deleteEventImage(event.imageUrl!);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 参加申込数を取得
  static Future<int> _getApplicationCount(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// 参加申込を削除
  static Future<void> _deleteEventApplications(String eventId, WriteBatch batch) async {
    try {
      final querySnapshot = await _firestore
          .collection('participationApplications')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }

  /// グループ分けデータを削除
  static Future<void> _deleteEventGroups(String eventId, WriteBatch batch) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_groups')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }

  /// 試合結果を削除
  static Future<void> _deleteMatchResults(String eventId, WriteBatch batch) async {
    try {
      final querySnapshot = await _firestore
          .collection('match_results')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }

  /// リマインダーを削除
  static Future<void> _deleteEventReminders(String eventId, WriteBatch batch) async {
    try {
      final querySnapshot = await _firestore
          .collection('event_reminders')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
    } catch (e) {
      // エラーは無視して続行
    }
  }

  /// イベント画像を削除
  static Future<void> _deleteEventImage(String imageUrl) async {
    try {
      await ImageUploadService.deleteImageFromUrl(imageUrl);
    } catch (e) {
      // 画像削除エラーは無視
    }
  }
}
