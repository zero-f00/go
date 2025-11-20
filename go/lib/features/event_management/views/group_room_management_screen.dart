import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';

/// グループ・部屋管理画面
class GroupRoomManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const GroupRoomManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<GroupRoomManagementScreen> createState() =>
      _GroupRoomManagementScreenState();
}

class _GroupRoomManagementScreenState
    extends ConsumerState<GroupRoomManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // グループ管理のサンプルデータ（後でFirestore連携）
  List<EventGroup> _groups = [];
  List<ParticipantInfo> _unassignedParticipants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroupData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    // TODO: 実際のFirestoreからのデータ取得
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _groups = [
        EventGroup(
          id: 'group1',
          name: 'チームA',
          participants: ['user1', 'user2'],
          roomUrl: 'https://discord.gg/teamA',
          communicationTool: 'Discord',
        ),
        EventGroup(
          id: 'group2',
          name: 'チームB',
          participants: ['user3'],
          roomUrl: '',
          communicationTool: 'Teams',
        ),
      ];

      _unassignedParticipants = [
        ParticipantInfo(
          userId: 'user4',
          displayName: '未割り当てユーザー1',
          gameUsername: 'player123',
        ),
        ParticipantInfo(
          userId: 'user5',
          displayName: '未割り当てユーザー2',
          gameUsername: 'gamer456',
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
                title: 'グループ・部屋管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupManagementTab(),
                    _buildRoomAssignmentTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewGroup,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
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
            Icons.event,
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
          Tab(text: 'グループ分け'),
          Tab(text: '部屋割り当て'),
        ],
      ),
    );
  }

  /// グループ管理タブ
  Widget _buildGroupManagementTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_unassignedParticipants.isNotEmpty) ...[
            _buildUnassignedSection(),
            const SizedBox(height: AppDimensions.spacingL),
          ],
          _buildGroupsSection(),
        ],
      ),
    );
  }

  /// 未割り当て参加者セクション
  Widget _buildUnassignedSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_off,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '未割り当て参加者 (${_unassignedParticipants.length})',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ..._unassignedParticipants.map((participant) =>
            _buildParticipantChip(participant, isUnassigned: true)),
        ],
      ),
    );
  }

  /// グループセクション
  Widget _buildGroupsSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'グループ一覧',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Expanded(
            child: ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                return _buildGroupCard(_groups[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// グループカード
  Widget _buildGroupCard(EventGroup group) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleGroupAction(group, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('編集')),
                  const PopupMenuItem(value: 'delete', child: Text('削除')),
                ],
                child: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '参加者: ${group.participants.length}名',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // 参加者チップ表示（簡易版）
          Wrap(
            spacing: AppDimensions.spacingS,
            children: group.participants.map((participantId) =>
              Chip(
                label: Text('User $participantId'),
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: AppColors.accent,
                  fontSize: AppDimensions.fontSizeS,
                ),
              )).toList(),
          ),
        ],
      ),
    );
  }

  /// 参加者チップ
  Widget _buildParticipantChip(ParticipantInfo participant, {bool isUnassigned = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Chip(
        label: Text('${participant.displayName} (@${participant.gameUsername})'),
        backgroundColor: isUnassigned
          ? AppColors.warning.withValues(alpha: 0.1)
          : AppColors.accent.withValues(alpha: 0.1),
        labelStyle: TextStyle(
          color: isUnassigned ? AppColors.warning : AppColors.accent,
          fontSize: AppDimensions.fontSizeS,
        ),
      ),
    );
  }

  /// 部屋割り当てタブ
  Widget _buildRoomAssignmentTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          return _buildRoomAssignmentCard(_groups[index]);
        },
      ),
    );
  }

  /// 部屋割り当てカード
  Widget _buildRoomAssignmentCard(EventGroup group) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildRoomUrlField(group),
          const SizedBox(height: AppDimensions.spacingM),
          _buildCommunicationToolSelector(group),
        ],
      ),
    );
  }

  /// 部屋URL入力フィールド
  Widget _buildRoomUrlField(EventGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '通話ルームURL',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          initialValue: group.roomUrl,
          decoration: InputDecoration(
            hintText: 'https://discord.gg/...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            suffixIcon: Icon(Icons.link, color: AppColors.textSecondary),
          ),
          onChanged: (value) {
            // TODO: 部屋URL更新処理
          },
        ),
      ],
    );
  }

  /// 通話ツール選択
  Widget _buildCommunicationToolSelector(EventGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '通話ツール',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        DropdownButtonFormField<String>(
          initialValue: group.communicationTool,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Discord', child: Text('Discord')),
            DropdownMenuItem(value: 'Teams', child: Text('Microsoft Teams')),
            DropdownMenuItem(value: 'Zoom', child: Text('Zoom')),
            DropdownMenuItem(value: 'Meet', child: Text('Google Meet')),
            DropdownMenuItem(value: 'Other', child: Text('その他')),
          ],
          onChanged: (value) {
            // TODO: 通話ツール更新処理
          },
        ),
      ],
    );
  }

  /// アクション処理
  void _handleGroupAction(EventGroup group, String action) {
    switch (action) {
      case 'edit':
        _editGroup(group);
        break;
      case 'delete':
        _deleteGroup(group);
        break;
    }
  }

  void _createNewGroup() {
    // TODO: 新規グループ作成ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('新規グループ作成（準備中）')),
    );
  }

  void _editGroup(EventGroup group) {
    // TODO: グループ編集ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${group.name}の編集（準備中）')),
    );
  }

  void _deleteGroup(EventGroup group) {
    // TODO: グループ削除確認ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${group.name}の削除（準備中）')),
    );
  }
}

/// グループモデル（簡易版）
class EventGroup {
  final String id;
  final String name;
  final List<String> participants;
  final String roomUrl;
  final String communicationTool;

  EventGroup({
    required this.id,
    required this.name,
    required this.participants,
    required this.roomUrl,
    required this.communicationTool,
  });
}

/// 参加者情報モデル（簡易版）
class ParticipantInfo {
  final String userId;
  final String displayName;
  final String gameUsername;

  ParticipantInfo({
    required this.userId,
    required this.displayName,
    required this.gameUsername,
  });
}