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
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../shared/widgets/marquee_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart';

/// グループ管理画面
class GroupRoomManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;

  const GroupRoomManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
  });

  @override
  ConsumerState<GroupRoomManagementScreen> createState() =>
      _GroupRoomManagementScreenState();
}

class _GroupRoomManagementScreenState
    extends ConsumerState<GroupRoomManagementScreen> with TickerProviderStateMixin {
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
      final applications = await ParticipationService.getEventApplicationsFromServer(
        widget.eventId,
        forceFromServer: true,
      );
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
      setState(() {
        _isLoading = false;
      });
    }
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
                title: l10n.groupTitle,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    onPressed: _editGeneralAnnouncements,
                    tooltip: l10n.editGeneralAnnouncementsTooltip,
                  ),
                ],
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                enableTap: widget.fromNotification,
                showBorder: true,
                margin: const EdgeInsets.all(AppDimensions.spacingM),
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
                              Icons.group,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text(
                              l10n.groupManagement,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildGroupManagementTab(),
                      ),
                    ],
                  ),
                ),
              ),
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
          label: Text(
            l10n.createGroup,
            style: const TextStyle(
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
    final l10n = L10n.of(context);
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
                      l10n.generalAnnouncements,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      l10n.visibleToAllParticipants,
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
    final l10n = L10n.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add,
              size: AppDimensions.iconXXL,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.noGroupsYet,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.createGroupDescription,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            // 未割り当て参加者がいる場合の警告表示
            if (_unassignedParticipants.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingL),
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
                            l10n.unassignedParticipantsWarning(_unassignedParticipants.length),
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
                        l10n.viewUnassignedParticipants,
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
    );
  }

  /// 未割り当て参加者セクション
  Widget _buildUnassignedSection() {
    final l10n = L10n.of(context);
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
              l10n.unassignedParticipantsTitle(_unassignedParticipants.length),
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
    final l10n = L10n.of(context);
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
                  PopupMenuItem(value: 'edit', child: Text(l10n.editAction)),
                  PopupMenuItem(
                    value: 'add_member',
                    child: Text(l10n.addMemberAction),
                  ),
                  PopupMenuItem(value: 'delete', child: Text(l10n.deleteAction)),
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
                  Text(
                    l10n.groupDescriptionLabel,
                    style: const TextStyle(
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
                      Text(
                        l10n.groupAnnouncementsLabel,
                        style: const TextStyle(
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
            l10n.participantsCount(group.participants.length),
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
                    l10n.noMembersInGroup,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    l10n.addMemberFromMenuHint,
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
    final l10n = L10n.of(context);
    final isUnassigned = _unassignedParticipants.contains(participant);

    List<Widget> additionalActions = [];
    if (isUnassigned && _groups.isNotEmpty) {
      additionalActions.add(
        AppButton.primary(
          text: l10n.addToGroup,
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
    final l10n = L10n.of(context);
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
            Expanded(child: Text(l10n.selectGroupToAddParticipant(participant.gameUsername))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _groups
              .map(
                (group) => ListTile(
                  leading: Icon(Icons.group, color: AppColors.accent),
                  title: Text(group.name),
                  subtitle: Text(l10n.membersCount(group.participants.length)),
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
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// 参加者をグループから削除
  Future<void> _removeParticipantFromGroup(
    ApprovedParticipant participant,
  ) async {
    final l10n = L10n.of(context);
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.participantRemovedFromGroup(participant.gameUsername, groupToUpdate.name),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToRemoveParticipant)),
        );
      }
    }
  }

  /// 参加者をグループに追加
  Future<void> _addParticipantToGroup(
    ApprovedParticipant participant,
    EventGroup group,
  ) async {
    final l10n = L10n.of(context);
    try {
      await FirebaseFirestore.instance
          .collection('event_groups')
          .doc(group.id)
          .update({
            'participants': FieldValue.arrayUnion([participant.userId]),
          });

      _loadGroupData(); // データ再読み込み

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.participantAddedToGroup(participant.gameUsername, group.name)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToAddParticipant)),
        );
      }
    }
  }

  /// アクション処理
  void _handleGroupAction(EventGroup group, String action) {
    final l10n = L10n.of(context);
    switch (action) {
      case 'edit':
        _editGroup(group);
        break;
      case 'add_member':
        if (_unassignedParticipants.isNotEmpty) {
          _showGroupMemberSelectionDialog(group);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.noParticipantsToAdd)),
          );
        }
        break;
      case 'delete':
        _deleteGroup(group);
        break;
    }
  }

  /// グループメンバー選択ダイアログ
  void _showGroupMemberSelectionDialog(EventGroup group) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addMemberToGroup(group.name)),
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
            child: Text(l10n.cancel),
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
    final l10n = L10n.of(context);
    try {
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
          SnackBar(
            content: Text(l10n.generalAnnouncementsUpdated),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUpdateGeneralAnnouncements(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 全体連絡事項編集ダイアログ
  void _showGeneralAnnouncementsDialog() {
    final l10n = L10n.of(context);
    final announcementsController = TextEditingController(
      text: _commonDescription,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: MarqueeText(
                text: l10n.editGeneralAnnouncementsTitle,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.generalAnnouncementsDescription,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: announcementsController,
                label: l10n.generalAnnouncementsLabel,
                hintText: l10n.generalAnnouncementsHint,
                maxLines: 5,
                minLines: 3,
                doneButtonText: l10n.ok,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: l10n.save,
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
    final l10n = L10n.of(context);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createNewGroup),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.groupNameLabel,
                  hintText: l10n.groupNameHint,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.groupDescriptionOptional,
                  hintText: l10n.groupDescriptionHint,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: l10n.createAction,
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
    final l10n = L10n.of(context);
    try {
      // 入力値の検証
      if (name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pleaseEnterGroupName),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

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
        // データ再読み込み
        await _loadGroupData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.groupCreated(name)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception(l10n.failedToCreateGroup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToCreateGroupWithError(e.toString())),
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
    final l10n = L10n.of(context);
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
        title: Text(l10n.editGroup),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.groupNameLabel),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: l10n.groupDescriptionOptional),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: announcementsController,
                label: l10n.groupAnnouncementsOptional,
                hintText: l10n.groupAnnouncementsHint,
                maxLines: 3,
                doneButtonText: l10n.ok,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: l10n.updateAction,
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
    final l10n = L10n.of(context);
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
              content: Text(l10n.groupUpdated(name)),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        throw Exception(l10n.failedToUpdateGroup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUpdateGroupWithError(e.toString())),
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
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cannotDeleteGroup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupHasRelatedMatches(group.name, matchCount)),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.cannotDeleteGroupReason,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.deleteGroupHint,
              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.understoodAction),
          ),
          AppButton.secondary(
            text: l10n.goToMatchManagement,
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
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGroupTitle),
        content: Text(l10n.deleteGroupConfirmation(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.danger(
            text: l10n.deleteAction,
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
    final l10n = L10n.of(context);
    try {
      final success = await GroupService.deleteGroup(group.id);

      if (success) {
        _loadGroupData(); // データ再読み込み

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.groupDeleted(group.name))),
          );
        }
      } else {
        throw Exception(l10n.failedToDeleteGroup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToDeleteGroup)),
        );
      }
    }
  }

  /// ゲームプロフィール画面に遷移
  Future<void> _navigateToGameProfile(ApprovedParticipant participant) async {
    final l10n = L10n.of(context);
    if (_gameId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gameInfoNotFound)),
      );
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
        skillLevel: _parseSkillLevel(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToShowGameProfile)),
        );
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

  /// 経験レベル文字列をSkillLevelに変換
  SkillLevel? _parseSkillLevel(String? skillLevelStr) {
    if (skillLevelStr == null) return null;
    switch (skillLevelStr.toLowerCase()) {
      case 'beginner':
        return SkillLevel.beginner;
      case 'intermediate':
        return SkillLevel.intermediate;
      case 'advanced':
        return SkillLevel.advanced;
      case 'expert':
      case 'pro':
        return SkillLevel.expert;
      default:
        return SkillLevel.intermediate; // デフォルト
    }
  }

  /// ロール文字列をPlayStylesに変換
  List<PlayStyle> _parsePlayStyles(String? roleStr) {
    if (roleStr == null || roleStr.isEmpty) return [];

    // 基本的なロールマッピング（ゲームによって異なるため、簡単な例）
    switch (roleStr.toLowerCase()) {
      case 'tank':
      case 'defensive':
        return [PlayStyle.competitive]; // 競技志向として扱う
      case 'dps':
      case 'damage':
      case 'aggressive':
        return [PlayStyle.competitive]; // 競技志向として扱う
      case 'support':
      case 'supportive':
        return [PlayStyle.cooperative]; // 協力プレイとして扱う
      case 'healer':
        return [PlayStyle.cooperative]; // 協力プレイとして扱う
      case 'casual':
        return [PlayStyle.casual];
      case 'social':
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
    final l10n = L10n.of(context);
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
                isExpanded ? l10n.collapseText : l10n.showMoreText,
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
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_off, color: AppColors.warning),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.unassignedParticipantsDialogTitle),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.approvedNotAssignedDescription,
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
                        l10n.createGroupForParticipantsHint,
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
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: l10n.createGroup,
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

}

