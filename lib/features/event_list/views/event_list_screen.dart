import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/event_management_types.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_card.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../game_event_management/models/game_event.dart';

class EventListScreen extends StatefulWidget {
  final EventManagementType eventType;
  final List<GameEvent>? events;

  const EventListScreen({
    super.key,
    required this.eventType,
    this.events,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final _searchController = TextEditingController();
  List<GameEvent> _filteredEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    setState(() {
      _isLoading = true;
    });

    // TODO: 実際のデータ取得処理を実装
    // 現在はモックデータまたは渡されたeventsを使用
    _filteredEvents = widget.events ?? _getMockEvents();

    setState(() {
      _isLoading = false;
    });
  }

  List<GameEvent> _getMockEvents() {
    // モックデータ - 実装時は削除
    switch (widget.eventType) {
      case EventManagementType.createdEvents:
        return _getCreatedEventsMock();
      case EventManagementType.collaborativeEvents:
        return _getCollaborativeEventsMock();
      case EventManagementType.draftEvents:
        return _getDraftEventsMock();
      case EventManagementType.pastEvents:
        return _getPastEventsMock();
    }
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = widget.events ?? _getMockEvents();
      } else {
        _filteredEvents = (widget.events ?? _getMockEvents())
            .where((event) =>
                event.name.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query))
            .toList();
      }
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
                title: widget.eventType.title,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildSearchSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                      Expanded(child: _buildEventList()),
                    ],
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
    return Container(
      width: double.infinity,
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
          Text(
            widget.eventType.description,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.accent,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
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

  Widget _buildSearchSection() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'イベント名で検索...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
        ),
        style: const TextStyle(
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accent,
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: EventCard(
            event: event,
            onTap: () => _showEventDetails(event),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: AppDimensions.iconXXXL,
            color: AppColors.overlayMedium,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            widget.eventType.emptyMessage,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            widget.eventType.emptyDetailMessage,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEventDetails(GameEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );
  }

  // モックデータ生成メソッド（実装時は削除）
  List<GameEvent> _getCreatedEventsMock() {
    return [
      GameEvent(
        id: 'created_1',
        name: '新春ログインボーナス',
        description: '新年を祝う特別なログインボーナスイベント',
        type: GameEventType.seasonal,
        status: GameEventStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        participantCount: 1247,
        maxParticipants: 2000,
        completionRate: 0.85,
        hasFee: false,
        rewards: const {'coin': 500, 'gem': 50},
        gameId: 'game_1',
        gameName: 'パズル＆ドラゴンズ',
        gameIconUrl: null,
      ),
      GameEvent(
        id: 'created_2',
        name: 'ウィークリーチャレンジ',
        description: '毎週更新される挑戦的なミッション',
        type: GameEventType.weekly,
        status: GameEventStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 6)),
        participantCount: 892,
        maxParticipants: 1000,
        completionRate: 0.72,
        hasFee: false,
        rewards: const {'exp': 1000, 'coin': 200},
        gameId: 'game_2',
        gameName: 'モンスターストライク',
        gameIconUrl: null,
      ),
    ];
  }

  List<GameEvent> _getCollaborativeEventsMock() {
    return [
      GameEvent(
        id: 'collab_1',
        name: 'レイドボス討伐戦',
        description: 'ギルドメンバーと協力して強敵を倒そう',
        type: GameEventType.special,
        status: GameEventStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 4)),
        participantCount: 645,
        maxParticipants: 1000,
        completionRate: 0.58,
        hasFee: true,
        rewards: const {'rare_item': 1, 'coin': 1000},
        isPremium: true,
        gameId: 'game_3',
        gameName: 'Fate/Grand Order',
        gameIconUrl: null,
      ),
    ];
  }

  List<GameEvent> _getDraftEventsMock() {
    return [
      GameEvent(
        id: 'draft_1',
        name: 'サマーフェスティバル（下書き）',
        description: '夏の特別イベント企画中',
        type: GameEventType.seasonal,
        status: GameEventStatus.upcoming,
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        participantCount: 0,
        maxParticipants: 500,
        completionRate: 0.0,
        hasFee: false,
        rewards: const {'special_character': 1},
        gameId: 'game_4',
        gameName: 'ドラゴンクエストウォーク',
      ),
    ];
  }

  List<GameEvent> _getPastEventsMock() {
    return [
      GameEvent(
        id: 'past_1',
        name: '年末感謝祭',
        description: '2023年の感謝を込めた特別イベント',
        type: GameEventType.seasonal,
        status: GameEventStatus.completed,
        startDate: DateTime.now().subtract(const Duration(days: 45)),
        endDate: DateTime.now().subtract(const Duration(days: 30)),
        participantCount: 2341,
        maxParticipants: 3000,
        completionRate: 0.94,
        hasFee: true,
        rewards: const {'gem': 100, 'coin': 2000},
        isPremium: true,
        gameId: 'game_5',
        gameName: 'ポケモン GO',
        gameIconUrl: null,
      ),
    ];
  }
}