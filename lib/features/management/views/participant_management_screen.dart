import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/event_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/utils/withdrawn_user_helper.dart';

class ParticipantManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;

  const ParticipantManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
  });

  @override
  ConsumerState<ParticipantManagementScreen> createState() =>
      _ParticipantManagementScreenState();
}

class _ParticipantManagementScreenState
    extends ConsumerState<ParticipantManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = UserRepository();

  final Map<String, UserData> _userDataCache = {};
  final Set<String> _processingApplications = {}; // 処理中のアプリケーションID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 戻るボタンの処理
  void _handleBackPressed() {
    // 通常の戻る動作
    Navigator.of(context).pop();
  }

  /// イベント詳細画面に遷移
  void _navigateToEventDetail() {
    Navigator.of(context).pushNamed(
      '/event_detail',
      arguments: widget.eventId,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: L10n.of(context).participantManagementTitle,
                showBackButton: true,
                onBackPressed: () => _handleBackPressed(),
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
                              Icons.group,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text(
                              L10n.of(context).participantManagementTitle,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildParticipantList('pending'),
                            _buildParticipantList('waitlisted'),
                            _buildParticipantList('approved'),
                            _buildParticipantList('rejected'),
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
        unselectedLabelColor: AppColors.textDark,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppDimensions.fontSizeM,
        ),
        tabs: [
          Tab(text: L10n.of(context).tabPending),
          Tab(text: L10n.of(context).tabWaitlisted),
          Tab(text: L10n.of(context).tabApproved),
          Tab(text: L10n.of(context).tabRejected),
        ],
      ),
    );
  }

  /// イベント情報表示
  Widget _buildEventInfo() {
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
      child: InkWell(
        onTap: () => _navigateToEventDetail(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          child: Row(
            children: [
              Icon(
                Icons.event,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  widget.eventName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: AppDimensions.iconS,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantList(String status) {

    return StreamBuilder<List<ParticipationApplication>>(
      stream: ParticipationService.getEventApplications(widget.eventId),
      builder: (context, snapshot) {

        if (snapshot.hasError) {
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.spacingL),
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    L10n.of(context).dataLoadFailed,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final allApplications = snapshot.data ?? [];

        final filteredApplications = allApplications
            .where((application) => application.status.name == status)
            .toList();


        if (filteredApplications.isEmpty) {
          return _buildEmptyState(status);
        }


        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          itemCount: filteredApplications.length,
          itemBuilder: (context, index) {
            final application = filteredApplications[index];
            return _buildParticipantCard(application, status);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    final l10n = L10n.of(context);
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = l10n.noPendingParticipants;
        icon = Icons.pending_actions;
        break;
      case 'waitlisted':
        message = l10n.noWaitlistedParticipants;
        icon = Icons.hourglass_empty;
        break;
      case 'approved':
        message = l10n.noApprovedParticipants;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = l10n.noRejectedParticipants;
        icon = Icons.cancel;
        break;
      default:
        message = l10n.noParticipants;
        icon = Icons.people;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconXXL,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              message,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(
    ParticipationApplication application,
    String status,
  ) {
    final userId = application.userId;

    return FutureBuilder<UserData?>(
      future: _getUserData(userId),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showUserActionModal(application, userData), // カード全体タップでアクションモーダル
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: WithdrawnUserHelper.getDisplayAvatarUrl(userData) != null
                            ? NetworkImage(WithdrawnUserHelper.getDisplayAvatarUrl(userData)!)
                            : null,
                        child: WithdrawnUserHelper.getDisplayAvatarUrl(userData) == null
                            ? Text(
                                WithdrawnUserHelper.getDisplayUsername(context, userData)
                                          .substring(0, 1)
                                          .toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppDimensions.fontSizeL,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ゲーム内ユーザー名を主表示
                            Text(
                              application.gameUsername ?? WithdrawnUserHelper.getDisplayUsername(context, userData),
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            // 実際のユーザー名をサブ表示（ゲーム内ユーザー名がある場合のみ）
                            if (application.gameUsername != null &&
                                application.gameUsername!.isNotEmpty &&
                                userData != null)
                              Container(
                                margin: const EdgeInsets.only(top: AppDimensions.spacingXS),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spacingS,
                                  vertical: AppDimensions.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                                  border: Border.all(
                                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  WithdrawnUserHelper.getDisplayUsername(context, userData),
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeS,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildRequestInfo(application),
                  if (status == 'pending') ...[
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildActionButtons(application),
                  ],
                  // 承認済みまたは拒否済みの場合は差し戻しボタンを表示
                  if (status == 'approved' || status == 'rejected') ...[
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildReturnToPendingButton(application, status),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ゲームプロフィール表示
  void _viewGameProfile(ParticipationApplication application) {
    // gameProfileDataからGameProfileを構築
    GameProfile? gameProfile;
    if (application.gameProfileData != null) {
      final data = application.gameProfileData!;
      gameProfile = GameProfile(
        id: data['id'] as String? ?? '',
        gameId: data['gameId'] as String? ?? '',
        userId: application.userId,
        gameUsername:
            data['gameUsername'] as String? ?? application.gameUsername ?? '',
        gameUserId:
            data['gameUserId'] as String? ?? application.gameUserId ?? '',
        skillLevel: data['skillLevel'] != null
            ? SkillLevel.values.firstWhere(
                (e) => e.name == data['skillLevel'],
                orElse: () => SkillLevel.beginner,
              )
            : SkillLevel.beginner,
        playStyles:
            (data['playStyles'] as List?)
                ?.map(
                  (e) => PlayStyle.values.firstWhere(
                    (style) => style.name == e,
                    orElse: () => PlayStyle.casual,
                  ),
                )
                .toList() ??
            [],
        rankOrLevel: data['rankOrLevel'] as String? ?? '',
        activityTimes:
            (data['activityTimes'] as List?)
                ?.map(
                  (e) => ActivityTime.values.firstWhere(
                    (time) => time.name == e,
                    orElse: () => ActivityTime.evening,
                  ),
                )
                .toList() ??
            [],
        useInGameVC: data['useInGameVC'] as bool? ?? false,
        voiceChatDetails: data['voiceChatDetails'] as String? ?? '',
        achievements: data['achievements'] as String? ?? '',
        notes: data['notes'] as String? ?? '',
        isFavorite: data['isFavorite'] as bool? ?? false,
        isPublic: data['isPublic'] as bool? ?? true,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } else if (application.gameUsername != null) {
      // 基本的なゲームプロフィールを作成
      gameProfile = GameProfile(
        id: '',
        gameId: '',
        userId: application.userId,
        gameUsername: application.gameUsername!,
        gameUserId: application.gameUserId ?? '',
        skillLevel: SkillLevel.beginner,
        playStyles: [],
        rankOrLevel: '',
        activityTimes: [],
        useInGameVC: false,
        voiceChatDetails: '',
        achievements: '',
        notes: '',
        isFavorite: false,
        isPublic: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    if (gameProfile != null) {
      // ユーザーデータを取得してから画面に渡す
      _getUserData(application.userId).then((userData) {
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/game_profile_view',
            arguments: {
              'profile': gameProfile,
              'userData': userData,
              'gameName': null,
              'gameIconUrl': null,
            },
          );
        }
      });
    }
  }

  /// ユーザープロフィール表示
  /// ユーザープロフィール画面に遷移
  void _viewUserProfile(String userId) async {
    try {
      // ユーザー情報を取得して退会状態を確認
      final userData = await _userRepository.getUserById(userId);
      if (userData != null && mounted) {
        // 退会ユーザーの場合はプロフィール表示を制限
        if (!userData.isActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).withdrawnUserProfileNotAvailable),
              backgroundColor: AppColors.warning,
            ),
          );
          return;
        }

        Navigator.of(context).pushNamed(
          '/user_profile',
          arguments: userData.userId, // カスタムユーザーIDを使用
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).userInfoNotFound),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).userProfileLoadFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    final l10n = L10n.of(context);
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        text = l10n.statusPending;
        break;
      case 'approved':
        backgroundColor = AppColors.success.withValues(alpha: 0.2);
        textColor = AppColors.success;
        text = l10n.statusApproved;
        break;
      case 'rejected':
        backgroundColor = AppColors.error.withValues(alpha: 0.2);
        textColor = AppColors.error;
        text = l10n.statusRejected;
        break;
      default:
        backgroundColor = AppColors.textLight.withValues(alpha: 0.2);
        textColor = AppColors.textSecondary;
        text = l10n.statusUnknown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildRequestInfo(ParticipationApplication application) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).applicationDateTime(_formatDateTime(application.appliedAt)),
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        if (application.message != null && application.message!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
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
                  L10n.of(context).applicationMessageLabel,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  application.message!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
        // 承認済みの場合は承認メッセージを表示
        if (application.status == ParticipationStatus.approved &&
            application.approvalMessage != null &&
            application.approvalMessage!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context).approvalMessageLabel,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  application.approvalMessage!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
        // 拒否済みの場合は拒否理由を表示
        if (application.status == ParticipationStatus.rejected &&
            application.rejectionReason != null &&
            application.rejectionReason!.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context).rejectionReasonTitle,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  application.rejectionReason!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(ParticipationApplication application) {
    final userId = application.userId;
    final isProcessing = _processingApplications.contains(application.id);

    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            text: L10n.of(context).approve,
            onPressed: isProcessing ? null : () => _approveRequest(application),
            isFullWidth: true,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton.secondary(
            text: L10n.of(context).reject,
            onPressed: isProcessing ? null : () => _rejectRequest(application),
            isFullWidth: true,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
        ),
      ],
    );
  }

  Future<UserData?> _getUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      return _userDataCache[userId];
    }

    try {
      final userData = await _userRepository.getUserById(userId);
      if (userData != null) {
        _userDataCache[userId] = userData;
      }
      return userData;
    } catch (e) {
      return null;
    }
  }

  Future<void> _approveRequest(ParticipationApplication application) async {
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    // 承認前に参加者数をチェック
    try {
      final currentApprovedCount = await ParticipationService.getApprovedParticipantCount(widget.eventId);

      // イベント情報を取得して定員を確認
      final eventDoc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId).get();
      if (eventDoc.exists) {
        final event = Event.fromFirestore(eventDoc);

        if (currentApprovedCount >= event.maxParticipants) {
          // 満員の場合は警告ダイアログを表示
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                title: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: AppColors.error,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      L10n.of(context).cannotApproveFullCapacity,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  '${L10n.of(context).fullCapacityApprovalMessage}\n\n${L10n.of(context).currentParticipantCount(currentApprovedCount, event.maxParticipants)}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      L10n.of(context).confirmButtonLabel,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // 定員間近の警告を表示
        if (currentApprovedCount >= event.maxParticipants - 1) {
          if (!mounted) return;
          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    L10n.of(context).nearCapacityWarning,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              content: Text(
                '${L10n.of(context).approvalWillReachCapacity}\n\n${L10n.of(context).currentParticipantCount(currentApprovedCount, event.maxParticipants)}\n\n${L10n.of(context).continueApproval}',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    L10n.of(context).cancel,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    ),
                  ),
                  child: Text(
                    L10n.of(context).approveButtonLabel,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldProceed != true) {
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).participantCountCheckFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // 承認ダイアログでメッセージを入力できるようにする
    if (!mounted) return;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: L10n.of(context).approveApplicationDialogTitle,
        message: L10n.of(context).enterApprovalMessageOptional,
        isRejection: false,
      ),
    );

    if (result != null) {
      // 処理中状態に追加
      setState(() {
        _processingApplications.add(application.id);
      });

      try {
        // 現在のユーザーIDを取得（自己通知除外のため）
        final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

        await ParticipationService.updateApplicationStatus(
          application.id,
          ParticipationStatus.approved,
          adminMessage: result.isNotEmpty ? result : null,
          adminUserId: currentUserId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).approvalSuccessMessage),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = L10n.of(context).approvalFailedMessage;

          // 定員超過エラーの場合は詳細なメッセージを表示
          if (e.toString().contains('定員を超過する') || e.toString().contains('capacity')) {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        // 処理中状態から削除
        if (mounted) {
          setState(() {
            _processingApplications.remove(application.id);
          });
        }
      }
    }
  }

  Future<void> _rejectRequest(ParticipationApplication application) async {
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    // 拒否ダイアログで理由を入力できるようにする
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: L10n.of(context).rejectApplicationDialogTitle,
        message: L10n.of(context).enterRejectionReasonOptional,
        isRejection: true,
      ),
    );

    if (result != null) {
      // 処理中状態に追加
      setState(() {
        _processingApplications.add(application.id);
      });

      try {
        // 現在のユーザーIDを取得（自己通知除外のため）
        final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

        final success = await ParticipationService.updateApplicationStatus(
          application.id,
          ParticipationStatus.rejected,
          adminMessage: result.isNotEmpty ? result : null,
          adminUserId: currentUserId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).rejectionSuccessMessage),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlerService.showErrorDialog(context, L10n.of(context).rejectionFailed);
        }
      } finally {
        // 処理中状態から削除
        if (mounted) {
          setState(() {
            _processingApplications.remove(application.id);
          });
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final l10n = L10n.of(context);
    return l10n.dateTimeFormatFull(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour.toString().padLeft(2, '0'),
      dateTime.minute.toString().padLeft(2, '0'),
    );
  }

  /// ユーザーアクションモーダルを表示
  void _showUserActionModal(ParticipationApplication application, UserData? userData) {
    UserActionModal.show(
      context: context,
      eventId: widget.eventId,
      userId: application.userId,
      userName: WithdrawnUserHelper.getDisplayUsername(context, userData),
      gameUsername: application.gameUsername,
      userData: userData,
      onGameProfileTap: () => _viewGameProfile(application),
      onUserProfileTap: () => _viewUserProfile(application.userId),
    );
  }

  /// 申請中に戻すボタン
  Widget _buildReturnToPendingButton(ParticipationApplication application, String status) {
    final l10n = L10n.of(context);
    final isFromApproval = status == 'approved';
    final buttonText = isFromApproval ? l10n.revokeApprovalAndReturnToPending : l10n.revokeRejectionAndReturnToPending;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _processingApplications.contains(application.id)
            ? null
            : () => _returnToPending(application, isFromApproval),
        icon: const Icon(Icons.undo, size: 18),
        label: Text(buttonText),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.warning,
          side: BorderSide(color: AppColors.warning),
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      ),
    );
  }

  /// 申請中に戻す処理
  Future<void> _returnToPending(ParticipationApplication application, bool isFromApproval) async {
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    final l10n = L10n.of(context);
    final title = isFromApproval ? l10n.revokeApprovalTitle : l10n.revokeRejectionTitle;
    final confirmMessage = isFromApproval
        ? l10n.revokeApprovalConfirmMessage
        : l10n.revokeRejectionConfirmMessage;

    final message = await showDialog<String?>(
      context: context,
      builder: (context) => _ReturnToPendingDialog(
        title: title,
        message: confirmMessage,
      ),
    );

    if (message == null) return; // キャンセルされた場合

    // 処理中状態に追加
    setState(() {
      _processingApplications.add(application.id);
    });

    try {
      // 現在のユーザーIDを取得（自己通知除外のため）
      final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

      final success = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.pending,
        adminMessage: message.isEmpty
            ? (isFromApproval ? l10n.approvalRevokedMessage : l10n.rejectionRevoked)
            : message,
        adminUserId: currentUserId,
      );

      if (success && mounted) {
        final successMessage = isFromApproval
            ? l10n.revokeApprovalSuccess
            : l10n.revokeRejectionSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        final errorMessage = isFromApproval
            ? l10n.revokeApprovalFailed
            : l10n.revokeRejectionFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = isFromApproval
            ? l10n.revokeApprovalFailed
            : l10n.revokeRejectionFailed;
        ErrorHandlerService.showErrorDialog(context, errorMessage);
      }
    } finally {
      // 処理中状態から削除
      if (mounted) {
        setState(() {
          _processingApplications.remove(application.id);
        });
      }
    }
  }
}

/// 承認・拒否ダイアログ
class _ApprovalDialog extends StatefulWidget {
  final String title;
  final String message;
  final bool isRejection;

  const _ApprovalDialog({
    required this.title,
    required this.message,
    required this.isRejection,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          AppTextFieldMultiline(
            controller: _controller,
            hintText: widget.isRejection ? L10n.of(context).enterRejectionReasonPlaceholder : L10n.of(context).enterApprovalMessagePlaceholder,
            maxLines: 3,
            doneButtonText: L10n.of(context).doneButtonLabel,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            L10n.of(context).cancel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeM,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isRejection
                ? AppColors.error
                : AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
          ),
          child: Text(
            widget.isRejection ? L10n.of(context).reject : L10n.of(context).approve,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// 申請中に戻すダイアログ
class _ReturnToPendingDialog extends StatefulWidget {
  final String title;
  final String message;

  const _ReturnToPendingDialog({
    required this.title,
    required this.message,
  });

  @override
  State<_ReturnToPendingDialog> createState() => _ReturnToPendingDialogState();
}

class _ReturnToPendingDialogState extends State<_ReturnToPendingDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          AppTextFieldMultiline(
            controller: _controller,
            hintText: L10n.of(context).revokeApprovalReasonHint,
            maxLines: 3,
            doneButtonText: L10n.of(context).doneButtonLabel,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            L10n.of(context).cancel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeM,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
          ),
          child: Text(
            L10n.of(context).returnToPendingButton,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
