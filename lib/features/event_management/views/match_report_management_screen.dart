import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/services/match_report_service.dart';
import '../../../shared/services/match_result_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../data/models/match_result_model.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../widgets/match_report_detail_dialog.dart';
import '../widgets/match_report_status_dialog.dart';

/// 試合報告管理画面
class MatchReportManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;

  const MatchReportManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
  });

  @override
  ConsumerState<MatchReportManagementScreen> createState() =>
      _MatchReportManagementScreenState();
}

class _MatchReportManagementScreenState
    extends ConsumerState<MatchReportManagementScreen> {
  final MatchReportService _reportService = MatchReportService();
  final MatchResultService _matchResultService = MatchResultService();

  List<MatchReport> _reports = [];
  Map<String, MatchResult?> _matchResultCache = {}; // matchId -> MatchResult
  Map<String, UserData> _userDataCache = {}; // userId -> UserData
  Map<String, String> _gameUsernameCache = {}; // userId -> gameUsername

  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // all, submitted, reviewing, resolved, rejected

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  /// 報告データを読み込み
  Future<void> _loadReportData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // イベントの試合報告を取得
      final reports = await _reportService.getEventMatchReports(widget.eventId);

      // 関連する試合情報を取得
      final matchIds = reports.map((r) => r.matchId).toSet();
      for (final matchId in matchIds) {
        try {
          final matchResult = await _matchResultService.getMatchResultById(matchId);
          _matchResultCache[matchId] = matchResult;
        } catch (e) {
          // 試合が削除されている場合はnullとして扱う
          _matchResultCache[matchId] = null;
        }
      }

      // ユーザー情報を取得
      final userRepository = ref.read(userRepositoryProvider);
      final userIds = reports.map((r) => r.reporterId).toSet();

      for (final userId in userIds) {
        try {
          final userData = await userRepository.getUserById(userId) ??
              await userRepository.getUserByCustomId(userId);
          if (userData != null) {
            _userDataCache[userId] = userData;
          }
        } catch (e) {
          // ユーザーデータ取得エラー
        }
      }

      // ゲーム内ユーザー名を取得
      try {
        final applications = await ParticipationService.getEventApplicationsFromServer(
          widget.eventId,
          forceFromServer: true,
        );

        for (final application in applications) {
          if (userIds.contains(application.userId) && application.gameUsername != null) {
            _gameUsernameCache[application.userId] = application.gameUsername!;
          }
        }
      } catch (e) {
        // ゲーム内ユーザー名取得エラー
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '報告データの読み込みに失敗しました: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// フィルタリングされた報告リストを取得
  List<MatchReport> get _filteredReports {
    if (_filterStatus == 'all') {
      return _reports;
    }
    return _reports.where((report) => report.status.value == _filterStatus).toList();
  }

  /// ステータスごとの報告数を取得
  int _getStatusCount(String status) {
    if (status == 'all') {
      return _reports.length;
    }
    return _reports.where((r) => r.status.value == status).length;
  }

  /// ステータスの色を取得
  Color _getStatusColor(MatchReportStatus status) {
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

  /// ステータスアイコンを取得
  IconData _getStatusIcon(MatchReportStatus status) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '試合報告管理',
                showBackButton: true,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorView()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// エラー表示
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconXXL,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              _errorMessage ?? 'エラーが発生しました',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            ElevatedButton.icon(
              onPressed: _loadReportData,
              icon: const Icon(Icons.refresh),
              label: const Text('再読み込み'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingXL,
                  vertical: AppDimensions.spacingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// コンテンツ表示
  Widget _buildContent() {
    return Column(
      children: [
        // イベント情報カード
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: EventInfoCard(
            eventId: widget.eventId,
            eventName: widget.eventName,
          ),
        ),
        // フィルタータブ
        _buildFilterTabs(),
        // 報告リスト
        Expanded(
          child: _filteredReports.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReportData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    itemCount: _filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = _filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// フィルタータブ
  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'すべて'),
            const SizedBox(width: AppDimensions.spacingS),
            _buildFilterChip('submitted', '新規'),
            const SizedBox(width: AppDimensions.spacingS),
            _buildFilterChip('reviewing', '確認中'),
            const SizedBox(width: AppDimensions.spacingS),
            _buildFilterChip('resolved', '解決済み'),
            const SizedBox(width: AppDimensions.spacingS),
            _buildFilterChip('rejected', '却下'),
          ],
        ),
      ),
    );
  }

  /// フィルターチップ
  Widget _buildFilterChip(String status, String label) {
    final count = _getStatusCount(status);
    final isSelected = _filterStatus == status;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: AppDimensions.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
    );
  }

  /// 空状態表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_off,
            size: AppDimensions.iconXXL,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            _filterStatus == 'all'
                ? '報告がありません'
                : '該当する報告がありません',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 報告カード
  Widget _buildReportCard(MatchReport report) {
    final matchResult = _matchResultCache[report.matchId];
    final reporter = _userDataCache[report.reporterId];
    final gameUsername = _gameUsernameCache[report.reporterId];

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: InkWell(
        onTap: () => _showReportDetail(report, matchResult),
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
                      color: _getStatusColor(report.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(report.status),
                          size: AppDimensions.iconS,
                          color: _getStatusColor(report.status),
                        ),
                        const SizedBox(width: AppDimensions.spacingXS),
                        Text(
                          report.status.displayName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(report.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateTime(report.createdAt),
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingM),

              // 試合情報
              Row(
                children: [
                  Icon(
                    Icons.sports_esports,
                    size: AppDimensions.iconM,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Text(
                      matchResult?.matchName ?? '試合情報なし',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // 報告タイプ
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: AppDimensions.iconM,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    report.issueType,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // 報告者
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: AppDimensions.iconM,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    '報告者: ${gameUsername ?? reporter?.displayName ?? '不明'}',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // 説明（最初の2行のみ表示）
              if (report.description.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  report.description,
                  maxLines: 2,
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
                        child: Text(
                          '運営対応: ${report.adminResponse}',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
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
  Future<void> _showReportDetail(MatchReport report, MatchResult? matchResult) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportDetailDialog(
        report: report,
        matchResult: matchResult,
        eventId: widget.eventId,
        eventName: widget.eventName,
        onStatusUpdate: () {
          // ステータス更新ダイアログを表示
          _showStatusUpdateDialog(report, matchResult);
        },
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      await _loadReportData();
    }
  }

  /// ステータス更新ダイアログを表示
  Future<void> _showStatusUpdateDialog(MatchReport report, MatchResult? matchResult) async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MatchReportStatusDialog(
        report: report,
        matchResult: matchResult,
        adminId: currentUser.uid,
      ),
    );

    // 更新があった場合はリロード
    if (result == true) {
      Navigator.of(context).pop(true); // 詳細ダイアログも閉じる
      await _loadReportData();
    }
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
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