import '../../features/game_event_management/models/game_event.dart';

/// イベント表示フィルタリングサービス
class EventFilterService {
  /// NGユーザーのイベントをフィルタリング
  ///
  /// [events] フィルタリング対象のイベントリスト
  /// [currentUserId] 現在のユーザーID
  /// 戻り値：フィルタリング後のイベントリスト
  static List<GameEvent> filterBlockedUserEvents(List<GameEvent> events, String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return events;
    }

    return events.where((event) {
      // ブロックされているユーザーのイベントは除外
      if (event.blockedUsers.contains(currentUserId)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 複数の条件でイベントをフィルタリング
  ///
  /// [events] フィルタリング対象のイベントリスト
  /// [currentUserId] 現在のユーザーID
  /// [excludeSelfEvents] 自分のイベントを除外するかどうか
  /// [excludeExpiredEvents] 期限切れイベントを除外するかどうか
  static List<GameEvent> filterEvents({
    required List<GameEvent> events,
    String? currentUserId,
    bool excludeSelfEvents = false,
    bool excludeExpiredEvents = false,
  }) {
    var filteredEvents = events;

    // NGユーザーのイベントを除外
    filteredEvents = filterBlockedUserEvents(filteredEvents, currentUserId);

    // 自分のイベントを除外
    if (excludeSelfEvents && currentUserId != null) {
      filteredEvents = filteredEvents.where((event) =>
        event.createdBy != currentUserId
      ).toList();
    }

    // 期限切れイベントを除外
    if (excludeExpiredEvents) {
      final now = DateTime.now();
      filteredEvents = filteredEvents.where((event) {
        // 参加申し込み締切が過ぎているイベントは除外
        if (event.registrationDeadline != null && event.registrationDeadline!.isBefore(now)) {
          return false;
        }
        // イベント開始時刻が過ぎているイベントも除外
        if (event.startDate.isBefore(now)) {
          return false;
        }
        return true;
      }).toList();
    }

    return filteredEvents;
  }

  /// 単一イベントがブロックされているかチェック
  ///
  /// [event] チェック対象のイベント
  /// [currentUserId] 現在のユーザーID
  /// 戻り値：ブロックされている場合true
  static bool isEventBlocked(GameEvent event, String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return false;
    }
    return event.blockedUsers.contains(currentUserId);
  }
}