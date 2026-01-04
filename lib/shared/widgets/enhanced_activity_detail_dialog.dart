import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../../features/game_event_management/models/game_event.dart';
import '../../l10n/app_localizations.dart';
import 'app_gradient_background.dart';
import 'app_header.dart';

// ApplicationStatusをParticipationStatusのエイリアスとして定義
typedef ApplicationStatus = ParticipationStatus;

/// 参加履歴の期間フィルタ
enum HistoryPeriod {
  all,
  thisMonth,
  lastThreeMonths,
  lastSixMonths,
  thisYear;

  String getDisplayName(L10n l10n) {
    switch (this) {
      case HistoryPeriod.all:
        return l10n.historyPeriodAll;
      case HistoryPeriod.thisMonth:
        return l10n.historyPeriodThisMonth;
      case HistoryPeriod.lastThreeMonths:
        return l10n.historyPeriodLastThreeMonths;
      case HistoryPeriod.lastSixMonths:
        return l10n.historyPeriodLastSixMonths;
      case HistoryPeriod.thisYear:
        return l10n.historyPeriodThisYear;
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case HistoryPeriod.all:
        return null;
      case HistoryPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case HistoryPeriod.lastThreeMonths:
        return DateTime(now.year, now.month - 3, 1);
      case HistoryPeriod.lastSixMonths:
        return DateTime(now.year, now.month - 6, 1);
      case HistoryPeriod.thisYear:
        return DateTime(now.year, 1, 1);
    }
  }
}

class EnhancedActivityDetailDialog extends StatefulWidget {
  final String title;
  final String activityType;
  final String userId;

  const EnhancedActivityDetailDialog({
    super.key,
    required this.title,
    required this.activityType,
    required this.userId,
  });

  @override
  State<EnhancedActivityDetailDialog> createState() =>
      _EnhancedActivityDetailDialogState();
}

class _EnhancedActivityDetailDialogState
    extends State<EnhancedActivityDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  HistoryPeriod _selectedPeriod = HistoryPeriod.all;
  bool _isSearching = false;
  String _searchQuery = '';

  // ページネーション
  static const int _pageSize = 20;
  List<ParticipationApplication> _allApplications = [];
  List<ParticipationApplication> _displayedApplications = [];
  bool _isLoadingMore = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _filterApplications();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    if (widget.activityType == 'total') {
      return 3; // 全て、承認済み、拒否
    }
    return 1;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _displayedApplications.length < _allApplications.length) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;

      final endIndex = _currentPage * _pageSize;
      _displayedApplications = _allApplications.take(endIndex).toList();
      _isLoadingMore = false;
    });
  }

  void _filterApplications() {
    // ビルド中のsetStateを避けるため
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _currentPage = 1;

        List<ParticipationApplication> filtered = _allApplications;

        // 期間フィルタ
        if (_selectedPeriod.startDate != null) {
          filtered = filtered
              .where((app) => app.appliedAt.isAfter(_selectedPeriod.startDate!))
              .toList();
        }

        // 検索フィルタ（イベント名で検索）
        // TODO: イベント名での検索実装（現在はeventIdしか持っていないため）

        _displayedApplications = filtered.take(_pageSize).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: widget.title,
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                  actions: [
                    if (widget.activityType == 'total')
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: AppColors.textDark,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                  ],
                ),
                if (_buildHeaderContent() != null) _buildHeaderContent()!,
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHeaderContent() {
    if (!_isSearching && widget.activityType != 'total') {
      return null;
    }

    final l10n = L10n.of(context);
    List<Widget> children = [];

    // 検索バー
    if (_isSearching) {
      children.add(
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.searchByEventNameHint,
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppDimensions.fontSizeM,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingL,
                  vertical: AppDimensions.spacingM,
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
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    // タブバー（参加履歴の場合）
    if (widget.activityType == 'total') {
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.normal,
            ),
            tabs: [
              Tab(text: l10n.tabAll),
              Tab(text: l10n.tabApproved),
              Tab(text: l10n.tabRejected),
            ],
          ),
        ),
      );
    }

    if (children.isEmpty) return null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildBody() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: widget.activityType == 'total'
            ? Column(
                children: [
                  _buildPeriodFilter(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFilteredContent(null), // 全て
                        _buildFilteredContent(
                          ParticipationStatus.approved,
                        ), // 承認済み
                        _buildFilteredContent(
                          ParticipationStatus.rejected,
                        ), // 拒否
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  if (widget.activityType == 'participating')
                    _buildPeriodFilter(),
                  Expanded(child: _buildActivityContent(widget.activityType)),
                ],
              ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingM,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: HistoryPeriod.values.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppDimensions.spacingS),
          itemBuilder: (context, index) {
            final l10n = L10n.of(context);
            final period = HistoryPeriod.values[index];
            final isSelected = period == _selectedPeriod;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _filterApplications();
                  }
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingL,
                    vertical: AppDimensions.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      period.getDisplayName(l10n),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilteredContent(ParticipationStatus? statusFilter) {
    final l10n = L10n.of(context);
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(l10n.noParticipationHistory);
        }

        // データを初期化（setStateを避けるため、ここで直接処理）
        List<ParticipationApplication> allApps = List.from(snapshot.data!);

        // statusFilterでフィルタリング
        if (statusFilter != null) {
          allApps = allApps.where((app) => app.status == statusFilter).toList();
        }

        // 日付でソート（新しい順）
        allApps.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        // 期間フィルタ適用
        List<ParticipationApplication> filtered = allApps;
        if (_selectedPeriod.startDate != null) {
          filtered = filtered
              .where((app) => app.appliedAt.isAfter(_selectedPeriod.startDate!))
              .toList();
        }

        // 検索フィルタ（将来の実装用）
        if (_searchQuery.isNotEmpty) {
          // TODO: イベント名での検索実装
        }

        // 初回の場合のみデータを設定
        if (_allApplications.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _allApplications = allApps;
                _displayedApplications = filtered.take(_pageSize).toList();
              });
            }
          });
        }

        // フィルタされたデータを表示用に使用
        final displayApps = filtered.take(_pageSize).toList();

        if (displayApps.isEmpty) {
          return _buildEmptyState(l10n.noMatchingHistory);
        }

        return _buildGroupedList(displayApps);
      },
    );
  }

  Widget _buildGroupedList(List<ParticipationApplication> applications) {
    // 月別にグループ化
    Map<String, List<ParticipationApplication>> groupedByMonth = {};

    for (var app in applications) {
      final monthKey = '${app.appliedAt.year}年${app.appliedAt.month}月';
      groupedByMonth[monthKey] ??= [];
      groupedByMonth[monthKey]!.add(app);
    }

    final sortedMonths = groupedByMonth.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 新しい月順

    return ListView.builder(
      controller: _scrollController,
      itemCount: sortedMonths.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= sortedMonths.length) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.spacingL),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final month = sortedMonths[index];
        final monthApplications = groupedByMonth[month]!;

        return _buildMonthSection(month, monthApplications);
      },
    );
  }

  Widget _buildMonthSection(
    String month,
    List<ParticipationApplication> applications,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
          color: AppColors.backgroundLight,
          child: Text(
            month,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        ...applications.map((app) => _buildApplicationTile(context, app)),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityContent(String type) {
    final l10n = L10n.of(context);
    switch (type) {
      case 'pending':
        return _buildPendingApplications();
      case 'participating':
        return _buildParticipatingEvents();
      case 'hosting':
        return _buildHostingEvents();
      default:
        return _buildEmptyState(l10n.noDataAvailable);
    }
  }

  Widget _buildPendingApplications() {
    final l10n = L10n.of(context);
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(l10n.noPendingApplications);
        }

        final pendingApps = snapshot.data!
            .where((app) => app.status == ParticipationStatus.pending)
            .toList();

        if (pendingApps.isEmpty) {
          return _buildEmptyState(l10n.noPendingApproval);
        }

        return ListView.separated(
          itemCount: pendingApps.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final app = pendingApps[index];
            return _buildApplicationTile(context, app);
          },
        );
      },
    );
  }

  Widget _buildParticipatingEvents() {
    final l10n = L10n.of(context);
    return FutureBuilder<List<ParticipationApplication>>(
      future: ParticipationService.getUserApplications(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(l10n.noParticipatingEvents);
        }

        final now = DateTime.now();
        List<ParticipationApplication> filtered = snapshot.data!
            .where((app) => app.status == ParticipationStatus.approved)
            .toList();

        // 期間フィルタ適用
        if (_selectedPeriod.startDate != null) {
          filtered = filtered
              .where((app) => app.appliedAt.isAfter(_selectedPeriod.startDate!))
              .toList();
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(l10n.noEventsThisPeriod);
        }

        return _buildGroupedList(filtered);
      },
    );
  }

  Widget _buildHostingEvents() {
    final l10n = L10n.of(context);
    return FutureBuilder<String?>(
      future: _getFirebaseUidFromCustomId(widget.userId),
      builder: (context, uidSnapshot) {
        if (uidSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final firebaseUid = uidSnapshot.data;
        if (firebaseUid == null) {
          return _buildEmptyState(l10n.userInfoNotAvailable);
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _getManagedEventDocs(firebaseUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(l10n.noHostingEvents);
            }

            final docs = snapshot.data!;

            // イベントを月別にグループ化
            Map<String, List<DocumentSnapshot>> groupedByMonth = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final date = data['updatedAt'] != null
                  ? (data['updatedAt'] as Timestamp).toDate()
                  : DateTime.now();
              final monthKey = '${date.year}年${date.month}月';
              groupedByMonth[monthKey] ??= [];
              groupedByMonth[monthKey]!.add(doc);
            }

            final sortedMonths = groupedByMonth.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              itemCount: sortedMonths.length,
              itemBuilder: (context, index) {
                final month = sortedMonths[index];
                final monthDocs = groupedByMonth[month]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingL,
                        vertical: AppDimensions.spacingM,
                      ),
                      color: AppColors.backgroundLight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            month,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXS,
                              ),
                            ),
                            child: Text(
                              l10n.countItems(monthDocs.length),
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeXS,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...monthDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // ステータスを適切に取得
                      GameEventStatus eventStatus;
                      try {
                        if (data['status'] is String) {
                          eventStatus = _parseEventStatus(data['status']);
                        } else {
                          // 日付から判定
                          final now = DateTime.now();
                          final eventDate = data['eventDate'] != null
                              ? (data['eventDate'] as Timestamp).toDate()
                              : null;
                          final endDate = data['endDate'] != null
                              ? (data['endDate'] as Timestamp).toDate()
                              : null;

                          // status がEventStatus enumの場合の処理
                          if (data['status'] != null &&
                              data['status'].toString() ==
                                  'EventStatus.cancelled') {
                            eventStatus = GameEventStatus.cancelled;
                          } else if (endDate != null && endDate.isBefore(now)) {
                            eventStatus = GameEventStatus.completed;
                          } else if (eventDate != null &&
                              eventDate.isAfter(now)) {
                            eventStatus = GameEventStatus.upcoming;
                          } else {
                            eventStatus = GameEventStatus.active;
                          }
                        }
                      } catch (e) {
                        // エラーが発生した場合はデフォルトステータス
                        eventStatus = GameEventStatus.upcoming;
                      }

                      final event = GameEvent(
                        id: doc.id,
                        name: data['name'] ?? 'イベント',
                        description: data['description'] ?? '',
                        type: GameEventType.daily,
                        status: eventStatus,
                        startDate: data['eventDate'] != null
                            ? (data['eventDate'] as Timestamp).toDate()
                            : DateTime.now(),
                        endDate: data['endDate'] != null
                            ? (data['endDate'] as Timestamp).toDate()
                            : DateTime.now(),
                        participantCount: data['currentParticipants'] ?? 0,
                        maxParticipants: data['maxParticipants'] ?? 0,
                        completionRate: 0.0,
                      );
                      return _buildEventTile(context, event);
                    }),
                    const Divider(height: 1),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildApplicationTile(
    BuildContext context,
    ParticipationApplication app,
  ) {
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed('/event_detail', arguments: app.eventId);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(app.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  _getStatusIcon(app.status),
                  color: _getStatusColor(app.status),
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _getEventName(app.eventId),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? l10n.eventNameLoading,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingS,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              app.status,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXS,
                            ),
                          ),
                          child: Text(
                            _getStatusText(app.status, l10n),
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeXS,
                              color: _getStatusColor(app.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Icon(
                          Icons.calendar_today,
                          size: AppDimensions.iconXS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          _formatDate(app.appliedAt),
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
        ),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, GameEvent event) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/event_detail', arguments: event.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingL,
            vertical: AppDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  Icons.event,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppDimensions.iconXS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          _formatDate(event.startDate),
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        Icon(
                          Icons.people,
                          size: AppDimensions.iconXS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          '${event.participantCount}/${event.maxParticipants}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
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
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'pending':
        return Icons.schedule;
      case 'participating':
        return Icons.event_available;
      case 'hosting':
        return Icons.admin_panel_settings;
      case 'total':
        return Icons.emoji_events;
      default:
        return Icons.analytics;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'pending':
        return AppColors.warning;
      case 'participating':
        return AppColors.success;
      case 'hosting':
        return AppColors.info;
      case 'total':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.waitlisted:
        return AppColors.info;
      case ApplicationStatus.approved:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.waitlisted:
        return Icons.queue;
      case ApplicationStatus.approved:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusText(ApplicationStatus status, L10n l10n) {
    switch (status) {
      case ApplicationStatus.pending:
        return l10n.statusPending;
      case ApplicationStatus.waitlisted:
        return l10n.statusWaitlisted;
      case ApplicationStatus.approved:
        return l10n.statusApproved;
      case ApplicationStatus.rejected:
        return l10n.statusRejected;
      case ApplicationStatus.cancelled:
        return l10n.statusCancelled;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  GameEventType _parseEventType(dynamic value) {
    switch (value?.toString()) {
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

  GameEventStatus _parseEventStatus(dynamic value) {
    switch (value?.toString()) {
      case 'upcoming':
        return GameEventStatus.upcoming;
      case 'active':
        return GameEventStatus.active;
      case 'completed':
        return GameEventStatus.completed;
      case 'expired':
        return GameEventStatus.expired;
      case 'cancelled':
        return GameEventStatus.cancelled;
      default:
        return GameEventStatus.upcoming;
    }
  }

  Future<String> _getEventName(String? eventId) async {
    if (eventId == null || eventId.isEmpty) {
      return 'イベント';
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name']?.toString() ?? 'イベント';
      }
      return 'イベント';
    } catch (e) {
      return 'イベント';
    }
  }

  /// CustomユーザーIDからFirebaseUIDを取得
  Future<String?> _getFirebaseUidFromCustomId(String customUserId) async {
    try {
      // まず、渡されたIDがすでにFirebaseUIDかどうかをチェック
      // FirebaseUIDは通常28文字で英数字
      if (customUserId.length == 28 &&
          RegExp(r'^[a-zA-Z0-9]+$').hasMatch(customUserId)) {
        return customUserId;
      }

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: customUserId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 運営イベントのドキュメントを取得
  Future<List<DocumentSnapshot>> _getManagedEventDocs(
    String firebaseUid,
  ) async {
    final allDocs = <String, DocumentSnapshot>{};

    try {
      // 1. 作成者として作成したイベントを取得
      final createdEventsQuery = await FirebaseFirestore.instance
          .collection('events')
          .where('createdBy', isEqualTo: firebaseUid)
          .get();

      for (final doc in createdEventsQuery.docs) {
        allDocs[doc.id] = doc;
      }

      // 2. 管理者として参加しているイベントを取得
      try {
        final managedEventsQuery = await FirebaseFirestore.instance
            .collection('events')
            .where('managerIds', arrayContains: firebaseUid)
            .get();

        for (final doc in managedEventsQuery.docs) {
          allDocs[doc.id] = doc;
        }
      } catch (e) {
        // managerIdsフィールドが存在しない場合は無視
      }

      // 3. スポンサーとして参加しているイベントを取得
      try {
        final sponsorEventsQuery = await FirebaseFirestore.instance
            .collection('events')
            .where('sponsorIds', arrayContains: firebaseUid)
            .get();

        for (final doc in sponsorEventsQuery.docs) {
          allDocs[doc.id] = doc;
        }
      } catch (e) {
        // sponsorIdsフィールドが存在しない場合は無視
      }

      // 日付でソート（新しい順）
      final sortedDocs = allDocs.values.toList();
      sortedDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;

        final aDate = aData['updatedAt'] != null
            ? (aData['updatedAt'] as Timestamp).toDate()
            : DateTime.now();
        final bDate = bData['updatedAt'] != null
            ? (bData['updatedAt'] as Timestamp).toDate()
            : DateTime.now();

        return bDate.compareTo(aDate);
      });

      return sortedDocs.take(50).toList();
    } catch (e) {
      return [];
    }
  }
}
