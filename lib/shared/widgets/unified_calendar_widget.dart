import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../../l10n/app_localizations.dart';

/// 統一カレンダーウィジェット
/// 参加予定カレンダーと主催イベントカレンダーの共通コンポーネント
class UnifiedCalendarWidget extends StatefulWidget {
  /// カレンダータイトル
  final String title;

  /// イベント取得関数
  final Future<Map<DateTime, List<GameEvent>>> Function() onLoadEvents;

  /// イベントタップ時のコールバック
  final void Function(GameEvent event) onEventTap;

  /// フィルター機能を有効にするか
  final bool showFilters;

  /// 初期フィルター設定
  final Map<String, bool>? initialFilters;

  /// フィルター適用時のコールバック
  final void Function(Map<String, bool> filters)? onFiltersChanged;

  /// イベントステータス色を取得する関数（オプション）
  final Color Function(GameEvent event)? getEventStatusColor;

  /// 日付正規化関数（デフォルトでは時分秒を0にする）
  final DateTime Function(DateTime date)? normalizeDate;

  /// 空状態時のメッセージ
  final String? emptyMessage;

  /// 空状態時のアイコン
  final IconData? emptyIcon;

  /// フィルターキーを表示名に変換する関数（オプション）
  final String Function(BuildContext context, String key)? filterDisplayNameBuilder;

  const UnifiedCalendarWidget({
    super.key,
    required this.title,
    required this.onLoadEvents,
    required this.onEventTap,
    this.showFilters = false,
    this.initialFilters,
    this.onFiltersChanged,
    this.getEventStatusColor,
    this.normalizeDate,
    this.emptyMessage,
    this.emptyIcon,
    this.filterDisplayNameBuilder,
  });

  @override
  State<UnifiedCalendarWidget> createState() => _UnifiedCalendarWidgetState();
}

class _UnifiedCalendarWidgetState extends State<UnifiedCalendarWidget> {
  late final ValueNotifier<List<GameEvent>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<GameEvent>> _events = {};
  bool _isLoading = true;
  bool _isDateSelected = false; // 日付選択状態を管理

  // フィルター設定
  Map<String, bool> _filters = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));

    // 初期フィルター設定
    if (widget.initialFilters != null) {
      _filters = Map.from(widget.initialFilters!);
    }

    _loadEvents();
  }

  @override
  void didUpdateWidget(UnifiedCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // widget.initialFiltersが変更された場合は更新
    if (widget.initialFilters != oldWidget.initialFilters) {
      if (widget.initialFilters != null) {
        _filters = Map.from(widget.initialFilters!);
      }
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  /// イベントを読み込み
  Future<void> _loadEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final events = await widget.onLoadEvents();
      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoading = false;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.eventLoadFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  /// 日付を正規化
  DateTime _normalizeDate(DateTime date) {
    if (widget.normalizeDate != null) {
      return widget.normalizeDate!(date);
    }
    return DateTime(date.year, date.month, date.day);
  }

  /// 指定日のイベントを取得
  List<GameEvent> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // カレンダー部分を独立したカード（アニメーション対応）
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.all(AppDimensions.spacingL),
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
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppDimensions.spacingM),
                    _buildCalendar(),
                  ],
                ),
              ),
              // イベントリスト部分を独立したカードに
              Expanded(child: _buildEventListCard()),
            ],
          );
  }

  /// ヘッダーを構築
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeXL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (widget.showFilters)
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: _showFilterDialog,
          ),
      ],
    );
  }

  /// カレンダーウィジェットを構築
  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(_isDateSelected),
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCalendarHeader(),
            SizedBox(height: _isDateSelected ? AppDimensions.spacingS : AppDimensions.spacingM),
            if (!_isDateSelected) ...[
              // 日付未選択時のみ週ヘッダーとグリッドを表示
              _buildWeekDaysHeader(),
              _buildCalendarGrid(),
            ] else ...[
              // 日付選択時はコンパクト表示
              _buildCompactSelectedDate(),
            ],
          ],
        ),
      ),
    );
  }

  /// 選択された日付のコンパクト表示を構築
  Widget _buildCompactSelectedDate() {
    if (_selectedDay == null) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // メインコンテンツ
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                // 日付アイコン
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.event,
                    color: AppColors.textWhite,
                    size: AppDimensions.iconL,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                // 日付情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectedDateLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        l10n.monthDayFormat(_selectedDay!.month, _selectedDay!.day),
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXL,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        l10n.yearWeekdayFormat(_selectedDay!.year, _getWeekdayName(context, _selectedDay!.weekday)),
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右上の戻るボタン
          Positioned(
            top: AppDimensions.spacingM,
            right: AppDimensions.spacingM,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = null;
                    _isDateSelected = false;
                  });
                  _selectedEvents.value = [];
                },
                icon: Icon(
                  Icons.expand_more,
                  color: AppColors.primary,
                  size: AppDimensions.iconM,
                ),
                tooltip: l10n.backToCalendar,
                padding: const EdgeInsets.all(AppDimensions.spacingS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 曜日名を取得
  String _getWeekdayName(BuildContext context, int weekday) {
    final l10n = L10n.of(context);
    final weekdays = [
      l10n.weekdayMonday,
      l10n.weekdayTuesday,
      l10n.weekdayWednesday,
      l10n.weekdayThursday,
      l10n.weekdayFriday,
      l10n.weekdaySaturday,
      l10n.weekdaySunday,
    ];
    return weekdays[weekday - 1];
  }

  /// 曜日短縮名を取得
  List<String> _getWeekdayShortNames(BuildContext context) {
    final l10n = L10n.of(context);
    return [
      l10n.weekdayShortSun,
      l10n.weekdayShortMon,
      l10n.weekdayShortTue,
      l10n.weekdayShortWed,
      l10n.weekdayShortThu,
      l10n.weekdayShortFri,
      l10n.weekdayShortSat,
    ];
  }

  /// カレンダーヘッダーを構築
  Widget _buildCalendarHeader() {
    final l10n = L10n.of(context);
    // 日付が選択されている場合はヘッダーを非表示または簡素化
    if (_isDateSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              color: AppColors.primary,
              size: AppDimensions.iconS,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              l10n.yearMonthFormat(_focusedDay.year, _focusedDay.month),
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 通常のカレンダーヘッダー
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _previousMonth(),
          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
        ),
        Text(
          l10n.yearMonthFormat(_focusedDay.year, _focusedDay.month),
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
    final weekDays = _getWeekdayShortNames(context);
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
          _isDateSelected = true;
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
                  children: events.take(3).map((event) {
                    Color dotColor = widget.getEventStatusColor != null
                        ? widget.getEventStatusColor!(event)
                        : AppColors.success;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
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

  /// イベントリストカードを構築
  Widget _buildEventListCard() {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        0,
        AppDimensions.spacingL,
        AppDimensions.spacingL,
      ),
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
          // ヘッダー部分
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppColors.accent,
                  size: AppDimensions.iconL,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Text(
                    _selectedDay != null
                        ? l10n.eventsOnDate(_selectedDay!.month, _selectedDay!.day)
                        : l10n.eventsLabel,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // イベントリスト部分
          Expanded(child: _buildScrollableEventList()),
        ],
      ),
    );
  }

  /// スクロール可能なイベントリストを構築
  Widget _buildScrollableEventList() {
    return ValueListenableBuilder<List<GameEvent>>(
      valueListenable: _selectedEvents,
      builder: (context, events, _) {
        final l10n = L10n.of(context);
        if (events.isEmpty) {
          // SingleChildScrollViewでラップしてオーバーフローを防止
          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingXL),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.emptyIcon ?? Icons.event_busy,
                      size: AppDimensions.iconXL,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      widget.emptyMessage ?? l10n.noEventsOnThisDay,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index]);
          },
        );
      },
    );
  }

  /// イベントカードを構築
  Widget _buildEventCard(GameEvent event) {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Material(
        color: AppColors.backgroundTransparent,
        child: InkWell(
          onTap: () => widget.onEventTap(event),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
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
                          if (event.gameName != null || event.gameIconUrl != null) ...[
                            const SizedBox(height: AppDimensions.spacingXS),
                            _buildGameInfo(event),
                          ],
                        ],
                      ),
                    ),
                    _buildStatusBadge(event),
                    const SizedBox(width: AppDimensions.spacingS),
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
                      l10n.participantCountFormat(event.participantCount, event.maxParticipants),
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

  /// ステータスに応じた色を取得
  Color _getStatusColor(GameEventStatus status) {
    switch (status) {
      case GameEventStatus.draft:
        return AppColors.warning;
      case GameEventStatus.published:
        return AppColors.success;
      case GameEventStatus.upcoming:
        return AppColors.info;
      case GameEventStatus.active:
        return AppColors.success;
      case GameEventStatus.completed:
        return AppColors.statusCompleted;
      case GameEventStatus.expired:
        return AppColors.statusExpired;
      case GameEventStatus.cancelled:
        return AppColors.error;
    }
  }

  /// ステータスバッジを構築
  Widget _buildStatusBadge(GameEvent event) {
    final color = _getStatusColor(event.status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        event.status.displayName,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeXS,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ゲーム情報（アイコンとゲーム名）を構築
  Widget _buildGameInfo(GameEvent event) {
    return Row(
      children: [
        if (event.gameIconUrl != null) ...[
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
              color: AppColors.backgroundLight,
              border: Border.all(
                color: AppColors.borderLight,
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
              child: Image.network(
                event.gameIconUrl!,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.backgroundLight,
                    child: const Icon(
                      Icons.videogame_asset,
                      color: AppColors.textSecondary,
                      size: 12,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.backgroundLight,
                    child: const Icon(
                      Icons.videogame_asset,
                      color: AppColors.textLight,
                      size: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
        ],
        if (event.gameName != null) ...[
          Expanded(
            child: Text(
              event.gameName!,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// フィルターダイアログを表示
  void _showFilterDialog() {
    if (!widget.showFilters) return;

    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.displayFilter),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _filters.entries.map((entry) {
                // フィルター表示名を取得（ビルダーがあれば使用、なければキーをそのまま使用）
                final displayName = widget.filterDisplayNameBuilder != null
                    ? widget.filterDisplayNameBuilder!(context, entry.key)
                    : entry.key;
                return CheckboxListTile(
                  title: Text(displayName),
                  value: entry.value,
                  onChanged: (value) {
                    setDialogState(() {
                      _filters[entry.key] = value ?? false;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (widget.onFiltersChanged != null) {
                  widget.onFiltersChanged!(_filters);
                }
                // フィルター適用後の再読み込みは親のonFiltersChangedで処理される
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.apply),
            ),
          ],
        ),
      ),
    );
  }
}