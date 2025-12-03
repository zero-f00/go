import '../../game_event_management/models/game_event.dart';

/// カレンダー用のイベントラッパークラス
class CalendarEvent {
  final GameEvent event;
  final DateTime date;

  const CalendarEvent({
    required this.event,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          event.id == other.event.id &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => event.id.hashCode ^ date.hashCode;

  @override
  String toString() => 'CalendarEvent{event: ${event.name}, date: $date}';
}