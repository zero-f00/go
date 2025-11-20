import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_gradient_background.dart';
import 'app_header.dart';
import 'event_card.dart';
import 'management_event_card_wrapper.dart';
import '../../features/game_event_management/models/game_event.dart';

/// 汎用的なイベント一覧画面コンポーネント
/// 他の画面でも流用可能な設計
class GenericEventListScreen extends StatefulWidget {
  /// 画面タイトル
  final String title;

  /// 表示するイベントリスト
  final List<GameEvent> events;

  /// 検索機能を有効にするかどうか
  final bool enableSearch;

  /// 空状態のときのタイトルメッセージ
  final String emptyTitle;

  /// 空状態のときの詳細メッセージ
  final String emptyMessage;

  /// 空状態のときのアイコン
  final IconData emptyIcon;

  /// カードタップ時のコールバック
  final Function(GameEvent) onEventTap;

  /// 検索ヒントテキスト
  final String searchHint;

  /// ローディング状態かどうか
  final bool isLoading;

  /// 管理者モード（管理者向け追加情報を表示）
  final bool isManagementMode;

  const GenericEventListScreen({
    super.key,
    required this.title,
    required this.events,
    required this.onEventTap,
    this.enableSearch = true,
    this.emptyTitle = 'イベントがありません',
    this.emptyMessage = 'まだイベントが作成されていません',
    this.emptyIcon = Icons.event_note,
    this.searchHint = 'イベント名で検索...',
    this.isLoading = false,
    this.isManagementMode = false,
  });

  @override
  State<GenericEventListScreen> createState() => _GenericEventListScreenState();
}

class _GenericEventListScreenState extends State<GenericEventListScreen> {
  final _searchController = TextEditingController();
  List<GameEvent> _filteredEvents = [];

  @override
  void initState() {
    super.initState();
    _filteredEvents = widget.events;
    if (widget.enableSearch) {
      _searchController.addListener(_filterEvents);
    }
  }

  @override
  void didUpdateWidget(GenericEventListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events) {
      _filteredEvents = widget.events;
      if (widget.enableSearch && _searchController.text.isNotEmpty) {
        _filterEvents();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEvents = widget.events;
      } else {
        _filteredEvents = widget.events
            .where((event) =>
                event.name.toLowerCase().contains(query) ||
                event.description.toLowerCase().contains(query) ||
                (event.gameName?.toLowerCase().contains(query) ?? false))
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
                title: widget.title,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    children: [
                      if (widget.enableSearch) ...[
                        _buildHeaderSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildSearchSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                      ] else ...[
                        _buildHeaderSection(),
                        const SizedBox(height: AppDimensions.spacingL),
                      ],
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
          hintText: widget.searchHint,
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
    if (widget.isLoading) {
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
          child: widget.isManagementMode
              ? ManagementEventCardWrapper(
                  event: event,
                  onTap: () => widget.onEventTap(event),
                )
              : EventCard(
                  event: event,
                  onTap: () => widget.onEventTap(event),
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
            widget.emptyIcon,
            size: AppDimensions.iconXXXL,
            color: AppColors.overlayMedium,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            widget.emptyTitle,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            widget.emptyMessage,
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
}