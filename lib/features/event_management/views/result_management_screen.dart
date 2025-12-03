import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/services/match_result_service.dart';
import '../../../shared/services/group_management_service.dart';
import '../../../shared/services/participation_service.dart';
import '../widgets/match_registration_dialog.dart';
import 'match_result_input_screen.dart';
import 'match_detail_screen.dart';
import 'group_room_management_screen.dart';
import 'event_participants_management_screen.dart';

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
    extends ConsumerState<ResultManagementScreen> {

  List<MatchResult> _matches = [];

  bool _isLoading = true;
  bool _isTeamEvent = false;
  List<String> _participants = []; // グループIDまたはユーザーID
  Map<String, String> _participantNames = {}; // participantId -> 表示名
  final MatchResultService _matchResultService = MatchResultService();
  final GroupManagementService _groupService = GroupManagementService();

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
        // 個人戦の場合：承認済み参加者を取得
        final applications = await ParticipationService.getEventApplications(widget.eventId).first;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('参加者の読み込みに失敗しました: $e')),
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
        for (final entry in participantInfo.entries) {
          final userId = entry.key;
          final info = entry.value;
          _participantNames[userId] = info['gameUsername'] ?? info['displayName'] ?? 'ユーザー';
        }
      }
    } catch (e) {
      print('チームメンバー名の取得エラー: $e');
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

      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
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
                title: '試合結果管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
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
                              '試合結果管理',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
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
                label: const Text(
                  '試合追加',
                  style: TextStyle(
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
            color: AppColors.cardShadow,
            blurRadius: AppDimensions.cardElevation,
            offset: const Offset(0, AppDimensions.shadowOffsetY),
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


  /// 試合結果タブ
  Widget _buildMatchResultsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_matches.isEmpty) {
      return _buildEmptyMatchesState();
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

  /// 試合データが空の場合の表示
  Widget _buildEmptyMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 80,
              color: AppColors.textDark.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Text(
              'まだ試合が登録されていません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              _isTeamEvent
                  ? 'チーム（グループ）対戦の試合結果を記録して\n管理しましょう'
                  : '参加者同士の個人戦の試合結果を記録して\n管理しましょう',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
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
                                ? '試合を開催するには2つ以上のチーム（グループ）が必要です'
                                : '試合を開催するには2人以上の参加者が必要です',
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
                        'チーム戦を開催するには事前にグループの作成が必要です',
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
                        label: const Text(
                          'グループ管理画面へ',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'イベントに参加者を追加してから試合を開始できます',
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
                        label: const Text(
                          '参加者管理画面へ',
                          style: TextStyle(
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
                  Column(
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
                    ],
                  ),
                  const Spacer(),
                  // アクションボタン
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMatchAction(match, value),
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
                      '勝者: ${_participantNames[match.winner] ?? match.winner}',
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
                      label: Text(match.isCompleted ? '結果編集' : '結果入力'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  OutlinedButton(
                    onPressed: () => _navigateToMatchDetail(match),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: const Text('詳細'),
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
    if (_participants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTeamEvent
              ? '試合を開催するには2つ以上のチーム（グループ）が必要です'
              : '試合を開催するには2人以上の参加者が必要です'),
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
    try {
      await _matchResultService.createMatchResult(match);

      // データを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合「${match.matchName}」を登録しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合の登録に失敗しました: $e'),
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
    try {
      await _matchResultService.updateMatchResult(updatedMatch);

      // データを再読み込み
      await _loadResultData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('試合結果を保存しました'),
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

  /// ステータス変更ダイアログを表示
  void _showStatusChangeDialog(MatchResult match) {
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
            Text('「${match.matchName}」のステータスを選択してください'),
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
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// ステータス変更処理
  Future<void> _changeMatchStatus(MatchResult match, MatchStatus newStatus) async {
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

  /// 試合アクション処理
  void _handleMatchAction(MatchResult match, String action) {
    switch (action) {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: AppDimensions.spacingS),
            Text('試合削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${match.matchName}」を削除しますか？'),
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
              _deleteMatch(match);
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

  /// 試合を削除
  Future<void> _deleteMatch(MatchResult match) async {
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
            content: Text('試合「${match.matchName}」を削除しました'),
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
            content: Text('試合の削除に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}

