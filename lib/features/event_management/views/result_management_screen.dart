import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/match_result_service.dart';
import '../../../shared/services/match_report_service.dart';
import '../../../shared/services/group_management_service.dart';
import '../../../shared/services/participation_service.dart';
import '../widgets/match_registration_dialog.dart';
import '../widgets/match_report_detail_dialog.dart';
import '../widgets/match_report_status_dialog.dart';
import 'match_result_input_screen.dart';
import 'match_detail_screen.dart';
import 'group_room_management_screen.dart';
import 'event_participants_management_screen.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

/// 試合ソート種別
enum MatchSortType {
  newest,        // 新しい順
  oldest,        // 古い順
  reportCount,   // 報告数順
  pendingReports, // 未処理報告優先
  status,        // ステータス順
}

/// 戦績・結果管理画面
class ResultManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;

  const ResultManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
  });

  @override
  ConsumerState<ResultManagementScreen> createState() =>
      _ResultManagementScreenState();
}

class _ResultManagementScreenState
    extends ConsumerState<ResultManagementScreen> {

  List<MatchResult> _matches = [];

  bool _isLoading = true;
  bool _isTeamEvent = false;
  List<String> _participants = []; // グループIDまたはユーザーID
  Map<String, String> _participantNames = {}; // participantId -> 表示名
  final MatchResultService _matchResultService = MatchResultService();
  final MatchReportService _reportService = MatchReportService();
  final GroupManagementService _groupService = GroupManagementService();

  // 試合報告関連データ
  Map<String, List<MatchReport>> _matchReports = {}; // matchId -> 報告リスト
  Map<String, int> _matchReportCounts = {}; // matchId -> 報告数

  // ソート関連
  MatchSortType _currentSortType = MatchSortType.newest;
  bool _showPendingReportsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadResultData();
  }

  /// 参加者を読み込み
  Future<void> _loadParticipants() async {
    try {
      if (_isTeamEvent) {
        // チーム戦の場合：グループIDを取得
        _participants = await _groupService.getEventGroupIds(widget.eventId);
        // グループ名も取得
        _participantNames = await _groupService.getGroupNames(_participants);

        // チーム戦の場合は個人スコア表示のためにチームメンバーの名前も取得
        await _loadTeamMemberNames();
      } else {
        // 個人戦の場合：承認済み参加者をサーバーから強制取得
        final applications = await ParticipationService.getEventApplicationsFromServer(
          widget.eventId,
          forceFromServer: true,
        );
        final approvedParticipants = applications
            .where((app) => app.status == ParticipationStatus.approved)
            .toList();

        _participants = approvedParticipants.map((app) => app.userId).toList();

        // 参加者名を設定（ゲーム内ユーザー名または表示名を使用）
        _participantNames = {};
        for (final app in approvedParticipants) {
          _participantNames[app.userId] = app.gameUsername ?? app.userDisplayName;
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToLoadParticipants(e.toString()))),
        );
      }
    }
  }

  /// チームメンバーの名前を読み込み
  Future<void> _loadTeamMemberNames() async {
    try {
      // 全チームのメンバーIDを収集
      final allMemberIds = <String>[];
      for (final teamId in _participants) {
        final members = await _groupService.getGroupMembers(teamId);
        allMemberIds.addAll(members);
      }

      if (allMemberIds.isNotEmpty) {
        // 承認済み参加者の表示名とゲーム内ユーザー名を一括取得
        final participantInfo = await _groupService.getApprovedParticipantNames(
          widget.eventId,
          allMemberIds
        );

        // ゲーム内ユーザー名を優先的に使用し、なければ表示名を使用
        if (mounted) {
          final l10n = L10n.of(context);
          for (final entry in participantInfo.entries) {
            final userId = entry.key;
            final info = entry.value;
            _participantNames[userId] = info['gameUsername'] ?? info['displayName'] ?? l10n.defaultUserName;
          }
        }
      }
    } catch (e) {
      // チームメンバー名の取得エラーを無視
    }
  }

  Future<void> _loadResultData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // グループ管理から現在のイベントがチーム戦かどうかを判定
      final isTeamMatch = await _groupService.isTeamMatchEvent(widget.eventId);
      _isTeamEvent = isTeamMatch;

      // 参加者を取得
      await _loadParticipants();

      // データを読み込み
      final matches = await _matchResultService.getMatchResultsByEventId(widget.eventId);

      // 各試合の報告を読み込み
      await _loadMatchReports(matches);

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToLoadData(e.toString()))),
        );
      }
    }
  }

  /// 試合報告データを読み込み
  Future<void> _loadMatchReports(List<MatchResult> matches) async {
    try {
      _matchReports.clear();
      _matchReportCounts.clear();

      for (final match in matches) {
        if (match.id != null) {
          final reports = await _reportService.getMatchReports(match.id!);
          _matchReports[match.id!] = reports;
          _matchReportCounts[match.id!] = reports.length;
        }
      }
    } catch (e) {
      // エラーが発生しても画面表示は続行
    }
  }

  /// 試合の報告件数を取得
  int _getMatchReportCount(String matchId) {
    return _matchReportCounts[matchId] ?? 0;
  }

  /// 試合の未処理報告件数を取得
  int _getPendingReportCount(String matchId) {
    final reports = _matchReports[matchId] ?? [];
    return reports.where((r) =>
        r.status == MatchReportStatus.submitted ||
        r.status == MatchReportStatus.reviewing
    ).length;
  }

  /// 表示用の試合リストを取得（ソートとフィルタリング適用）
  List<MatchResult> _getDisplayMatches() {
    List<MatchResult> displayMatches = List.from(_matches);

    // 未処理報告のみ表示フィルター
    if (_showPendingReportsOnly) {
      displayMatches = displayMatches.where((match) {
        if (match.id == null) return false;
        return _getPendingReportCount(match.id!) > 0;
      }).toList();
    }

    // ソート処理
    switch (_currentSortType) {
      case MatchSortType.newest:
        displayMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case MatchSortType.oldest:
        displayMatches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case MatchSortType.reportCount:
        displayMatches.sort((a, b) {
          final aCount = a.id != null ? _getMatchReportCount(a.id!) : 0;
          final bCount = b.id != null ? _getMatchReportCount(b.id!) : 0;
          return bCount.compareTo(aCount); // 報告数の多い順
        });
        break;
      case MatchSortType.pendingReports:
        displayMatches.sort((a, b) {
          final aPending = a.id != null ? _getPendingReportCount(a.id!) : 0;
          final bPending = b.id != null ? _getPendingReportCount(b.id!) : 0;
          if (aPending != bPending) {
            return bPending.compareTo(aPending); // 未処理報告数の多い順
          }
          return b.createdAt.compareTo(a.createdAt); // 同じなら新しい順
        });
        break;
      case MatchSortType.status:
        displayMatches.sort((a, b) {
          // ステータス優先度: 進行中 > 予定 > 完了
          final aStatus = a.status.index;
          final bStatus = b.status.index;
          if (aStatus != bStatus) {
            return aStatus.compareTo(bStatus);
          }
          return b.createdAt.compareTo(a.createdAt); // 同じなら新しい順
        });
        break;
    }

    return displayMatches;
  }

  /// ソート種別の表示名を取得
  String _getSortTypeName(MatchSortType type) {
    final l10n = L10n.of(context);
    switch (type) {
      case MatchSortType.newest:
        return l10n.sortNewest;
      case MatchSortType.oldest:
        return l10n.sortOldest;
      case MatchSortType.reportCount:
        return l10n.sortReportCount;
      case MatchSortType.pendingReports:
        return l10n.sortPendingReports;
      case MatchSortType.status:
        return l10n.sortStatus;
    }
  }

  /// ソート種別のアイコンを取得
  IconData _getSortIcon(MatchSortType type) {
    switch (type) {
      case MatchSortType.newest:
        return Icons.arrow_downward;
      case MatchSortType.oldest:
        return Icons.arrow_upward;
      case MatchSortType.reportCount:
        return Icons.report;
      case MatchSortType.pendingReports:
        return Icons.priority_high;
      case MatchSortType.status:
        return Icons.list_alt;
    }
  }

  /// 報告バッジを構築
  List<Widget> _buildReportBadges(String matchId) {
    final totalReports = _getMatchReportCount(matchId);
    final pendingReports = _getPendingReportCount(matchId);

    if (totalReports == 0) return [];

    final badges = <Widget>[];

    // 未処理報告バッジ（優先表示）
    if (pendingReports > 0) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.priority_high,
                size: AppDimensions.iconXS,
                color: Colors.white,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                L10n.of(context).pendingReportsCount(pendingReports),
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 処理済み報告がある場合の総数バッジ
    final resolvedReports = totalReports - pendingReports;
    if (resolvedReports > 0) {
      badges.add(
        const SizedBox(width: AppDimensions.spacingXS),
      );
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingS,
            vertical: AppDimensions.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: AppColors.success,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppDimensions.iconXS,
                color: AppColors.success,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                L10n.of(context).resolvedReportsCount(resolvedReports),
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: l10n.matchResultTitle,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                enableTap: widget.fromNotification,
                iconData: Icons.leaderboard,
              ),
              Expanded(
                child: Container(
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingL),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics,
                                  color: AppColors.accent,
                                  size: AppDimensions.iconM,
                                ),
                                const SizedBox(width: AppDimensions.spacingS),
                                Text(
                                  l10n.matchResultLabel,
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontSizeL,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const Spacer(),
                                PopupMenuButton<MatchSortType>(
                                  onSelected: (MatchSortType type) {
                                    setState(() {
                                      _currentSortType = type;
                                    });
                                  },
                                  itemBuilder: (context) => MatchSortType.values.map((type) {
                                    return PopupMenuItem<MatchSortType>(
                                      value: type,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getSortIcon(type),
                                            size: AppDimensions.iconS,
                                            color: _currentSortType == type
                                                ? AppColors.accent
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: AppDimensions.spacingS),
                                          Text(
                                            _getSortTypeName(type),
                                            style: TextStyle(
                                              color: _currentSortType == type
                                                  ? AppColors.accent
                                                  : AppColors.textDark,
                                              fontWeight: _currentSortType == type
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.spacingM,
                                      vertical: AppDimensions.spacingS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sort,
                                          size: AppDimensions.iconS,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: AppDimensions.spacingXS),
                                        Text(
                                          _getSortTypeName(_currentSortType),
                                          style: const TextStyle(
                                            fontSize: AppDimensions.fontSizeS,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingM),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showPendingReportsOnly = !_showPendingReportsOnly;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppDimensions.spacingM,
                                        vertical: AppDimensions.spacingS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _showPendingReportsOnly
                                            ? AppColors.warning.withValues(alpha: 0.1)
                                            : AppColors.backgroundLight,
                                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                        border: Border.all(
                                          color: _showPendingReportsOnly
                                              ? AppColors.warning
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _showPendingReportsOnly
                                                ? Icons.check_box
                                                : Icons.check_box_outline_blank,
                                            size: AppDimensions.iconS,
                                            color: _showPendingReportsOnly
                                                ? AppColors.warning
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: AppDimensions.spacingXS),
                                          Text(
                                            l10n.showPendingReportsOnly,
                                            style: TextStyle(
                                              fontSize: AppDimensions.fontSizeS,
                                              color: _showPendingReportsOnly
                                                  ? AppColors.warning
                                                  : AppColors.textSecondary,
                                              fontWeight: _showPendingReportsOnly
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildMatchResultsTab(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _participants.length >= 2
          ? Container(
              margin: const EdgeInsets.only(
                right: AppDimensions.spacingM,
                bottom: AppDimensions.spacingM,
              ),
              child: FloatingActionButton.extended(
                onPressed: _registerMatch,
                backgroundColor: AppColors.accent,
                icon: const Icon(Icons.add_box, color: Colors.white),
                label: Text(
                  l10n.addMatch,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
    );
  }



  /// 試合結果タブ
  Widget _buildMatchResultsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
      return _buildEmptyMatchesState();
    }

    final displayMatches = _getDisplayMatches();

    if (displayMatches.isEmpty && _showPendingReportsOnly) {
      final l10n = L10n.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.report_off,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text(
                l10n.noPendingReports,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.problemMatchesDescription,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: displayMatches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(displayMatches[index]);
        },
      ),
    );
  }

  /// 試合データが空の場合の表示
  Widget _buildEmptyMatchesState() {
    final l10n = L10n.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.sports_esports,
                size: 40,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              l10n.noMatchesRegistered,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingL,
                vertical: AppDimensions.spacingM,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppDimensions.iconS,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      _isTeamEvent
                          ? l10n.teamMatchDescription
                          : l10n.individualMatchDescription,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.info,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            if (_participants.length < 2) ...[
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: AppDimensions.iconS,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Flexible(
                          child: Text(
                            _isTeamEvent
                                ? l10n.needTwoTeamsForMatch
                                : l10n.needTwoParticipantsForMatch,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    if (_isTeamEvent) ...[
                      Text(
                        l10n.needGroupsForTeamMatch,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      ElevatedButton.icon(
                        onPressed: _navigateToGroupManagement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingL,
                            vertical: AppDimensions.spacingS,
                          ),
                        ),
                        icon: const Icon(Icons.group_add, size: AppDimensions.iconS),
                        label: Text(
                          l10n.goToGroupManagement,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        l10n.needParticipantsForMatch,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textDark.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      ElevatedButton.icon(
                        onPressed: _navigateToParticipantManagement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingL,
                            vertical: AppDimensions.spacingS,
                          ),
                        ),
                        icon: const Icon(Icons.person_add, size: AppDimensions.iconS),
                        label: Text(
                          l10n.goToParticipantManagement,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 試合カード（コンパクト版）
  Widget _buildMatchCard(MatchResult match) {
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToMatchDetail(match),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: _getStatusColor(match.status).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 日時とステータス
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: AppDimensions.iconXS,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppDimensions.spacingXS),
                            Text(
                              _formatDateTime(match.createdAt),
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingS,
                          vertical: AppDimensions.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(match.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(match.status),
                              size: AppDimensions.iconXS,
                              color: _getStatusColor(match.status),
                            ),
                            const SizedBox(width: AppDimensions.spacingXS),
                            Text(
                              _getLocalizedMatchStatus(match.status),
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(match.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                  // 報告バッジ
                  if (match.id != null)
                    Row(
                      children: _buildReportBadges(match.id!),
                    ),
                  const SizedBox(width: AppDimensions.spacingS),
                  // アクションボタン
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMatchAction(match, value),
                    itemBuilder: (context) {
                      final reportCount = match.id != null ? _getMatchReportCount(match.id!) : 0;
                      return [
                        if (reportCount > 0)
                          PopupMenuItem(
                            value: 'view_reports',
                            child: Row(
                              children: [
                                const Icon(Icons.report, color: AppColors.warning),
                                const SizedBox(width: AppDimensions.spacingS),
                                Text(l10n.confirmReportsCount(reportCount)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'change_status',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, color: AppColors.info),
                              const SizedBox(width: AppDimensions.spacingS),
                              Text(l10n.changeStatus),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: AppColors.error),
                              const SizedBox(width: AppDimensions.spacingS),
                              Text(l10n.deleteAction),
                            ],
                          ),
                        ),
                      ];
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingXS),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: AppDimensions.iconS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),
              // 試合名
              Text(
                match.matchName,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spacingS),
              // 参加者情報
              Row(
                children: [
                  Icon(
                    _isTeamEvent ? Icons.group : Icons.person,
                    size: AppDimensions.iconS,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      match.participants.map((id) => _participantNames[id] ?? id).join(' vs '),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // 勝者情報（完了時のみ）
              if (match.isCompleted && match.winner != null) ...[
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: AppDimensions.iconS,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      l10n.winnerLabel(_participantNames[match.winner] ?? match.winner!),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppDimensions.spacingM),
              // アクションボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _inputResult(match),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: match.isCompleted ? AppColors.info : AppColors.accent,
                        side: BorderSide(
                          color: match.isCompleted ? AppColors.info : AppColors.accent,
                        ),
                      ),
                      icon: Icon(
                        match.isCompleted ? Icons.edit : Icons.input,
                        size: AppDimensions.iconS,
                      ),
                      label: Text(match.isCompleted ? l10n.editResult : l10n.inputResult),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  OutlinedButton(
                    onPressed: () => _navigateToMatchDetail(match),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text(l10n.detailButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }




  /// ヘルパーメソッド
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  /// アクションメソッド

  /// 試合詳細画面へ遷移
  void _navigateToMatchDetail(MatchResult match) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(
          match: match,
          participantNames: _participantNames,
          isTeamEvent: _isTeamEvent,
          onMatchUpdated: _onMatchUpdated,
        ),
      ),
    );

    if (result == true) {
      // 詳細画面で変更があった場合はデータを再読み込み
      await _loadResultData();
    }
  }

  /// 試合データ更新時の処理
  Future<void> _onMatchUpdated() async {
    await _loadResultData();
  }

  /// グループ管理画面へ遷移
  void _navigateToGroupManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupRoomManagementScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );

    // 画面から戻ってきたらデータを更新
    if (mounted) {
      await _loadResultData();
    }
  }

  /// 参加者管理画面へ遷移
  void _navigateToParticipantManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventParticipantsManagementScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );

    // 画面から戻ってきたらデータを更新
    if (mounted) {
      await _loadResultData();
    }
  }

  /// 試合を登録
  void _registerMatch() {
    final l10n = L10n.of(context);
    if (_participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTeamEvent
              ? l10n.needTwoTeamsForMatch
              : l10n.needTwoParticipantsForMatch),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MatchRegistrationDialog(
        eventId: widget.eventId,
        isTeamEvent: _isTeamEvent,
        participants: _participants,
        participantNames: _participantNames,
        onMatchRegistered: _onMatchRegistered,
      ),
    );
  }

  /// 試合登録完了時の処理
  Future<void> _onMatchRegistered(MatchResult match) async {
    final l10n = L10n.of(context);
    try {
      await _matchResultService.createMatchResult(match);

      // データを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchRegisteredMessage(match.matchName)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToRegisterMatch(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 試合結果を入力
  void _inputResult(MatchResult match) async {
    final result = await Navigator.of(context).push<MatchResult>(
      MaterialPageRoute(
        builder: (context) => MatchResultInputScreen(
          match: match,
          onResultSubmitted: _onResultSubmitted,
        ),
      ),
    );

    if (result != null) {
      await _onResultSubmitted(result);
    }
  }

  /// 試合結果提出完了時の処理
  Future<void> _onResultSubmitted(MatchResult updatedMatch) async {
    final l10n = L10n.of(context);
    try {
      await _matchResultService.updateMatchResult(updatedMatch);

      // データを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchResultSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToSaveMatchResult(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }



  /// ステータスに対応する色を取得
  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return AppColors.info;
      case MatchStatus.inProgress:
        return AppColors.warning;
      case MatchStatus.completed:
        return AppColors.success;
    }
  }

  /// ステータスに対応するアイコンを取得
  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return Icons.schedule;
      case MatchStatus.inProgress:
        return Icons.timer;
      case MatchStatus.completed:
        return Icons.check_circle;
    }
  }

  /// ステータス変更ダイアログを表示
  void _showStatusChangeDialog(MatchResult match) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.info),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.changeStatusTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectStatusForMatch(match.matchName)),
            const SizedBox(height: AppDimensions.spacingL),
            ...MatchStatus.values.map((status) => RadioListTile<MatchStatus>(
              title: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(_getLocalizedMatchStatus(status)),
                ],
              ),
              value: status,
              groupValue: match.status,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  _changeMatchStatus(match, value);
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// ステータス変更処理
  Future<void> _changeMatchStatus(MatchResult match, MatchStatus newStatus) async {
    final l10n = L10n.of(context);
    try {
      final updatedMatch = match.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _matchResultService.updateMatchResult(updatedMatch);

      // データを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.statusChangedMessage(_getLocalizedMatchStatus(newStatus))),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToChangeStatus(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  /// 試合の報告一覧を表示
  void _showMatchReports(MatchResult match) {
    if (match.id == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _buildReportsBottomSheet(
          match,
          scrollController,
        ),
      ),
    );
  }

  /// 報告リストのボトムシート
  Widget _buildReportsBottomSheet(MatchResult match, ScrollController scrollController) {
    final l10n = L10n.of(context);
    final reports = _matchReports[match.id!] ?? [];

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(
                Icons.report,
                color: AppColors.warning,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.matchReportsTitle,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      match.matchName,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Divider(),

          // 報告リスト
          if (reports.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.report_off,
                      size: 64,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Text(
                      l10n.noReportsForMatch,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppDimensions.fontSizeM,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return _buildReportCard(report, match);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 報告カード（簡略版）
  Widget _buildReportCard(MatchReport report, MatchResult match) {
    final l10n = L10n.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: InkWell(
        onTap: () => _showReportDetail(report, match),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingS,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getReportStatusColor(report.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Text(
                      _getLocalizedReportStatus(report.status),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.bold,
                        color: _getReportStatusColor(report.status),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatReportDateTime(report.createdAt, l10n),
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: AppDimensions.iconS,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Text(
                    report.issueType,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 報告詳細を表示
  Future<void> _showReportDetail(MatchReport report, MatchResult match) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportDetailDialog(
        report: report,
        matchResult: match,
        eventId: widget.eventId,
        eventName: widget.eventName,
        onStatusUpdate: () {
          _showStatusUpdateDialog(report, match);
        },
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      await _loadResultData();
    }
  }

  /// ステータス更新ダイアログを表示
  Future<void> _showStatusUpdateDialog(MatchReport report, MatchResult match) async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportStatusDialog(
        report: report,
        matchResult: match,
        adminId: currentUser.uid,
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      Navigator.of(context).pop(true); // 詳細ダイアログも閉じる
      await _loadResultData();
    }
  }

  /// 報告ステータスの色を取得
  Color _getReportStatusColor(MatchReportStatus status) {
    switch (status) {
      case MatchReportStatus.submitted:
        return AppColors.warning;
      case MatchReportStatus.reviewing:
        return AppColors.info;
      case MatchReportStatus.resolved:
        return AppColors.success;
      case MatchReportStatus.rejected:
        return AppColors.textSecondary;
    }
  }

  /// 報告日時フォーマット
  String _formatReportDateTime(DateTime dateTime, L10n l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inHours < 1) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return l10n.hoursAgo(difference.inHours);
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// 試合アクション処理
  void _handleMatchAction(MatchResult match, String action) {
    switch (action) {
      case 'view_reports':
        if (match.id != null) {
          _showMatchReports(match);
        }
        break;
      case 'change_status':
        _showStatusChangeDialog(match);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(match);
        break;
    }
  }

  /// 試合削除確認ダイアログを表示
  void _showDeleteConfirmationDialog(MatchResult match) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.deleteMatchTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteMatchConfirmation(match.matchName)),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      l10n.deleteMatchWarning,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMatch(match);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
  }

  /// 試合を削除
  Future<void> _deleteMatch(MatchResult match) async {
    final l10n = L10n.of(context);
    try {
      // データベースから削除
      if (match.id != null) {
        await _matchResultService.deleteMatchResult(match.id!);
      }

      // ローカルのマッチリストから削除
      setState(() {
        _matches.removeWhere((m) => m.id == match.id);
      });

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.matchDeletedMessage(match.matchName)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // エラーが発生した場合はデータを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteMatch(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// MatchStatusのローカライズ表示名を取得
  String _getLocalizedMatchStatus(MatchStatus status) {
    final l10n = L10n.of(context);
    switch (status) {
      case MatchStatus.scheduled:
        return l10n.matchStatusScheduled;
      case MatchStatus.inProgress:
        return l10n.matchStatusInProgress;
      case MatchStatus.completed:
        return l10n.matchStatusCompleted;
    }
  }

  /// MatchReportStatusのローカライズ表示名を取得
  String _getLocalizedReportStatus(MatchReportStatus status) {
    final l10n = L10n.of(context);
    switch (status) {
      case MatchReportStatus.submitted:
        return l10n.reportStatusSubmitted;
      case MatchReportStatus.reviewing:
        return l10n.reportStatusReviewing;
      case MatchReportStatus.resolved:
        return l10n.reportStatusResolved;
      case MatchReportStatus.rejected:
        return l10n.reportStatusRejected;
    }
  }
}

