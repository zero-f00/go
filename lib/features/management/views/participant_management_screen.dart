import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/admin_memo_widget.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/widgets/app_text_field.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                title: '参加者管理',
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
                            const Text(
                              '参加者管理',
                              style: TextStyle(
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
        tabs: const [
          Tab(text: '申請中'),
          Tab(text: '承認済み'),
          Tab(text: '拒否済み'),
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
                    'データの読み込みに失敗しました',
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
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        message = '申請中の参加者はいません';
        icon = Icons.pending_actions;
        break;
      case 'approved':
        message = '承認済みの参加者はいません';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = '拒否済みの参加者はいません';
        icon = Icons.cancel;
        break;
      default:
        message = '参加者はいません';
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
                        backgroundImage: userData?.photoUrl != null
                            ? NetworkImage(userData!.photoUrl!)
                            : null,
                        child: userData?.photoUrl == null
                            ? Text(
                                userData?.displayName != null
                                    ? userData!.displayName
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'U',
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
                              application.gameUsername ?? userData?.displayName ?? '読み込み中...',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            // 実際のユーザー名をサブ表示（ゲーム内ユーザー名がある場合のみ）
                            if (application.gameUsername != null &&
                                application.gameUsername!.isNotEmpty &&
                                userData?.displayName != null)
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
                                  userData!.displayName,
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
        experience: data['experience'] != null
            ? GameExperience.values.firstWhere(
                (e) => e.name == data['experience'],
                orElse: () => GameExperience.beginner,
              )
            : GameExperience.beginner,
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
        experience: GameExperience.beginner,
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
  void _viewUserProfile(String userId) {
    Navigator.of(context).pushNamed('/user_profile', arguments: userId);
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case 'pending':
        backgroundColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        text = '申請中';
        break;
      case 'approved':
        backgroundColor = AppColors.success.withValues(alpha: 0.2);
        textColor = AppColors.success;
        text = '承認済み';
        break;
      case 'rejected':
        backgroundColor = AppColors.error.withValues(alpha: 0.2);
        textColor = AppColors.error;
        text = '拒否済み';
        break;
      default:
        backgroundColor = AppColors.textLight.withValues(alpha: 0.2);
        textColor = AppColors.textSecondary;
        text = '不明';
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
          '申請日時: ${_formatDateTime(application.appliedAt)}',
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
                const Text(
                  '申込メッセージ:',
                  style: TextStyle(
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
                  '承認メッセージ:',
                  style: TextStyle(
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
                  '拒否理由:',
                  style: TextStyle(
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

    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            text: '承認',
            onPressed: () => _approveRequest(userId),
            isFullWidth: true,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton.secondary(
            text: '拒否',
            onPressed: () => _rejectRequest(userId),
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
      debugPrint('ユーザーデータ取得エラー: $e');
      return null;
    }
  }

  Future<void> _approveRequest(String userId) async {
    // 承認ダイアログでメッセージを入力できるようにする
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: '参加申請を承認しますか？',
        message: '承認メッセージを入力できます（任意）',
        isRejection: false,
      ),
    );

    if (result != null) {
      try {
        // 申請を検索してIDを取得
        final applications = await ParticipationService.getEventApplications(
          widget.eventId,
        ).first;
        final application = applications.firstWhere(
          (app) => app.userId == userId,
        );

        final success = await ParticipationService.updateApplicationStatus(
          application.id,
          ParticipationStatus.approved,
          adminMessage: result.isNotEmpty ? result : null,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('参加申請を承認しました'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlerService.showErrorDialog(context, '承認に失敗しました');
        }
      }
    }
  }

  Future<void> _rejectRequest(String userId) async {
    // 拒否ダイアログで理由を入力できるようにする
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => _ApprovalDialog(
        title: '参加申請を拒否しますか？',
        message: '拒否理由を入力してください（任意）',
        isRejection: true,
      ),
    );

    if (result != null) {
      try {
        // 申請を検索してIDを取得
        final applications = await ParticipationService.getEventApplications(
          widget.eventId,
        ).first;
        final application = applications.firstWhere(
          (app) => app.userId == userId,
        );

        final success = await ParticipationService.updateApplicationStatus(
          application.id,
          ParticipationStatus.rejected,
          adminMessage: result.isNotEmpty ? result : null,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('参加申請を拒否しました'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ErrorHandlerService.showErrorDialog(context, '拒否に失敗しました');
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// ユーザーアクションモーダルを表示
  void _showUserActionModal(ParticipationApplication application, UserData? userData) {
    UserActionModal.show(
      context: context,
      eventId: widget.eventId,
      userId: application.userId,
      userName: userData?.displayName ?? application.gameUsername ?? 'Unknown',
      gameUsername: application.gameUsername,
      userData: userData,
      onGameProfileTap: () => _viewGameProfile(application),
      onUserProfileTap: () => _viewUserProfile(application.userId),
    );
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
            hintText: widget.isRejection ? '拒否理由を入力...' : '承認メッセージを入力...',
            maxLines: 3,
            doneButtonText: '完了',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'キャンセル',
            style: TextStyle(
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
            widget.isRejection ? '拒否' : '承認',
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
