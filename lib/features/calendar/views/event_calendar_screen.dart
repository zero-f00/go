import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/unified_calendar_widget.dart';
import '../../../shared/services/participation_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../event_detail/views/event_detail_screen.dart';

class EventCalendarScreen extends ConsumerStatefulWidget {
  final List<ParticipationApplication> applications;
  /// 埋め込みモード（Scaffold/ヘッダーなしで表示）
  final bool isEmbedded;

  const EventCalendarScreen({
    super.key,
    required this.applications,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends ConsumerState<EventCalendarScreen> {
  /// 参加予定イベントを読み込み
  Future<Map<DateTime, List<GameEvent>>> _loadParticipationEvents() async {
    final events = <DateTime, List<GameEvent>>{};

    for (final application in widget.applications) {
      final event = await _getEventFromApplication(application);
      if (event != null) {
        final date = _normalizeDate(event.startDate);
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(event);
      }
    }

    return events;
  }

  /// 日付を正規化（時分秒を0にする）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }


  /// アプリケーションからGameEventを取得
  Future<GameEvent?> _getEventFromApplication(ParticipationApplication application) async {
    try {
      // まず gameEvents コレクションから取得を試みる
      final gameEventDoc = await FirebaseFirestore.instance
          .collection('gameEvents')
          .doc(application.eventId)
          .get();

      if (gameEventDoc.exists && gameEventDoc.data() != null) {
        final gameEventData = gameEventDoc.data()!;
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInCalendar(gameEventData)) {
          return null;
        }
        return GameEvent.fromFirestore(gameEventData, gameEventDoc.id);
      }

      // 次に events コレクションから取得を試みる
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(application.eventId)
          .get();

      if (eventDoc.exists && eventDoc.data() != null) {
        final eventData = eventDoc.data()!;
        // 下書きや非公開イベントは表示しない
        if (!_isEventVisibleInCalendar(eventData)) {
          return null;
        }
        return _convertEventToGameEvent(eventData, application.eventId);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// カレンダーに表示すべきイベントかどうかを判定
  bool _isEventVisibleInCalendar(Map<String, dynamic> eventData) {
    final status = eventData['status'] as String?;
    final visibility = eventData['visibility'] as String?;

    // 下書き状態のイベントは表示しない
    if (status == 'draft') {
      return false;
    }

    // 非公開イベントは表示しない
    if (visibility == 'private') {
      return false;
    }

    // 公開済みまたは予約公開済みのイベントのみ表示
    return status == 'published' || status == 'scheduled';
  }

  /// EventデータをGameEventに変換
  GameEvent _convertEventToGameEvent(Map<String, dynamic> eventData, String eventId) {
    return GameEvent(
      id: eventId,
      name: eventData['name'] ?? 'イベント',
      subtitle: eventData['subtitle'],
      description: eventData['description'] ?? '',
      type: _mapEventType(eventData['type']),
      status: GameEventStatus.active,
      startDate: (eventData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (eventData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 2)),
      participantCount: (eventData['participantIds'] as List?)?.length ?? 0,
      maxParticipants: eventData['maxParticipants'] ?? 10,
      completionRate: 0.0,
      hasFee: eventData['hasFee'] ?? false,
      rewards: const <String, double>{},
      gameId: eventData['gameId'],
      gameName: eventData['gameName'],
      gameIconUrl: eventData['gameIconUrl'],
      imageUrl: eventData['imageUrl'],
      rules: eventData['rules'],
      registrationDeadline: (eventData['registrationDeadline'] as Timestamp?)?.toDate(),
      prizeContent: eventData['prizeContent'],
      contactInfo: eventData['contactInfo'],
      policy: eventData['policy'],
      additionalInfo: eventData['additionalInfo'],
      streamingUrls: List<String>.from(eventData['streamingUrls'] ?? []),
      minAge: eventData['minAge'],
      feeAmount: eventData['feeAmount']?.toDouble(),
      platforms: List<String>.from(eventData['platforms'] ?? []),
      approvalMethod: eventData['approvalMethod'] ?? 'manual',
      visibility: eventData['visibility'] ?? 'public',
      language: eventData['language'] ?? 'ja',
      hasAgeRestriction: eventData['hasAgeRestriction'] ?? false,
      hasStreaming: eventData['hasStreaming'] ?? false,
      eventTags: List<String>.from(eventData['eventTags'] ?? []),
      sponsors: List<String>.from(eventData['sponsors'] ?? []),
      managers: List<String>.from(eventData['managers'] ?? []),
      createdBy: eventData['createdBy'],
      createdByName: eventData['createdByName'],
    );
  }

  /// イベントタイプのマッピング
  GameEventType _mapEventType(String? eventType) {
    switch (eventType) {
      case 'daily':
        return GameEventType.daily;
      case 'weekly':
        return GameEventType.weekly;
      case 'special':
        return GameEventType.special;
      case 'seasonal':
        return GameEventType.seasonal;
      default:
        return GameEventType.daily;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 埋め込みモードの場合はカレンダーウィジェットのみ返す
    if (widget.isEmbedded) {
      return _buildCalendarContent();
    }

    // 通常モードの場合はScaffold付きで返す
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '参加予定カレンダー',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _buildCalendarContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// カレンダーコンテンツを構築
  Widget _buildCalendarContent() {
    return UnifiedCalendarWidget(
      title: '参加予定カレンダー',
      onLoadEvents: _loadParticipationEvents,
      onEventTap: _showEventDetails,
      normalizeDate: _normalizeDate,
      emptyMessage: 'この日はイベントがありません',
      emptyIcon: Icons.event_busy,
    );
  }


  /// イベント詳細画面を表示
  void _showEventDetails(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

}