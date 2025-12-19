import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/zoomable_image_widget.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/match_result_service.dart';
import '../../../shared/services/match_report_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../widgets/match_report_detail_dialog.dart';
import '../widgets/match_report_status_dialog.dart';
import '../../../shared/widgets/user_action_modal.dart';
import 'match_result_input_screen.dart';

/// 試合詳細画面
class MatchDetailScreen extends ConsumerStatefulWidget {
  final MatchResult match;
  final Map<String, String> participantNames;
  final bool isTeamEvent;
  final VoidCallback onMatchUpdated;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.participantNames,
    required this.isTeamEvent,
    required this.onMatchUpdated,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late MatchResult _currentMatch;
  late TabController _tabController;
  final MatchResultService _matchResultService = MatchResultService();
  final MatchReportService _reportService = MatchReportService();

  // 報告関連データ
  List<MatchReport> _reports = [];
  Map<String, String> _reporterNames = {}; // reporterId -> 表示名
  bool _isLoadingReports = true;
  int _pendingReportCount = 0;

  @override
  void initState() {
    super.initState();
    _currentMatch = widget.match;
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 報告データを読み込み
  Future<void> _loadReports() async {
    if (_currentMatch.id == null) return;

    setState(() {
      _isLoadingReports = true;
    });

    try {
      final reports = await _reportService.getMatchReports(_currentMatch.id!);
      final pendingCount = reports.where((r) =>
        r.status == MatchReportStatus.submitted ||
        r.status == MatchReportStatus.reviewing
      ).length;

      // 報告者の名前を取得
      await _loadReporterNames(reports);

      if (mounted) {
        setState(() {
          _reports = reports;
          _pendingReportCount = pendingCount;
          _isLoadingReports = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReports = false;
        });
      }
    }
  }

  /// 報告者の名前を取得
  Future<void> _loadReporterNames(List<MatchReport> reports) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      final reporterIds = reports.map((r) => r.reporterId).toSet();

      // 参加者情報から報告者のゲーム内ユーザー名を取得
      final applications = await ParticipationService.getEventApplicationsFromServer(
        _currentMatch.eventId,
        forceFromServer: true,
      );

      // まずゲーム内ユーザー名を優先的に設定
      for (final application in applications) {
        if (reporterIds.contains(application.userId) && application.gameUsername != null) {
          _reporterNames[application.userId] = application.gameUsername!;
        }
      }

      // ゲーム内ユーザー名がない場合は表示名を取得
      for (final reporterId in reporterIds) {
        if (!_reporterNames.containsKey(reporterId)) {
          try {
            final userData = await userRepository.getUserById(reporterId) ??
                await userRepository.getUserByCustomId(reporterId);
            if (userData != null) {
              _reporterNames[reporterId] = userData.displayName;
            } else {
              _reporterNames[reporterId] = '不明';
            }
          } catch (e) {
            _reporterNames[reporterId] = '不明';
          }
        }
      }
    } catch (e) {
      // 報告者名の取得に失敗
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
                title: '試合詳細',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              // タブバー
              Container(
                margin: const EdgeInsets.all(AppDimensions.spacingL),
                padding: const EdgeInsets.all(AppDimensions.spacingXS),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                  tabs: [
                    const Tab(text: '試合情報'),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('問題報告'),
                          if (_pendingReportCount > 0) ...[
                            const SizedBox(width: AppDimensions.spacingXS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_pendingReportCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: AppDimensions.fontSizeXS,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // タブビュー
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 試合情報タブ
                    _buildMatchInfoTab(),
                    // 問題報告タブ
                    _buildReportsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 試合情報タブ
  Widget _buildMatchInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchHeader(),
          const SizedBox(height: AppDimensions.spacingL),
          _buildMatchContent(),
          const SizedBox(height: AppDimensions.spacingXL),
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 試合ヘッダー
  Widget _buildMatchHeader() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _currentMatch.matchName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeXL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change_status',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.info),
                        SizedBox(width: AppDimensions.spacingS),
                        Text('ステータス変更'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppColors.error),
                        SizedBox(width: AppDimensions.spacingS),
                        Text('削除'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: AppDimensions.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '作成: ${_formatDateTime(_currentMatch.createdAt)}',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_currentMatch.completedAt != null) ...[
                const SizedBox(width: AppDimensions.spacingL),
                Icon(
                  Icons.check_circle,
                  size: AppDimensions.iconS,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '完了: ${_formatDateTime(_currentMatch.completedAt!)}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.success,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(_currentMatch.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(_currentMatch.status),
                  size: AppDimensions.iconS,
                  color: _getStatusColor(_currentMatch.status),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  _currentMatch.status.displayName,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(_currentMatch.status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 試合コンテンツ
  Widget _buildMatchContent() {
    if (_currentMatch.isCompleted) {
      return _buildCompletedMatchContent();
    } else if (_currentMatch.isInProgress) {
      return _buildInProgressMatchContent();
    } else if (_currentMatch.isScheduled) {
      return _buildScheduledMatchContent();
    }
    return const SizedBox.shrink();
  }

  /// 完了した試合のコンテンツ
  Widget _buildCompletedMatchContent() {
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
          // 勝者表示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: AppColors.success,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '勝者: ${widget.participantNames[_currentMatch.winner] ?? _currentMatch.winner ?? '引き分け'}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacingL),

          // 順位表示
          _buildRankingDisplay(),

          const SizedBox(height: AppDimensions.spacingL),

          // スコア表示
          if (_currentMatch.scores.isNotEmpty) ...[
            _buildScoresDisplay(),
            const SizedBox(height: AppDimensions.spacingL),
          ],

          // 個人スコア表示（チーム戦の場合）
          if (_currentMatch.isTeamMatch &&
              _currentMatch.individualScores != null &&
              _currentMatch.individualScores!.isNotEmpty) ...[
            _buildIndividualScoresDisplay(),
            const SizedBox(height: AppDimensions.spacingL),
          ],

          // 運営メモ表示
          if (_currentMatch.adminPublicNotes != null && _currentMatch.adminPublicNotes!.isNotEmpty ||
              _currentMatch.adminPrivateNotes != null && _currentMatch.adminPrivateNotes!.isNotEmpty) ...[
            _buildAdminNotesDisplay(),
            const SizedBox(height: AppDimensions.spacingL),
          ],

          // エビデンス画像表示
          if (_currentMatch.evidenceImages.isNotEmpty) ...[
            _buildEvidenceImagesDisplay(),
          ],
        ],
      ),
    );
  }

  /// 進行中の試合のコンテンツ
  Widget _buildInProgressMatchContent() {
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
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: _buildParticipantsList(),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: AppColors.warning,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '結果入力待ち',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 開催予定の試合のコンテンツ
  Widget _buildScheduledMatchContent() {
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
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: _buildParticipantsList(),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: AppColors.info,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '開催予定',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 順位表示
  Widget _buildRankingDisplay() {
    // 勝者を基に順位を推定（勝者が1位、他は参加順）
    final rankedParticipants = List<String>.from(_currentMatch.participants);
    if (_currentMatch.winner != null && rankedParticipants.contains(_currentMatch.winner!)) {
      rankedParticipants.remove(_currentMatch.winner!);
      rankedParticipants.insert(0, _currentMatch.winner!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: AppColors.accent,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              '順位',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: rankedParticipants.asMap().entries.map((entry) {
              final index = entry.key;
              final participantId = entry.value;
              final rank = index + 1;

              Color rankColor;
              IconData rankIcon;

              switch (rank) {
                case 1:
                  rankColor = AppColors.warning;
                  rankIcon = Icons.looks_one;
                  break;
                case 2:
                  rankColor = AppColors.textSecondary;
                  rankIcon = Icons.looks_two;
                  break;
                case 3:
                  rankColor = AppColors.secondary;
                  rankIcon = Icons.looks_3;
                  break;
                default:
                  rankColor = AppColors.textLight;
                  rankIcon = Icons.radio_button_unchecked;
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < rankedParticipants.length - 1 ? AppDimensions.spacingM : 0,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        rankIcon,
                        color: rankColor,
                        size: AppDimensions.iconM,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingL),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showUserActionModal(participantId),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.spacingXS,
                          ),
                          child: Text(
                            widget.participantNames[participantId] ?? participantId,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: rank == 1 ? FontWeight.w600 : FontWeight.w500,
                              color: rank == 1 ? AppColors.success : AppColors.accent,
                              decoration: TextDecoration.underline,
                              decorationColor: rank == 1 ? AppColors.success : AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '$rank位',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: rankColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// スコア表示
  Widget _buildScoresDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.score,
              color: AppColors.secondary,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              'スコア',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _currentMatch.scores.entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showUserActionModal(entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingXS,
                        ),
                        child: Text(
                          widget.participantNames[entry.key] ?? entry.key,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}点',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: entry.key == _currentMatch.winner
                          ? AppColors.success
                          : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  /// 個人スコア表示
  Widget _buildIndividualScoresDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person,
              color: AppColors.info,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              '個人スコア',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _currentMatch.individualScores!.entries.map((entry) =>
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingS),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _showUserActionModal(entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.spacingXS,
                        ),
                        child: Text(
                          widget.participantNames[entry.key] ?? entry.key,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            color: AppColors.accent,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value}点',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _inputResult(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentMatch.isCompleted ? AppColors.info : AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
            ),
            icon: Icon(_currentMatch.isCompleted ? Icons.edit : Icons.input),
            label: Text(
              _currentMatch.isCompleted ? '結果編集' : '結果入力',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              gradient: LinearGradient(
                colors: [
                  AppColors.info.withValues(alpha: 0.1),
                  AppColors.info.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: AppColors.info,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                onTap: () => _showStatusChangeDialog(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: Colors.white,
                          size: AppDimensions.iconS,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Text(
                        'ステータス変更',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// アクション処理
  void _handleAction(String action) {
    switch (action) {
      case 'change_status':
        _showStatusChangeDialog();
        break;
      case 'delete':
        _showDeleteConfirmationDialog();
        break;
    }
  }

  /// ステータス変更ダイアログを表示
  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.info),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('ステータス変更'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${_currentMatch.matchName}」のステータスを選択してください'),
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
                  Text(status.displayName),
                ],
              ),
              value: status,
              groupValue: _currentMatch.status,
              onChanged: (value) {
                if (value != null) {
                  Navigator.of(context).pop();
                  _changeMatchStatus(value);
                }
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// ステータス変更処理
  Future<void> _changeMatchStatus(MatchStatus newStatus) async {
    try {
      final updatedMatch = _currentMatch.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _matchResultService.updateMatchResult(updatedMatch);

      setState(() {
        _currentMatch = updatedMatch;
      });

      widget.onMatchUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータスを「${newStatus.displayName}」に変更しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ステータス変更に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 削除確認ダイアログ
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('試合削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${_currentMatch.matchName}」を削除しますか？'),
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.error, size: 20),
                  SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      'この操作は取り消せません。\n試合データは完全に削除されます。',
                      style: TextStyle(
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
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMatch();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 試合削除処理
  Future<void> _deleteMatch() async {
    try {
      if (_currentMatch.id != null) {
        await _matchResultService.deleteMatchResult(_currentMatch.id!);
      }

      widget.onMatchUpdated();

      if (mounted) {
        Navigator.of(context).pop(true); // 削除完了を通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合「${_currentMatch.matchName}」を削除しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合の削除に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 結果入力
  void _inputResult() async {
    final result = await Navigator.of(context).push<MatchResult>(
      MaterialPageRoute(
        builder: (context) => MatchResultInputScreen(
          match: _currentMatch,
          onResultSubmitted: _onResultSubmitted,
        ),
      ),
    );

    if (result != null) {
      await _onResultSubmitted(result);
    }
  }

  /// 結果提出完了時の処理
  Future<void> _onResultSubmitted(MatchResult updatedMatch) async {
    try {
      await _matchResultService.updateMatchResult(updatedMatch);

      setState(() {
        _currentMatch = updatedMatch;
      });

      widget.onMatchUpdated();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('試合結果を保存しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合結果の保存に失敗しました: $e'),
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

  /// エビデンス画像表示（詳細画面用）
  Widget _buildEvidenceImagesDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                color: AppColors.info,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'エビデンス画像',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                ),
                child: Text(
                  '${_currentMatch.evidenceImages.length}枚',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimensions.spacingS,
              mainAxisSpacing: AppDimensions.spacingS,
              childAspectRatio: 1,
            ),
            itemCount: _currentMatch.evidenceImages.length,
            itemBuilder: (context, index) {
              final imageUrl = _currentMatch.evidenceImages[index];
              return GestureDetector(
                onTap: () {}, // ZoomableImageWidget handles tap automatically
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.info),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: ZoomableImageWidget(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// エビデンス画像セクション

  /// 試合データを再読み込み
  Future<void> _refreshMatchData() async {
    try {
      if (_currentMatch.id != null) {
        // 試合データを再取得してUI更新
        final matchService = MatchResultService();
        final updatedMatches = await matchService.getMatchResultsByEventId(_currentMatch.eventId);
        final updatedMatch = updatedMatches.firstWhere(
          (match) => match.id == _currentMatch.id,
          orElse: () => _currentMatch,
        );

        setState(() {
          _currentMatch = updatedMatch;
        });

        // 親画面にも更新を通知
        widget.onMatchUpdated();
      }
    } catch (e) {
      // エラーは無視（UI更新は必須ではない）
    }
  }

  /// 運営メモ表示（管理者向け：公開・プライベート両方を表示）
  Widget _buildAdminNotesDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 公開メモ（ユーザー閲覧可能）
        if (_currentMatch.adminPublicNotes != null && _currentMatch.adminPublicNotes!.isNotEmpty) ...[
          Container(
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.visibility,
                        color: AppColors.info,
                        size: AppDimensions.iconS,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '公開メモ（ユーザー閲覧可能）',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '参加者に公開される運営メモです',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _currentMatch.adminPublicNotes!,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 公開メモとプライベートメモの両方がある場合のスペース
        if (_currentMatch.adminPublicNotes != null && _currentMatch.adminPublicNotes!.isNotEmpty &&
            _currentMatch.adminPrivateNotes != null && _currentMatch.adminPrivateNotes!.isNotEmpty)
          const SizedBox(height: AppDimensions.spacingM),

        // プライベートメモ（運営者のみ）
        if (_currentMatch.adminPrivateNotes != null && _currentMatch.adminPrivateNotes!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
                width: 2,
              ),
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.visibility_off,
                        color: AppColors.warning,
                        size: AppDimensions.iconS,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'プライベートメモ（運営者のみ閲覧可能）',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '内部管理用のメモです（参加者には表示されません）',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _currentMatch.adminPrivateNotes!,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 参加者リストをタップ可能な形式で構築
  Widget _buildParticipantsList() {
    final participants = _currentMatch.participants;

    if (participants.isEmpty) {
      return const Text(
        '参加者: なし',
        style: TextStyle(
          fontSize: AppDimensions.fontSizeS,
          color: AppColors.textSecondary,
        ),
      );
    }

    return Wrap(
      children: [
        const Text(
          '参加者: ',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        for (int i = 0; i < participants.length; i++) ...[
          GestureDetector(
            onTap: () => _showUserActionModal(participants[i]),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXS,
                vertical: 2,
              ),
              child: Text(
                widget.participantNames[participants[i]] ?? participants[i],
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (i < participants.length - 1)
            const Text(
              ' vs ',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ],
    );
  }

  /// ユーザーアクションモーダルを表示
  void _showUserActionModal(String userId) {
    final userName = widget.participantNames[userId] ?? userId;

    UserActionModal.show(
      context: context,
      eventId: _currentMatch.eventId,
      eventName: widget.match.matchName,
      userId: userId,
      userName: userName,
      onGameProfileTap: () {
        // ゲームプロフィール表示の実装（必要に応じて）
        Navigator.of(context).pushNamed(
          '/game_profile_view',
          arguments: {
            'userId': userId,
            'gameId': 'default', // 適切なゲームIDに置き換え
          },
        );
      },
      onUserProfileTap: () {
        // ユーザープロフィール表示の実装
        Navigator.of(context).pushNamed(
          '/user_profile',
          arguments: userId,
        );
      },
      showViolationReport: true,
    );
  }

  /// 問題報告タブ
  Widget _buildReportsTab() {
    if (_isLoadingReports) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_reports.isEmpty) {
      return Padding(
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
            mainAxisAlignment: MainAxisAlignment.center,
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
                  Icons.report_off,
                  size: 40,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text(
                'この試合に関する報告はありません',
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
                        '問題が発生した場合は、参加者から報告が届きます',
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
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  /// 報告カード
  Widget _buildReportCard(MatchReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: InkWell(
        onTap: () => _showReportDetail(report),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー（ステータスと時刻）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: _getReportStatusColor(report.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getReportStatusIcon(report.status),
                          size: AppDimensions.iconS,
                          color: _getReportStatusColor(report.status),
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          report.status.displayName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            fontWeight: FontWeight.bold,
                            color: _getReportStatusColor(report.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatReportDateTime(report.createdAt),
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // 報告者情報
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: AppDimensions.iconS,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  const Text(
                    '報告者: ',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showUserActionModal(report.reporterId),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingXS,
                        vertical: 2,
                      ),
                      child: Text(
                        _reporterNames[report.reporterId] ?? '不明',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 問題タイプ
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: AppDimensions.iconM,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      report.issueType,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),

              // 説明
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  report.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],

              // 管理者対応済みの場合
              if (report.adminResponse != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: AppDimensions.iconS,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '運営対応',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingXS),
                            Text(
                              report.adminResponse!,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeS,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // アクションボタン（未対応の場合）
              if (report.status == MatchReportStatus.submitted ||
                  report.status == MatchReportStatus.reviewing) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showReportDetail(report),
                      icon: const Icon(Icons.visibility, size: AppDimensions.iconS),
                      label: const Text('詳細を確認'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    ElevatedButton.icon(
                      onPressed: () => _showReportDetail(report),
                      icon: const Icon(Icons.edit_note, size: AppDimensions.iconS),
                      label: const Text('対応する'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingM,
                          vertical: AppDimensions.spacingS,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 報告詳細を表示
  Future<void> _showReportDetail(MatchReport report) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportDetailDialog(
        report: report,
        matchResult: _currentMatch,
        eventId: _currentMatch.eventId,
        eventName: widget.match.matchName,
        onStatusUpdate: () {
          _showStatusUpdateDialog(report);
        },
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      await _loadReports();
    }
  }

  /// ステータス更新ダイアログを表示
  Future<void> _showStatusUpdateDialog(MatchReport report) async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportStatusDialog(
        report: report,
        matchResult: _currentMatch,
        adminId: currentUser.uid,
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      Navigator.of(context).pop(true); // 詳細ダイアログも閉じる
      await _loadReports();
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

  /// 報告ステータスのアイコンを取得
  IconData _getReportStatusIcon(MatchReportStatus status) {
    switch (status) {
      case MatchReportStatus.submitted:
        return Icons.report_outlined;
      case MatchReportStatus.reviewing:
        return Icons.visibility;
      case MatchReportStatus.resolved:
        return Icons.check_circle;
      case MatchReportStatus.rejected:
        return Icons.cancel;
    }
  }

  /// 報告日時フォーマット
  String _formatReportDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}