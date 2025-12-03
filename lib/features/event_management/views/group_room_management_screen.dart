import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/widgets/group_memo_widget.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/event_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/widgets/user_avatar_from_id.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/event_group_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// グループ管理画面
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
    extends ConsumerState<GroupRoomManagementScreen> {
  // グループ管理データ
  List<EventGroup> _groups = [];
  List<ApprovedParticipant> _unassignedParticipants = [];
  List<ApprovedParticipant> _allApprovedParticipants = []; // 全ての承認済み参加者
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = true;
  String _commonDescription = ''; // 共通説明
  String? _gameId; // イベントに紐づくゲームID
  Set<String> _expandedAnnouncements = {}; // 展開されたグループ連絡事項のID

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      // イベント情報を取得してゲームIDを設定
      final event = await EventService.getEventById(widget.eventId);
      if (event != null) {
        setState(() {
          _gameId = event.gameId;
        });
      }

      // 承認済みの参加申請を取得
      final applications = await ParticipationService.getEventApplications(
        widget.eventId,
      ).first;
      final approvedApplications = applications
          .where((app) => app.status == ParticipationStatus.approved)
          .toList();

      // 承認済みユーザーの詳細情報を取得
      final List<ApprovedParticipant> approvedParticipants = [];
      for (final app in approvedApplications) {
        final userData = await _userRepository.getUserById(app.userId);
        if (userData != null) {
          approvedParticipants.add(
            ApprovedParticipant(
              userId: app.userId,
              displayName: userData.displayName,
              gameUsername: app.gameUsername ?? userData.userId,
              gameProfileData: app.gameProfileData,
              application: app,
            ),
          );
        }
      }

      // 既存のグループ情報をFirestoreから取得
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('event_groups')
          .where('eventId', isEqualTo: widget.eventId)
          .get();

      final List<EventGroup> loadedGroups = [];
      final Set<String> assignedParticipants = {};

      for (final doc in groupsSnapshot.docs) {
        final group = EventGroup.fromFirestore(doc);
        loadedGroups.add(group);
        assignedParticipants.addAll(group.participants);
      }

      // 共通説明を取得
      final commonDescDoc = await FirebaseFirestore.instance
          .collection('event_group_settings')
          .doc(widget.eventId)
          .get();

      String commonDesc = '';
      if (commonDescDoc.exists) {
        commonDesc = commonDescDoc.data()?['commonDescription'] ?? '';
      }

      // 未割り当てユーザーを特定
      final unassigned = approvedParticipants
          .where(
            (participant) => !assignedParticipants.contains(participant.userId),
          )
          .toList();

      setState(() {
        _groups = loadedGroups;
        _unassignedParticipants = unassigned;
        _allApprovedParticipants = approvedParticipants;
        _commonDescription = commonDesc;
        _isLoading = false;
      });
    } catch (e) {
      print('グループデータ読み込みエラー: $e');
      setState(() {
        _isLoading = false;
      });
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
                title: 'グループ管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    onPressed: _editGeneralAnnouncements,
                    tooltip: '全体連絡事項を編集',
                  ),
                ],
              ),
              Expanded(child: _buildGroupManagementTab()),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(
          right: AppDimensions.spacingM,
          bottom: AppDimensions.spacingM,
        ),
        child: FloatingActionButton.extended(
          onPressed: _createNewGroup,
          backgroundColor: AppColors.accent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'グループ作成',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
    );
  }

  /// グループ管理タブ
  Widget _buildGroupManagementTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // グループが存在しない場合
    if (_groups.isEmpty) {
      return _buildEmptyState();
    }

    // グループが存在する場合は通常のListViewを表示
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      children: [
        // 共通説明表示
        if (_commonDescription.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1,
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
                    Icon(
                      Icons.campaign,
                      color: AppColors.primary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      '全体連絡事項',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '全参加者が閲覧可能',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeXS,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  _commonDescription,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 未割り当て参加者セクション
        if (_unassignedParticipants.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildUnassignedSection(),
          ),
        ],

        // グループセクション
        ..._buildGroupsList(),
      ],
    );
  }

  /// 空の状態を表示
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          // 空の状態のメインコンテナ
          Expanded(
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
                  Icon(
                    Icons.group_add,
                    size: 80,
                    color: AppColors.textDark.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  Text(
                    'まだグループがありません',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'チーム戦を開催するために\nグループ（チーム）を作成しましょう',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXL),

                  // 未割り当て参加者がいる場合の警告表示
                  if (_unassignedParticipants.isNotEmpty) ...[
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
                                  '${_unassignedParticipants.length}名の承認済み参加者が\nグループ未割り当てです',
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
                          TextButton.icon(
                            onPressed: _showUnassignedParticipantsDialog,
                            icon: Icon(Icons.visibility, color: AppColors.accent),
                            label: Text(
                              '未割り当て参加者を確認',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  /// 未割り当て参加者セクション
  Widget _buildUnassignedSection() {
    return Column(
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
        ..._unassignedParticipants.map(
          (participant) =>
              _buildParticipantChip(participant, isUnassigned: true),
        ),
      ],
    );
  }

  /// グループリストを構築
  List<Widget> _buildGroupsList() {

    return _groups
        .map(
          (group) => Container(
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
            child: _buildGroupCard(group),
          ),
        )
        .toList();
  }

  /// グループカード
  Widget _buildGroupCard(EventGroup group) {
    // グループに所属する参加者の詳細情報を取得
    final groupParticipants = _getAllParticipants()
        .where((participant) => group.participants.contains(participant.userId))
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
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
          // グループヘッダー
          Row(
            children: [
              Icon(
                Icons.group,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
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
                  const PopupMenuItem(
                    value: 'add_member',
                    child: Text('メンバー追加'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('削除')),
                ],
                child: Icon(Icons.more_vert, color: AppColors.textSecondary),
              ),
            ],
          ),

          // グループ説明
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'グループ説明:',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    group.description,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // グループ連絡事項
          if (group.announcements.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        color: AppColors.accent,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      const Text(
                        'グループ連絡事項:',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  _buildAnnouncementsText(group.announcements, group.id),
                ],
              ),
            ),
          ],

          // 管理者専用グループメモ
          GroupMemoWidget(
            eventId: widget.eventId,
            groupId: group.id,
            groupName: group.name,
            currentUserId: ref.read(currentFirebaseUserProvider)?.uid,
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // 参加者数
          Text(
            '参加者: ${group.participants.length}名',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: AppDimensions.spacingM),

          // 参加者一覧
          if (groupParticipants.isNotEmpty) ...[
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingS,
              children: groupParticipants
                  .map(
                    (participant) =>
                        _buildParticipantChip(participant, isUnassigned: false),
                  )
                  .toList(),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add,
                    color: AppColors.warning,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    'メンバーがいません',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    'メニューからメンバーを追加してください',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 参加者チップ
  Widget _buildParticipantChip(
    ApprovedParticipant participant, {
    bool isUnassigned = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: InkWell(
        onTap: () => _showParticipantActions(participant),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: isUnassigned
                ? AppColors.warning.withValues(alpha: 0.1)
                : AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: isUnassigned
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ユーザーアイコンを追加
              GestureDetector(
                onTap: () => _showParticipantActions(participant),
                child: UserAvatarFromId(
                  userId: participant.userId,
                  size: 28,
                  backgroundColor: isUnassigned
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : AppColors.accent.withValues(alpha: 0.15),
                  iconColor: isUnassigned
                      ? AppColors.warning
                      : AppColors.accent,
                  borderColor: isUnassigned
                      ? AppColors.warning.withValues(alpha: 0.3)
                      : AppColors.accent.withValues(alpha: 0.3),
                  borderWidth: 1,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      participant.gameUsername,
                      style: TextStyle(
                        color: isUnassigned
                            ? AppColors.warning
                            : AppColors.accent,
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      participant.displayName,
                      style: TextStyle(
                        color: isUnassigned
                            ? AppColors.warning.withValues(alpha: 0.8)
                            : AppColors.accent.withValues(alpha: 0.8),
                        fontSize: AppDimensions.fontSizeXS,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (!isUnassigned) ...[
                const SizedBox(width: AppDimensions.spacingS),
                InkWell(
                  onTap: () => _removeParticipantFromGroup(participant),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: Icon(
                    Icons.close,
                    size: AppDimensions.iconS,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 全参加者を取得（割り当て済み + 未割り当て）
  List<ApprovedParticipant> _getAllParticipants() {
    return _allApprovedParticipants;
  }

  /// 参加者アクションダイアログを表示
  void _showParticipantActions(ApprovedParticipant participant) {
    final isUnassigned = _unassignedParticipants.contains(participant);

    List<Widget> additionalActions = [];
    if (isUnassigned && _groups.isNotEmpty) {
      additionalActions.add(
        AppButton.primary(
          text: 'グループに追加',
          icon: Icons.group_add,
          onPressed: () {
            Navigator.pop(context);
            _showGroupSelectionDialog(participant);
          },
          isFullWidth: true,
        ),
      );
    }

    UserActionModal.show(
      context: context,
      eventId: widget.eventId,
      userId: participant.userId,
      userName: participant.gameUsername,
      gameUsername: participant.gameUsername,
      onGameProfileTap: () => _navigateToGameProfile(participant),
      onUserProfileTap: () => _navigateToUserProfile(participant),
      additionalActions: additionalActions,
    );
  }

  /// グループ選択ダイアログを表示
  void _showGroupSelectionDialog(ApprovedParticipant participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            UserAvatarFromId(
              userId: participant.userId,
              size: 32,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              iconColor: AppColors.accent,
              borderColor: AppColors.accent.withValues(alpha: 0.3),
              borderWidth: 1,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(child: Text('${participant.gameUsername}を追加するグループ')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _groups
              .map(
                (group) => ListTile(
                  leading: Icon(Icons.group, color: AppColors.accent),
                  title: Text(group.name),
                  subtitle: Text('${group.participants.length}人'),
                  onTap: () {
                    Navigator.pop(context);
                    _addParticipantToGroup(participant, group);
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  /// 参加者をグループから削除
  Future<void> _removeParticipantFromGroup(
    ApprovedParticipant participant,
  ) async {
    try {
      // Firestoreから参加者を削除
      final groupToUpdate = _groups.firstWhere(
        (group) => group.participants.contains(participant.userId),
      );

      await FirebaseFirestore.instance
          .collection('event_groups')
          .doc(groupToUpdate.id)
          .update({
            'participants': FieldValue.arrayRemove([participant.userId]),
          });

      _loadGroupData(); // データ再読み込み

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${participant.gameUsername}を${groupToUpdate.name}から削除しました',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('参加者の削除に失敗しました')));
    }
  }

  /// 参加者をグループに追加
  Future<void> _addParticipantToGroup(
    ApprovedParticipant participant,
    EventGroup group,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('event_groups')
          .doc(group.id)
          .update({
            'participants': FieldValue.arrayUnion([participant.userId]),
          });

      _loadGroupData(); // データ再読み込み

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${participant.gameUsername}を${group.name}に追加しました'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('参加者の追加に失敗しました')));
    }
  }

  /// アクション処理
  void _handleGroupAction(EventGroup group, String action) {
    switch (action) {
      case 'edit':
        _editGroup(group);
        break;
      case 'add_member':
        if (_unassignedParticipants.isNotEmpty) {
          _showGroupMemberSelectionDialog(group);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('追加できる参加者がいません')));
        }
        break;
      case 'delete':
        _deleteGroup(group);
        break;
    }
  }

  /// グループメンバー選択ダイアログ
  void _showGroupMemberSelectionDialog(EventGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${group.name}にメンバーを追加'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _unassignedParticipants.length,
            itemBuilder: (context, index) {
              final participant = _unassignedParticipants[index];
              return ListTile(
                leading: UserAvatarFromId(
                  userId: participant.userId,
                  size: 40,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  iconColor: AppColors.accent,
                  borderColor: AppColors.accent.withValues(alpha: 0.3),
                  borderWidth: 1,
                ),
                title: Text(participant.gameUsername),
                subtitle: Text(participant.displayName),
                onTap: () {
                  Navigator.pop(context);
                  _addParticipantToGroup(participant, group);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _createNewGroup() {
    _showCreateGroupDialog();
  }

  /// 全体連絡事項を編集
  void _editGeneralAnnouncements() {
    _showGeneralAnnouncementsDialog();
  }

  /// 全体連絡事項を更新
  Future<void> _updateGeneralAnnouncements(String announcements) async {
    try {
      print('Updating general announcements for event: ${widget.eventId}');

      await FirebaseFirestore.instance
          .collection('event_group_settings')
          .doc(widget.eventId)
          .set({
            'commonDescription': announcements.trim(),
            'updatedAt': Timestamp.now(),
          }, SetOptions(merge: true));

      setState(() {
        _commonDescription = announcements.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('全体連絡事項を更新しました'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error updating general announcements: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('全体連絡事項の更新に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 全体連絡事項編集ダイアログ
  void _showGeneralAnnouncementsDialog() {
    final announcementsController = TextEditingController(
      text: _commonDescription,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.campaign, color: AppColors.primary),
            SizedBox(width: AppDimensions.spacingS),
            Text('全体連絡事項の編集'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'イベントに参加するすべてのユーザーが閲覧できる連絡事項を設定してください。',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: announcementsController,
                decoration: const InputDecoration(
                  labelText: '全体連絡事項',
                  helperText: '全参加者が閲覧可能',
                  hintText: '例：イベント開始時刻が30分変更になりました',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          AppButton.primary(
            text: '保存',
            onPressed: () {
              Navigator.pop(context);
              _updateGeneralAnnouncements(announcementsController.text);
            },
          ),
        ],
      ),
    );
  }

  /// 新規グループ作成ダイアログ
  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいグループを作成'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                hintText: '例：チームA',
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'グループ説明（任意）',
                hintText: '例：攻撃担当のメンバー',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          AppButton.primary(
            text: '作成',
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _createGroup(nameController.text, descriptionController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  /// グループを作成
  Future<void> _createGroup(String name, String description) async {
    try {
      // 入力値の検証
      if (name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('グループ名を入力してください'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      print('Creating group: $name for event: ${widget.eventId}');

      final newGroup = EventGroup(
        id: '',
        eventId: widget.eventId,
        name: name.trim(),
        description: description.trim(),
        participants: <String>[],
        announcements: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final groupId = await GroupService.createGroup(newGroup);

      if (groupId != null) {
        print('Group created successfully with ID: $groupId');
        // データ再読み込み
        await _loadGroupData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('グループ「$name」を作成しました'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('グループの作成に失敗しました');
      }
    } catch (e, stackTrace) {
      print('Error creating group: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループの作成に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editGroup(EventGroup group) {
    _showEditGroupDialog(group);
  }

  /// グループ編集ダイアログ
  void _showEditGroupDialog(EventGroup group) {
    final nameController = TextEditingController(text: group.name);
    final descriptionController = TextEditingController(
      text: group.description,
    );
    final announcementsController = TextEditingController(
      text: group.announcements,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'グループ名'),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'グループ説明（任意）'),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: announcementsController,
                decoration: const InputDecoration(
                  labelText: 'グループ連絡事項',
                  helperText: 'メンバーのみ閲覧可能',
                  hintText: '例：次回の練習は19時からです',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          AppButton.primary(
            text: '更新',
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context);
                _updateGroup(
                  group,
                  nameController.text,
                  descriptionController.text,
                  announcementsController.text,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// グループを更新
  Future<void> _updateGroup(
    EventGroup group,
    String name,
    String description,
    String announcements,
  ) async {
    try {
      final updatedGroup = group.copyWith(
        name: name.trim(),
        description: description.trim(),
        announcements: announcements.trim(),
        updatedAt: DateTime.now(),
      );

      final success = await GroupService.updateGroup(updatedGroup);

      if (success) {
        await _loadGroupData(); // データ再読み込み

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('グループ「$name」を更新しました'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception('グループの更新に失敗しました');
      }
    } catch (e, stackTrace) {
      print('Error updating group: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('グループの更新に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _deleteGroup(EventGroup group) {
    _checkGroupDeletion(group);
  }

  /// グループ削除前のチェック処理
  Future<void> _checkGroupDeletion(EventGroup group) async {
    final canDelete = await GroupService.canDeleteGroup(group.id);

    if (!canDelete) {
      final matchCount = await GroupService.getRelatedMatchCount(group.id);
      _showCannotDeleteDialog(group, matchCount);
    } else {
      _showDeleteConfirmDialog(group);
    }
  }

  /// 削除不可ダイアログ表示
  void _showCannotDeleteDialog(EventGroup group, int matchCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除できません'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('「${group.name}」は${matchCount}件の戦績データに関連付けられています。'),
            const SizedBox(height: AppDimensions.spacingM),
            const Text(
              '戦績データを保護するため、関連する戦績があるグループは削除できません。',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            const Text(
              'どうしても削除が必要な場合は、先に関連する戦績データを個別に削除してください。',
              style: TextStyle(fontSize: AppDimensions.fontSizeS),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
          AppButton.secondary(
            text: '戦績管理へ',
            onPressed: () {
              Navigator.pop(context);
              _navigateToMatchResultManagement();
            },
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログ表示
  void _showDeleteConfirmDialog(EventGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除'),
        content: Text('「${group.name}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          AppButton.danger(
            text: '削除',
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteGroup(group);
            },
          ),
        ],
      ),
    );
  }

  /// グループ削除確認
  Future<void> _confirmDeleteGroup(EventGroup group) async {
    try {
      final success = await GroupService.deleteGroup(group.id);

      if (success) {
        _loadGroupData(); // データ再読み込み

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('グループ「${group.name}」を削除しました')));
      } else {
        throw Exception('グループの削除に失敗しました');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('グループの削除に失敗しました')));
    }
  }

  /// ゲームプロフィール画面に遷移
  Future<void> _navigateToGameProfile(ApprovedParticipant participant) async {
    if (_gameId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ゲーム情報が見つかりません')));
      return;
    }

    try {
      // ユーザーデータを取得
      final userData = await _userRepository.getUserById(participant.userId);

      // GameProfileオブジェクトを作成
      final gameProfile = GameProfile(
        id: '${participant.userId}_$_gameId',
        userId: participant.userId,
        gameId: _gameId!,
        gameUsername: participant.gameUsername,
        gameUserId:
            participant.gameProfileData?['gameUserId']?.toString() ??
            participant.gameUsername,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // 参加申請のゲームプロフィールデータがある場合は使用
        rankOrLevel:
            participant.gameProfileData?['rank']?.toString() ??
            participant.gameProfileData?['level']?.toString() ??
            '',
        achievements:
            participant.gameProfileData?['achievements']?.toString() ?? '',
        notes: participant.gameProfileData?['description']?.toString() ?? '',
        experience: _parseGameExperience(
          participant.gameProfileData?['experienceLevel']?.toString(),
        ),
        playStyles: _parsePlayStyles(
          participant.gameProfileData?['preferredRole']?.toString(),
        ),
        isPublic: true,
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/game_profile_view',
          arguments: {
            'profile': gameProfile,
            'userData': userData,
            'gameName': null, // 必要に応じてゲーム情報も取得可能
            'gameIconUrl': null, // 必要に応じてゲーム情報も取得可能
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ゲームプロフィールの表示に失敗しました')));
      }
    }
  }

  /// ユーザープロフィール画面に遷移
  void _navigateToUserProfile(ApprovedParticipant participant) {
    Navigator.pushNamed(
      context,
      '/user_profile',
      arguments: {'userId': participant.userId},
    );
  }

  /// 経験レベル文字列をGameExperienceに変換
  GameExperience? _parseGameExperience(String? experienceStr) {
    if (experienceStr == null) return null;
    switch (experienceStr.toLowerCase()) {
      case 'beginner':
      case '初心者':
        return GameExperience.beginner;
      case 'intermediate':
      case '中級者':
        return GameExperience.intermediate;
      case 'advanced':
      case '上級者':
        return GameExperience.advanced;
      case 'expert':
      case 'pro':
      case 'プロ':
        return GameExperience.expert;
      default:
        return GameExperience.intermediate; // デフォルト
    }
  }

  /// ロール文字列をPlayStylesに変換
  List<PlayStyle> _parsePlayStyles(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) return [];

    // 基本的なロールマッピング（ゲームによって異なるため、簡単な例）
    switch (roleStr.toLowerCase()) {
      case 'tank':
      case 'タンク':
      case 'defensive':
        return [PlayStyle.competitive]; // 競技志向として扱う
      case 'dps':
      case 'damage':
      case 'アタッカー':
      case 'aggressive':
        return [PlayStyle.competitive]; // 競技志向として扱う
      case 'support':
      case 'サポート':
      case 'supportive':
        return [PlayStyle.cooperative]; // 協力プレイとして扱う
      case 'healer':
      case 'ヒーラー':
        return [PlayStyle.cooperative]; // 協力プレイとして扱う
      case 'casual':
      case 'カジュアル':
        return [PlayStyle.casual];
      case 'social':
      case 'ソーシャル':
      case '交流':
        return [PlayStyle.social];
      default:
        return [PlayStyle.casual]; // デフォルト
    }
  }

  /// 連絡事項テキストを展開可能な形で表示
  Widget _buildAnnouncementsText(String announcements, String groupId) {
    if (announcements.isEmpty) {
      return const SizedBox.shrink();
    }
    final isExpanded = _expandedAnnouncements.contains(groupId);
    const maxLines = 3;

    // テキストが短い場合は通常表示
    if (announcements.length <= 100) {
      return Text(
        announcements,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeS,
          color: AppColors.textDark,
          height: 1.4,
        ),
        softWrap: true,
      );
    }

    // 長いテキストの場合は展開/折りたたみ機能付き
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          announcements,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textDark,
            height: 1.4,
          ),
          maxLines: isExpanded ? null : maxLines,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          softWrap: true,
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedAnnouncements.remove(groupId);
              } else {
                _expandedAnnouncements.add(groupId);
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: AppDimensions.iconS,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              Text(
                isExpanded ? '折りたたむ' : 'もっと見る',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 未割り当て参加者ダイアログを表示
  void _showUnassignedParticipantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_off, color: AppColors.warning),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('未割り当て参加者'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '承認済みでグループに割り当てられていない参加者：',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _unassignedParticipants.length,
                  itemBuilder: (context, index) {
                    final participant = _unassignedParticipants[index];
                    return InkWell(
                      onTap: () => _showParticipantActions(participant),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            UserAvatarFromId(
                              userId: participant.userId,
                              size: 40,
                              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                              iconColor: AppColors.warning,
                              borderColor: AppColors.warning.withValues(alpha: 0.3),
                              borderWidth: 1,
                            ),
                            const SizedBox(width: AppDimensions.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    participant.gameUsername,
                                    style: const TextStyle(
                                      fontSize: AppDimensions.fontSizeM,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spacingXS),
                                  Text(
                                    participant.displayName,
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeS,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.info,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        'グループを作成してこれらの参加者を割り当ててください',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          AppButton.primary(
            text: 'グループ作成',
            icon: Icons.add,
            onPressed: () {
              Navigator.of(context).pop();
              _createNewGroup();
            },
          ),
        ],
      ),
    );
  }

  /// 戦績管理画面へ遷移
  void _navigateToMatchResultManagement() {
    Navigator.of(context).pushNamed(
      '/result_management',
      arguments: {
        'eventId': widget.eventId,
        'eventName': widget.eventName,
      },
    );
  }

  /// 削除制限バッジウィジェット
  Widget _buildDeletionRestrictionBadge(EventGroup group) {
    return FutureBuilder<bool>(
      future: GroupService.canDeleteGroup(group.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == false) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingXS,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: AppColors.warning,
                ),
                SizedBox(width: AppDimensions.spacingXS),
                Text(
                  '戦績あり',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

