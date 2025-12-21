import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/match_result_service.dart';
import '../../../shared/services/group_management_service.dart';
import '../../../shared/services/participation_service.dart';
import 'participant_match_detail_screen.dart';

/// 参加者向け戦績・結果確認画面
class ParticipantMatchResultsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ParticipantMatchResultsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ParticipantMatchResultsScreen> createState() =>
      _ParticipantMatchResultsScreenState();
}

class _ParticipantMatchResultsScreenState
    extends ConsumerState<ParticipantMatchResultsScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  List<MatchResult> _allMatches = [];
  List<MatchResult> _myMatches = [];

  bool _isLoading = true;
  bool _isTeamEvent = false;
  String? _currentUserId;
  String? _currentUserTeamId;
  Map<String, String> _participantNames = {};

  final MatchResultService _matchResultService = MatchResultService();
  final GroupManagementService _groupService = GroupManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// データを読み込み
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 現在のユーザーを取得
      final currentUser = ref.read(currentFirebaseUserProvider);
      _currentUserId = currentUser?.uid;

      if (_currentUserId == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // イベントタイプを確認
      _isTeamEvent = await _groupService.isTeamMatchEvent(widget.eventId);

      // 参加者名を読み込み
      await _loadParticipantNames();

      // 現在のユーザーのチーム情報を取得（チーム戦の場合）
      if (_isTeamEvent) {
        _currentUserTeamId = await _getCurrentUserTeam();
      }

      // 試合データを読み込み
      _allMatches = await _matchResultService.getMatchResultsByEventId(widget.eventId);

      // 自分の試合をフィルタリング
      _myMatches = _allMatches.where((match) {
        if (_isTeamEvent && _currentUserTeamId != null) {
          return match.participants.contains(_currentUserTeamId!);
        } else {
          return match.participants.contains(_currentUserId!);
        }
      }).toList();


      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データの読み込みに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 参加者名を読み込み
  Future<void> _loadParticipantNames() async {
    try {
      if (_isTeamEvent) {
        // チーム戦：グループ名を取得
        final groupIds = await _groupService.getEventGroupIds(widget.eventId);
        _participantNames = await _groupService.getGroupNames(groupIds);

        // チームメンバー名も取得
        for (final groupId in groupIds) {
          final memberIds = await _groupService.getGroupMembers(groupId);
          final memberInfo = await _groupService.getApprovedParticipantNames(
            widget.eventId, memberIds
          );

          for (final entry in memberInfo.entries) {
            _participantNames[entry.key] =
                entry.value['gameUsername'] ?? entry.value['displayName'] ?? 'ユーザー';
          }
        }
      } else {
        // 個人戦：参加者名を取得
        final applications = await ParticipationService.getEventApplications(widget.eventId).first;
        final approvedParticipants = applications
            .where((app) => app.status == ParticipationStatus.approved)
            .toList();

        for (final app in approvedParticipants) {
          _participantNames[app.userId] = app.gameUsername ?? app.userDisplayName;
        }
      }
    } catch (e) {
      // エラーが発生した場合は参加者名が空のまま継続
    }
  }

  /// 現在のユーザーのチームIDを取得
  Future<String?> _getCurrentUserTeam() async {
    try {
      final groupIds = await _groupService.getEventGroupIds(widget.eventId);

      for (final groupId in groupIds) {
        final members = await _groupService.getGroupMembers(groupId);
        if (members.contains(_currentUserId!)) {
          return groupId;
        }
      }
      return null;
    } catch (e) {
      return null;
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
                title: '戦績・結果確認',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                iconData: Icons.sports_esports,
                trailing: _isLoading
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Text(
                        _isTeamEvent ? 'チーム戦' : '個人戦',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ),
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.analytics,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            const Text(
                              '試合結果',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textDark,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppDimensions.fontSizeM,
                          ),
                          tabs: const [
                            Tab(text: 'すべての試合'),
                            Tab(text: '自分の試合'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildAllMatchesTab(),
                                _buildMyMatchesTab(),
                              ],
                            ),
                      ),
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


  /// すべての試合タブ
  Widget _buildAllMatchesTab() {
    if (_allMatches.isEmpty) {
      return _buildEmptyState('まだ試合が登録されていません');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      itemCount: _allMatches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(_allMatches[index], isMyMatch: false);
      },
    );
  }

  /// 自分の試合タブ
  Widget _buildMyMatchesTab() {
    if (_myMatches.isEmpty) {
      return _buildEmptyState('あなたが参加した試合はありません');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      itemCount: _myMatches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(_myMatches[index], isMyMatch: true);
      },
    );
  }


  /// 空の状態
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 試合カード
  Widget _buildMatchCard(MatchResult match, {required bool isMyMatch}) {
    return GestureDetector(
      onTap: () => _navigateToMatchDetail(match),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: isMyMatch ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isMyMatch ? AppColors.accent : AppColors.border,
            width: isMyMatch ? 2 : 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              // ステータスバッジ
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
                      match.status.displayName,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(match.status),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 日時
              Text(
                _formatDateTime(match.createdAt),
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
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
          ),
          const SizedBox(height: AppDimensions.spacingS),

          // 参加者
          Text(
            _formatParticipants(match.participants),
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // 結果（完了時のみ）
          if (match.isCompleted) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 勝者
                  if (match.winner != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: AppColors.warning,
                          size: AppDimensions.iconS,
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Text(
                          '勝者: ${_participantNames[match.winner] ?? match.winner}',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    if (match.scores.isNotEmpty) const SizedBox(height: AppDimensions.spacingS),
                  ],

                  // スコア
                  if (match.scores.isNotEmpty) ...[
                    Text(
                      'スコア',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    ...match.scores.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _participantNames[entry.key] ?? entry.key,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${entry.value}${match.scoreUnit ?? '点'}',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              fontWeight: FontWeight.w600,
                              color: entry.key == match.winner
                                  ? AppColors.success
                                  : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    )),
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

  /// 試合詳細画面へ遷移
  void _navigateToMatchDetail(MatchResult match) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantMatchDetailScreen(
          match: match,
          participantNames: _participantNames,
          isTeamEvent: _isTeamEvent,
          currentUserId: _currentUserId,
          currentUserTeamId: _currentUserTeamId,
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );
  }

  /// ステータスの色を取得
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

  /// ステータスのアイコンを取得
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


  /// 参加者表示をフォーマット
  String _formatParticipants(List<String> participants) {
    final names = participants.map((id) => _participantNames[id] ?? id).toList();

    if (names.length <= 2) {
      // 2人以下の場合は従来の「vs」形式
      return names.join(' vs ');
    } else if (names.length <= 4) {
      // 3-4人の場合は改行区切り
      return names.join(' • ');
    } else {
      // 5人以上の場合は省略形式
      return '${names.take(3).join(' • ')} 他${names.length - 3}名';
    }
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}