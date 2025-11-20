import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';

/// 戦績・結果管理画面
class ResultManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ResultManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ResultManagementScreen> createState() =>
      _ResultManagementScreenState();
}

class _ResultManagementScreenState
    extends ConsumerState<ResultManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // サンプルデータ（後でFirestore連携）
  List<MatchResult> _matches = [];
  List<ParticipantRanking> _rankings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadResultData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResultData() async {
    // TODO: 実際のFirestoreからのデータ取得
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _matches = [
        MatchResult(
          id: 'match1',
          matchName: '準決勝A',
          participants: ['Player1', 'Player2'],
          winner: 'Player1',
          scores: {'Player1': 100, 'Player2': 85},
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        MatchResult(
          id: 'match2',
          matchName: '決勝戦',
          participants: ['Player1', 'Player3'],
          winner: null,
          scores: {},
          completedAt: null,
        ),
      ];

      _rankings = [
        ParticipantRanking(
          userId: 'user1',
          displayName: 'Player1',
          rank: 1,
          totalScore: 250,
          wins: 3,
          losses: 0,
        ),
        ParticipantRanking(
          userId: 'user2',
          displayName: 'Player2',
          rank: 2,
          totalScore: 200,
          wins: 2,
          losses: 1,
        ),
      ];

      _isLoading = false;
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
                title: '戦績・結果管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMatchResultsTab(),
                    _buildRankingTab(),
                    _buildStatisticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewMatch,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '試合追加',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// イベント情報
  Widget _buildEventInfo() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.leaderboard,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Text(
            widget.eventName,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// タブバー
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppDimensions.fontSizeM,
        ),
        tabs: const [
          Tab(text: '試合結果'),
          Tab(text: 'ランキング'),
          Tab(text: '統計'),
        ],
      ),
    );
  }

  /// 試合結果タブ
  Widget _buildMatchResultsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          return _buildMatchCard(_matches[index]);
        },
      ),
    );
  }

  /// 試合カード
  Widget _buildMatchCard(MatchResult match) {
    final isCompleted = match.winner != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isCompleted
            ? AppColors.success.withValues(alpha: 0.3)
            : AppColors.warning.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.matchName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  isCompleted ? '完了' : '進行中',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          if (isCompleted) ...[
            _buildCompletedMatchContent(match),
          ] else ...[
            _buildInProgressMatchContent(match),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editMatch(match),
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isCompleted ? null : () => _inputResult(match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.input),
                  label: Text(isCompleted ? '結果入力済み' : '結果入力'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 完了した試合のコンテンツ
  Widget _buildCompletedMatchContent(MatchResult match) {
    return Column(
      children: [
        Text(
          '勝者: ${match.winner}',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ...match.scores.entries.map((entry) =>
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key),
              Text(
                '${entry.value}点',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: entry.key == match.winner
                    ? AppColors.success
                    : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (match.completedAt != null) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '完了時間: ${_formatDateTime(match.completedAt!)}',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// 進行中の試合のコンテンツ
  Widget _buildInProgressMatchContent(MatchResult match) {
    return Column(
      children: [
        Text(
          '参加者: ${match.participants.join(' vs ')}',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: AppColors.warning,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '結果入力待ち',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ランキングタブ
  Widget _buildRankingTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _rankings.length,
        itemBuilder: (context, index) {
          return _buildRankingCard(_rankings[index]);
        },
      ),
    );
  }

  /// ランキングカード
  Widget _buildRankingCard(ParticipantRanking ranking) {
    Color rankColor;
    IconData rankIcon;

    switch (ranking.rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // ゴールド
        rankIcon = Icons.looks_one;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // シルバー
        rankIcon = Icons.looks_two;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // ブロンズ
        rankIcon = Icons.looks_3;
        break;
      default:
        rankColor = AppColors.textSecondary;
        rankIcon = Icons.person;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: ranking.rank <= 3
          ? Border.all(color: rankColor.withValues(alpha: 0.3))
          : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              rankIcon,
              color: rankColor,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ranking.rank}位',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: rankColor,
                  ),
                ),
                Text(
                  ranking.displayName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  '${ranking.wins}勝 ${ranking.losses}敗',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ranking.totalScore}',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'ポイント',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 統計タブ
  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildStatCard('総試合数', '${_matches.length}'),
          _buildStatCard('完了試合', '${_matches.where((m) => m.winner != null).length}'),
          _buildStatCard('参加者数', '${_rankings.length}'),
          _buildStatCard('平均スコア', _calculateAverageScore()),
        ],
      ),
    );
  }

  /// 統計カード
  Widget _buildStatCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  /// ヘルパーメソッド
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _calculateAverageScore() {
    if (_rankings.isEmpty) return '0';
    final total = _rankings.fold<double>(0, (sum, ranking) => sum + ranking.totalScore);
    return (total / _rankings.length).toStringAsFixed(1);
  }

  /// アクションメソッド
  void _addNewMatch() {
    // TODO: 新規試合追加ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('新規試合追加（準備中）')),
    );
  }

  void _editMatch(MatchResult match) {
    // TODO: 試合編集ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${match.matchName}の編集（準備中）')),
    );
  }

  void _inputResult(MatchResult match) {
    // TODO: 結果入力ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${match.matchName}の結果入力（準備中）')),
    );
  }
}

/// 試合結果モデル
class MatchResult {
  final String id;
  final String matchName;
  final List<String> participants;
  final String? winner;
  final Map<String, int> scores;
  final DateTime? completedAt;

  MatchResult({
    required this.id,
    required this.matchName,
    required this.participants,
    this.winner,
    required this.scores,
    this.completedAt,
  });
}

/// 参加者ランキングモデル
class ParticipantRanking {
  final String userId;
  final String displayName;
  final int rank;
  final double totalScore;
  final int wins;
  final int losses;

  ParticipantRanking({
    required this.userId,
    required this.displayName,
    required this.rank,
    required this.totalScore,
    required this.wins,
    required this.losses,
  });
}