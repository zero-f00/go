import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_gradient_background.dart';
import 'app_header.dart';
import 'event_card.dart';
import 'management_event_card_wrapper.dart';
import '../../features/game_event_management/models/game_event.dart';

/// 過去イベント履歴の表示フィルタ
enum PastEventFilter {
  all,       // 全て
  completed, // 完了のみ
  cancelled, // キャンセルのみ
}

/// 過去イベント履歴のソート方法
enum PastEventSort {
  dateNewest,    // 開催日（新しい順）
  dateOldest,    // 開催日（古い順）
  participantsDesc, // 参加者数（降順）
  participantsAsc,  // 参加者数（昇順）
}

/// 過去イベント履歴の表示期間
enum PastEventPeriod {
  month,      // 最近1ヶ月
  threeMonth, // 最近3ヶ月
  sixMonth,   // 最近6ヶ月
  year,       // 最近1年
  all,        // 全期間
}

/// 表示モード
enum ViewMode {
  list,    // リスト表示
  compact, // コンパクト表示
}

extension PastEventFilterExtension on PastEventFilter {
  String get displayName {
    switch (this) {
      case PastEventFilter.all:
        return '全て';
      case PastEventFilter.completed:
        return '完了済み';
      case PastEventFilter.cancelled:
        return 'キャンセル';
    }
  }

  IconData get icon {
    switch (this) {
      case PastEventFilter.all:
        return Icons.all_inclusive;
      case PastEventFilter.completed:
        return Icons.check_circle;
      case PastEventFilter.cancelled:
        return Icons.cancel;
    }
  }
}

extension PastEventSortExtension on PastEventSort {
  String get displayName {
    switch (this) {
      case PastEventSort.dateNewest:
        return '開催日（新しい順）';
      case PastEventSort.dateOldest:
        return '開催日（古い順）';
      case PastEventSort.participantsDesc:
        return '参加者数（多い順）';
      case PastEventSort.participantsAsc:
        return '参加者数（少ない順）';
    }
  }
}

extension PastEventPeriodExtension on PastEventPeriod {
  String get displayName {
    switch (this) {
      case PastEventPeriod.month:
        return '最近1ヶ月';
      case PastEventPeriod.threeMonth:
        return '最近3ヶ月';
      case PastEventPeriod.sixMonth:
        return '最近6ヶ月';
      case PastEventPeriod.year:
        return '最近1年';
      case PastEventPeriod.all:
        return '全期間';
    }
  }

  DateTime? get cutoffDate {
    final now = DateTime.now();
    switch (this) {
      case PastEventPeriod.month:
        return now.subtract(const Duration(days: 30));
      case PastEventPeriod.threeMonth:
        return now.subtract(const Duration(days: 90));
      case PastEventPeriod.sixMonth:
        return now.subtract(const Duration(days: 180));
      case PastEventPeriod.year:
        return now.subtract(const Duration(days: 365));
      case PastEventPeriod.all:
        return null;
    }
  }
}

/// 改善された過去イベント履歴画面
class EnhancedPastEventsScreen extends ConsumerStatefulWidget {
  /// 表示するイベントリスト
  final List<GameEvent> events;

  /// カードタップ時のコールバック
  final Function(GameEvent) onEventTap;

  /// 管理者モード
  final bool isManagementMode;

  /// ローディング状態
  final bool isLoading;

  const EnhancedPastEventsScreen({
    super.key,
    required this.events,
    required this.onEventTap,
    this.isManagementMode = false,
    this.isLoading = false,
  });

  @override
  ConsumerState<EnhancedPastEventsScreen> createState() => _EnhancedPastEventsScreenState();
}

class _EnhancedPastEventsScreenState extends ConsumerState<EnhancedPastEventsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // フィルタ・ソート状態
  PastEventFilter _selectedFilter = PastEventFilter.all;
  PastEventSort _selectedSort = PastEventSort.dateNewest;
  PastEventPeriod _selectedPeriod = PastEventPeriod.all;
  ViewMode _viewMode = ViewMode.list;
  String? _selectedGame;

  // ページネーション
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  List<GameEvent> _filteredEvents = [];
  List<GameEvent> _displayedEvents = [];
  List<String> _availableGames = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void didUpdateWidget(EnhancedPastEventsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _initializeData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 検索クエリを正規化する（全角半角統一、小文字変換など）
  String _normalizeSearchQuery(String text) {
    return text
        .toLowerCase()
        .replaceAll('　', ' ') // 全角スペースを半角スペースに変換
        .replaceAllMapped(RegExp(r'[Ａ-Ｚａ-ｚ０-９]'), (match) {
          // 全角英数字を半角に変換
          final char = match.group(0)!;
          final code = char.codeUnitAt(0);
          if (code >= 0xFF10 && code <= 0xFF19) {
            // 全角数字 (０-９) を半角数字 (0-9) に変換
            return String.fromCharCode(code - 0xFF10 + 0x30);
          } else if (code >= 0xFF21 && code <= 0xFF3A) {
            // 全角大文字 (Ａ-Ｚ) を半角小文字 (a-z) に変換
            return String.fromCharCode(code - 0xFF21 + 0x61);
          } else if (code >= 0xFF41 && code <= 0xFF5A) {
            // 全角小文字 (ａ-ｚ) を半角小文字 (a-z) に変換
            return String.fromCharCode(code - 0xFF41 + 0x61);
          }
          return char;
        })
        .trim();
  }

  void _initializeData() {
    _availableGames = _extractAvailableGames();
    _applyFilters();
  }

  List<String> _extractAvailableGames() {
    final games = widget.events
        .where((event) => event.gameName != null && event.gameName!.isNotEmpty)
        .map((event) => event.gameName!)
        .toSet()
        .toList();
    games.sort();
    return games;
  }

  void _applyFilters() {
    final query = _normalizeSearchQuery(_searchController.text);
    List<GameEvent> filtered = widget.events;

    // ステータスフィルタ
    if (_selectedFilter != PastEventFilter.all) {
      filtered = filtered.where((event) {
        switch (_selectedFilter) {
          case PastEventFilter.completed:
            return event.status == GameEventStatus.completed;
          case PastEventFilter.cancelled:
            return event.status == GameEventStatus.cancelled;
          case PastEventFilter.all:
            return true;
        }
      }).toList();
    }

    // 期間フィルタ
    if (_selectedPeriod != PastEventPeriod.all) {
      final cutoff = _selectedPeriod.cutoffDate;
      if (cutoff != null) {
        filtered = filtered.where((event) => event.startDate.isAfter(cutoff)).toList();
      }
    }

    // ゲームフィルタ
    if (_selectedGame != null) {
      filtered = filtered.where((event) => event.gameName == _selectedGame).toList();
    }

    // 検索フィルタ
    if (query.isNotEmpty) {
      filtered = filtered.where((event) {
        // イベント名での検索
        if (_normalizeSearchQuery(event.name).contains(query)) return true;

        // 説明文での検索
        if (_normalizeSearchQuery(event.description).contains(query)) return true;

        // ゲーム名での検索
        if (event.gameName != null && _normalizeSearchQuery(event.gameName!).contains(query)) return true;

        // 主催者名での検索（もし利用可能なら）
        if (event.createdByName != null && _normalizeSearchQuery(event.createdByName!).contains(query)) return true;

        // イベントタグでの検索
        if (event.eventTags.any((tag) => _normalizeSearchQuery(tag).contains(query))) return true;

        // サブタイトルでの検索
        if (event.subtitle != null && _normalizeSearchQuery(event.subtitle!).contains(query)) return true;

        return false;
      }).toList();
    }

    // ソート
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case PastEventSort.dateNewest:
          return b.startDate.compareTo(a.startDate);
        case PastEventSort.dateOldest:
          return a.startDate.compareTo(b.startDate);
        case PastEventSort.participantsDesc:
          return b.participantCount.compareTo(a.participantCount);
        case PastEventSort.participantsAsc:
          return a.participantCount.compareTo(b.participantCount);
      }
    });

    setState(() {
      _filteredEvents = filtered;
      _currentPage = 1;
      _updateDisplayedEvents();
    });
  }

  void _updateDisplayedEvents() {
    final endIndex = _currentPage * _pageSize;
    _displayedEvents = _filteredEvents.take(endIndex).toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _displayedEvents.length < _filteredEvents.length) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // 遅延を追加してローディング状態を表示
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentPage++;
      _updateDisplayedEvents();
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '過去のイベント履歴',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Container(
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
                        _buildHeaderSection(),
                        _buildFilterSection(),
                        _buildSearchSection(),
                        Expanded(child: _buildEventList()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '過去のイベント履歴',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              _buildViewModeToggle(),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.accent,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                '${_filteredEvents.length}件のイベント（全${widget.events.length}件中）',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.view_list,
            isSelected: _viewMode == ViewMode.list,
            onTap: () => setState(() => _viewMode = ViewMode.list),
          ),
          _buildToggleButton(
            icon: Icons.view_compact,
            isSelected: _viewMode == ViewMode.compact,
            onTap: () => setState(() => _viewMode = ViewMode.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Icon(
          icon,
          size: AppDimensions.iconS,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFilterDropdown<PastEventFilter>(
                label: 'ステータス',
                value: _selectedFilter,
                items: PastEventFilter.values,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value ?? PastEventFilter.all;
                  });
                  _applyFilters();
                },
                itemBuilder: (filter) => Row(
                  children: [
                    Icon(filter.icon, size: AppDimensions.iconS),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(filter.displayName),
                  ],
                ),
              )),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: _buildFilterDropdown<PastEventPeriod>(
                label: '期間',
                value: _selectedPeriod,
                items: PastEventPeriod.values,
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value ?? PastEventPeriod.all;
                  });
                  _applyFilters();
                },
                itemBuilder: (period) => Text(period.displayName),
              )),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(child: _buildGameFilter()),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: _buildSortDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: onChanged,
            items: items.map((item) => DropdownMenuItem<T>(
              value: item,
              child: itemBuilder(item),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGameFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ゲーム',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<String?>(
            value: _selectedGame,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('全てのゲーム'),
            onChanged: (value) {
              setState(() {
                _selectedGame = value;
              });
              _applyFilters();
            },
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('全てのゲーム'),
              ),
              ..._availableGames.map((game) => DropdownMenuItem<String?>(
                value: game,
                child: Text(game),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ソート',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButton<PastEventSort>(
            value: _selectedSort,
            isExpanded: true,
            underline: const SizedBox(),
            onChanged: (value) {
              setState(() {
                _selectedSort = value ?? PastEventSort.dateNewest;
              });
              _applyFilters();
            },
            items: PastEventSort.values.map((sort) => DropdownMenuItem<PastEventSort>(
              value: sort,
              child: Text(sort.displayName),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'イベント名、説明、ゲーム名で検索...',
          hintStyle: const TextStyle(
            color: AppColors.textLight,
            fontSize: AppDimensions.fontSizeM,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: AppDimensions.iconM,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconM,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    // Clear操作後にUIを更新
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
        ),
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
        ),
        onChanged: (value) {
          // Note: _applyFilters is called automatically through addListener
          // This setState is only for UI updates (clear button visibility)
          setState(() {});
        },
      ),
    );
  }

  Widget _buildEventList() {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingXL),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(
          top: AppDimensions.spacingS,
          bottom: AppDimensions.spacingL,
        ),
        itemCount: _displayedEvents.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _displayedEvents.length) {
            return const Padding(
              padding: EdgeInsets.all(AppDimensions.spacingL),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              ),
            );
          }

          final event = _displayedEvents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: _viewMode == ViewMode.compact
                ? _buildCompactEventCard(event)
                : (widget.isManagementMode
                    ? ManagementEventCardWrapper(
                        event: event,
                        onTap: () => widget.onEventTap(event),
                      )
                    : EventCard(
                        event: event,
                        onTap: () => widget.onEventTap(event),
                      )),
          );
        },
      ),
    );
  }

  Widget _buildCompactEventCard(GameEvent event) {
    final statusColor = event.status == GameEventStatus.completed
        ? AppColors.success
        : AppColors.warning;
    final statusText = event.status == GameEventStatus.completed
        ? '完了'
        : 'キャンセル';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => widget.onEventTap(event),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Row(
                    children: [
                      if (event.gameName != null) ...[
                        Icon(
                          Icons.games,
                          size: AppDimensions.iconXS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          event.gameName!,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                      ],
                      Icon(
                        Icons.people,
                        size: AppDimensions.iconXS,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      Text(
                        '${event.participantCount}人',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${event.startDate.month}/${event.startDate.day}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Icon(
              Icons.arrow_forward_ios,
              size: AppDimensions.iconS,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String message;
    IconData icon;

    if (_searchController.text.isNotEmpty) {
      title = '検索結果がありません';
      message = '条件を変更して再度検索してください';
      icon = Icons.search_off;
    } else {
      title = '過去のイベントがありません';
      message = 'まだ完了したイベントがありません';
      icon = Icons.history;
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingXL),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}