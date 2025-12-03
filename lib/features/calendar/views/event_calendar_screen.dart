import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/game_icon.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/game_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../event_detail/views/event_detail_screen.dart';

class EventCalendarScreen extends ConsumerStatefulWidget {
  final List<ParticipationApplication> applications;

  const EventCalendarScreen({
    super.key,
    required this.applications,
  });

  @override
  ConsumerState<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends ConsumerState<EventCalendarScreen> {
  late final ValueNotifier<List<GameEvent>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<GameEvent>> _events = {};
  bool _isLoading = true;
  final Map<String, String?> _gameIconCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  /// イベントを読み込み
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _events = events;
      _isLoading = false;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  /// 日付を正規化（時分秒を0にする）
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 指定日のイベントを取得
  List<GameEvent> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          _buildCalendar(),
                          const SizedBox(height: AppDimensions.spacingL),
                          Expanded(
                            child: _buildEventList(),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// カレンダーウィジェットを構築
  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: AppDimensions.spacingM),
          _buildWeekDaysHeader(),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  /// カレンダーヘッダーを構築
  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _previousMonth(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
        Text(
          '${_focusedDay.year}年${_focusedDay.month}月',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        IconButton(
          onPressed: () => _nextMonth(),
          icon: const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
      ],
    );
  }

  /// 曜日ヘッダーを構築
  Widget _buildWeekDaysHeader() {
    const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      children: weekDays.map((day) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
          child: Text(
            day,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )).toList(),
    );
  }

  /// カレンダーグリッドを構築
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // 日曜日を0にする
    final totalDays = lastDayOfMonth.day;

    final List<Widget> dayWidgets = [];

    // 月の最初の日の前の空白を追加
    for (int i = 0; i < firstDayOfWeek; i++) {
      dayWidgets.add(Container());
    }

    // 月の日付を追加
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      dayWidgets.add(_buildDayCell(date));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }

  /// 日付セルを構築
  Widget _buildDayCell(DateTime date) {
    final events = _getEventsForDay(date);
    final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
    final isToday = _isSameDay(date, DateTime.now());

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
        _selectedEvents.value = events;
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.textWhite
                      : isToday
                          ? AppColors.accent
                          : AppColors.textDark,
                ),
              ),
            ),
            if (events.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 前月に移動
  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  /// 次月に移動
  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  /// 同じ日かどうか判定
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 選択された日のイベントリストを構築
  Widget _buildEventList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: AppColors.accent,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Text(
                _selectedDay != null
                    ? '${_selectedDay!.month}月${_selectedDay!.day}日のイベント'
                    : 'イベント',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Expanded(
            child: ValueListenableBuilder<List<GameEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: AppDimensions.iconXL,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        const Text(
                          'この日はイベントがありません',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(events[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// イベントカードを構築
  Widget _buildEventCard(GameEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: () => _showEventDetails(event),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    FutureBuilder<String?>(
                      future: _getGameIconUrl(event.gameId),
                      builder: (context, snapshot) {
                        return GameIcon(
                          iconUrl: snapshot.data,
                          size: AppDimensions.iconL,
                          gameName: event.gameName,
                        );
                      },
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (event.gameName != null) ...[
                            const SizedBox(height: AppDimensions.spacingXS),
                            Text(
                              event.gameName!,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textLight,
                      size: AppDimensions.iconM,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      '${event.startDate.hour.toString().padLeft(2, '0')}:${event.startDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingL),
                    Icon(
                      Icons.group,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      '${event.participantCount}/${event.maxParticipants}人',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  /// ゲームIDからアイコンURLを取得（キャッシュ付き）
  Future<String?> _getGameIconUrl(String? gameId) async {
    if (gameId == null || gameId.isEmpty) {
      return null;
    }

    // キャッシュから確認
    if (_gameIconCache.containsKey(gameId)) {
      return _gameIconCache[gameId];
    }

    try {
      final game = await GameService.instance.getGameById(gameId);
      final iconUrl = game?.iconUrl;

      // キャッシュに保存
      _gameIconCache[gameId] = iconUrl;
      return iconUrl;
    } catch (e) {
      // エラーの場合はキャッシュにnullを保存
      _gameIconCache[gameId] = null;
      return null;
    }
  }
}