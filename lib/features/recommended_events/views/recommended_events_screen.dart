import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/unified_calendar_widget.dart';
import '../../../shared/services/recommendation_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../event_detail/views/event_detail_screen.dart';

/// おすすめイベント画面
/// お気に入りゲームでの絞り込みとカレンダー/リスト表示切り替え機能を提供
class RecommendedEventsScreen extends ConsumerStatefulWidget {
  /// 初期表示するイベントリスト
  final List<GameEvent> initialEvents;

  /// ユーザーのFirebase UID
  final String firebaseUid;

  const RecommendedEventsScreen({
    super.key,
    required this.initialEvents,
    required this.firebaseUid,
  });

  @override
  ConsumerState<RecommendedEventsScreen> createState() =>
      _RecommendedEventsScreenState();
}

class _RecommendedEventsScreenState
    extends ConsumerState<RecommendedEventsScreen> {
  /// 表示モード: true=リスト, false=カレンダー
  bool _isListView = true;

  /// 選択中のゲームID（nullの場合は全て表示）
  String? _selectedGameId;

  /// 全イベントリスト（再取得後のデータ）
  List<GameEvent> _allEvents = [];

  /// フィルタリング後のイベントリスト
  List<GameEvent> _filteredEvents = [];

  /// 検索クエリ
  final _searchController = TextEditingController();

  /// ローディング状態
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _allEvents = widget.initialEvents;
    _filteredEvents = widget.initialEvents;
    _searchController.addListener(_applyFilters);
    // 画面を開いた時に最新データを再取得
    _refreshEvents();
  }

  /// 最新のおすすめイベントを再取得
  Future<void> _refreshEvents() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // RecommendationServiceから最新データを取得
      final stream = RecommendationService.getRecommendedEvents(widget.firebaseUid);
      final events = await stream.first;

      if (mounted) {
        setState(() {
          _allEvents = events;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// フィルターを適用
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // ゲームフィルター
        if (_selectedGameId != null && event.gameId != _selectedGameId) {
          return false;
        }

        // 検索フィルター
        if (query.isNotEmpty) {
          final matchesName = event.name.toLowerCase().contains(query);
          final matchesDescription =
              event.description.toLowerCase().contains(query);
          final matchesGame =
              event.gameName?.toLowerCase().contains(query) ?? false;
          if (!matchesName && !matchesDescription && !matchesGame) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  /// ゲームフィルターを設定
  void _setGameFilter(String? gameId) {
    setState(() {
      _selectedGameId = gameId;
    });
    _applyFilters();
  }

  /// お気に入りゲームリストを取得
  List<_GameFilterItem> _getGameFilterItems() {
    // イベントからユニークなゲーム情報を抽出
    final gameMap = <String, _GameFilterItem>{};

    for (final event in _allEvents) {
      if (event.gameId != null && !gameMap.containsKey(event.gameId)) {
        gameMap[event.gameId!] = _GameFilterItem(
          gameId: event.gameId!,
          gameName: event.gameName ?? '不明なゲーム',
          gameIconUrl: event.gameIconUrl,
          eventCount: 0,
        );
      }
      if (event.gameId != null && gameMap.containsKey(event.gameId)) {
        gameMap[event.gameId!] = gameMap[event.gameId!]!.copyWith(
          eventCount: gameMap[event.gameId!]!.eventCount + 1,
        );
      }
    }

    return gameMap.values.toList()
      ..sort((a, b) => b.eventCount.compareTo(a.eventCount));
  }

  @override
  Widget build(BuildContext context) {
    final gameFilterItems = _getGameFilterItems();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'おすすめイベント',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
                actions: [
                  // 表示切り替えボタン
                  _buildViewToggleButton(),
                ],
              ),
              Expanded(
                child: _isListView
                    ? _buildListView(gameFilterItems)
                    : _buildCalendarView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 表示切り替えボタン
  Widget _buildViewToggleButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(
            icon: Icons.list,
            isSelected: _isListView,
            onTap: () => setState(() => _isListView = true),
            tooltip: 'リスト表示',
          ),
          _buildToggleItem(
            icon: Icons.calendar_month,
            isSelected: !_isListView,
            onTap: () => setState(() => _isListView = false),
            tooltip: 'カレンダー表示',
          ),
        ],
      ),
    );
  }

  /// トグルアイテム
  Widget _buildToggleItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.backgroundWhite
                : AppColors.backgroundTransparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconM,
            color: isSelected ? AppColors.primary : AppColors.textWhite,
          ),
        ),
      ),
    );
  }

  /// リスト表示
  Widget _buildListView(List<_GameFilterItem> gameFilterItems) {
    return Padding(
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
            // ヘッダー
            _buildListHeader(),
            // ゲームフィルターチップ
            if (gameFilterItems.isNotEmpty) _buildGameFilterChips(gameFilterItems),
            // 検索フィールド
            _buildSearchField(),
            // イベントリスト
            Expanded(child: _buildEventList()),
          ],
        ),
      ),
    );
  }

  /// リストヘッダー
  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                'おすすめイベント',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
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
                '${_filteredEvents.length}件のイベント',
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

  /// ゲームフィルターチップ
  Widget _buildGameFilterChips(List<_GameFilterItem> gameFilterItems) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 「すべて」チップ
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingS),
            child: FilterChip(
              label: Text(
                'すべて (${_allEvents.length})',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: _selectedGameId == null
                      ? AppColors.textWhite
                      : AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: _selectedGameId == null,
              onSelected: (_) => _setGameFilter(null),
              backgroundColor: AppColors.backgroundLight,
              selectedColor: AppColors.primary,
              checkmarkColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                side: BorderSide(
                  color: _selectedGameId == null
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            ),
          ),
          // ゲームごとのチップ
          ...gameFilterItems.map((item) => Padding(
                padding: const EdgeInsets.only(right: AppDimensions.spacingS),
                child: FilterChip(
                  avatar: item.gameIconUrl != null
                      ? ClipOval(
                          child: Image.network(
                            item.gameIconUrl!,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.videogame_asset,
                              size: 16,
                            ),
                          ),
                        )
                      : null,
                  label: Text(
                    '${item.gameName} (${item.eventCount})',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: _selectedGameId == item.gameId
                          ? AppColors.textWhite
                          : AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: _selectedGameId == item.gameId,
                  onSelected: (_) => _setGameFilter(
                    _selectedGameId == item.gameId ? null : item.gameId,
                  ),
                  backgroundColor: AppColors.backgroundLight,
                  selectedColor: AppColors.primary,
                  checkmarkColor: AppColors.textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    side: BorderSide(
                      color: _selectedGameId == item.gameId
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 検索フィールド
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'イベント名やゲーム名で検索...',
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
          setState(() {});
        },
      ),
    );
  }

  /// イベントリスト
  Widget _buildEventList() {
    // ローディング中
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingXL),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
        itemCount: _filteredEvents.length,
        itemBuilder: (context, index) {
          final event = _filteredEvents[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            child: EventCard(
              event: event,
              onTap: () => _navigateToEventDetail(event),
            ),
          );
        },
      ),
    );
  }

  /// 空状態
  Widget _buildEmptyState() {
    final hasFilter = _selectedGameId != null || _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.filter_list_off : Icons.recommend,
              size: AppDimensions.iconXXXL,
              color: AppColors.overlayMedium,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              hasFilter ? '条件に一致するイベントがありません' : 'おすすめイベントがありません',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              hasFilter
                  ? 'フィルターを変更してみてください'
                  : 'お気に入りのゲームを登録すると\n関連するイベントが表示されます',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: AppDimensions.spacingL),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _setGameFilter(null);
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('フィルターをクリア'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// カレンダー表示
  Widget _buildCalendarView() {
    return UnifiedCalendarWidget(
      title: 'おすすめイベント',
      onLoadEvents: _loadEventsForCalendar,
      onEventTap: _navigateToEventDetail,
      emptyMessage: 'この日はおすすめイベントがありません',
      emptyIcon: Icons.recommend,
      getEventStatusColor: (event) {
        switch (event.status) {
          case GameEventStatus.upcoming:
            return AppColors.info;
          case GameEventStatus.active:
            return AppColors.success;
          case GameEventStatus.published:
            return AppColors.success;
          default:
            return AppColors.textSecondary;
        }
      },
    );
  }

  /// カレンダー用イベントデータを読み込み
  Future<Map<DateTime, List<GameEvent>>> _loadEventsForCalendar() async {
    final eventMap = <DateTime, List<GameEvent>>{};

    // フィルターが適用されたイベントを使用
    final eventsToShow =
        _selectedGameId != null
            ? _allEvents
                .where((e) => e.gameId == _selectedGameId)
                .toList()
            : _allEvents;

    for (final event in eventsToShow) {
      final date = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      if (!eventMap.containsKey(date)) {
        eventMap[date] = [];
      }
      eventMap[date]!.add(event);
    }

    return eventMap;
  }

  /// イベント詳細画面へ遷移
  void _navigateToEventDetail(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }
}

/// ゲームフィルター用のデータクラス
class _GameFilterItem {
  final String gameId;
  final String gameName;
  final String? gameIconUrl;
  final int eventCount;

  const _GameFilterItem({
    required this.gameId,
    required this.gameName,
    this.gameIconUrl,
    required this.eventCount,
  });

  _GameFilterItem copyWith({
    String? gameId,
    String? gameName,
    String? gameIconUrl,
    int? eventCount,
  }) {
    return _GameFilterItem(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      gameIconUrl: gameIconUrl ?? this.gameIconUrl,
      eventCount: eventCount ?? this.eventCount,
    );
  }
}
