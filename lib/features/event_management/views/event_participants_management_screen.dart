import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/utils/withdrawn_user_helper.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../l10n/app_localizations.dart';

/// イベント参加者管理画面
class EventParticipantsManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;
  final String? notificationType;
  final String? cancelledUserId;
  final String? cancelledUserName;
  final String? cancellationReason;

  const EventParticipantsManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
    this.notificationType,
    this.cancelledUserId,
    this.cancelledUserName,
    this.cancellationReason,
  });

  @override
  ConsumerState<EventParticipantsManagementScreen> createState() =>
      _EventParticipantsManagementScreenState();
}

class _EventParticipantsManagementScreenState
    extends ConsumerState<EventParticipantsManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final UserRepository _userRepository = UserRepository();

  final Map<String, UserData> _userDataCache = {};
  final Set<String> _processingApplications = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // テキストが長い場合のみアニメーション開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextLengthAndStartAnimation();
    });

    // 通知から来た場合の初期処理
    if (widget.fromNotification && widget.notificationType == 'participantCancelled') {
      // キャンセル通知の場合は、キャンセル済みタブ（タブインデックス4）に移動
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(4);

          // キャンセル情報をスナックバーで表示
          if (widget.cancelledUserName != null) {
            final l10n = L10n.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.userCancelledParticipation(widget.cancelledUserName!),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 3),
                action: widget.cancellationReason != null ? SnackBarAction(
                  label: l10n.viewReason,
                  textColor: AppColors.textWhite,
                  onPressed: () => _showCancellationReasonDialog(),
                ) : null,
              ),
            );
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                title: l10n.participantsTitle,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                enableTap: widget.fromNotification,
                iconData: Icons.people_alt,
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
                              Icons.people_alt,
                              color: AppColors.accent,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            Text(
                              l10n.participationApplications,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true, // 横スクロールを有効化
                          tabAlignment: TabAlignment.start, // 左寄せで開始
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
                          labelPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingL), // タブ間のパディング調整
                          indicatorPadding: const EdgeInsets.all(4),
                          tabs: [
                            Tab(text: l10n.tabPending),
                            Tab(text: l10n.tabApproved),
                            Tab(text: l10n.tabRejected),
                            Tab(text: l10n.tabWaitlisted),
                            Tab(text: l10n.tabCancelled),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingM),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildParticipantList('pending'),
                            _buildParticipantList('approved'),
                            _buildParticipantList('rejected'),
                            _buildParticipantList('waitlisted'),
                            _buildParticipantList('cancelled'),
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

  Widget _buildParticipantList(String status) {
    return StreamBuilder<List<ParticipationApplication>>(
      stream: ParticipationService.getEventApplications(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          final l10n = L10n.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  l10n.dataLoadFailed,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  l10n.errorLabel(snapshot.error.toString()),
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.error,
                  ),
                ),
              ],
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
      case 'approved':
        message = l10n.noApprovedParticipants;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = l10n.noRejectedParticipants;
        icon = Icons.cancel;
        break;
      case 'waitlisted':
        message = l10n.noWaitlistedParticipants;
        icon = Icons.queue;
        break;
      case 'cancelled':
        message = l10n.noCancelledParticipants;
        icon = Icons.cancel_outlined;
        break;
      default:
        message = l10n.noParticipants;
        icon = Icons.people;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(ParticipationApplication application, String status) {
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
            onTap: () => _showUserActionModal(application, userData),
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
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      backgroundImage: WithdrawnUserHelper.getDisplayAvatarUrl(userData) != null
                          ? NetworkImage(WithdrawnUserHelper.getDisplayAvatarUrl(userData)!)
                          : null,
                      child: WithdrawnUserHelper.getDisplayAvatarUrl(userData) == null
                          ? Text(
                              WithdrawnUserHelper.getDisplayUsername(context, userData).substring(0, 1).toUpperCase(),
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
                          Text(
                            userData != null ? WithdrawnUserHelper.getDisplayUsername(context, userData) : L10n.of(context).loadingText,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (userData != null)
                            Text(
                              '@${WithdrawnUserHelper.getDisplayUserId(userData)}',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: AppColors.textDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(height: AppDimensions.spacingS),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: AppDimensions.iconS,
                          color: AppColors.textDark,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildGameAccountInfo(application),
                const SizedBox(height: AppDimensions.spacingM),
                _buildRequestInfo(application),
                if (status == 'pending') ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildActionButtons(application),
                ],
                if (status == 'approved') ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildReturnToPendingButton(application, L10n.of(context).revokeApprovalAndReturnToPending),
                ],
                if (status == 'rejected') ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildReturnToPendingButton(application, L10n.of(context).revokeRejectionAndReturnToPending),
                ],
                if (status == 'waitlisted') ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildWaitlistActionButtons(application),
                ],
                if (status == 'cancelled') ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildCancellationInfo(application),
                ],
              ],
            ),
            ),
          ),
        );
      },
    );
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
      case 'waitlisted':
        backgroundColor = AppColors.accent.withValues(alpha: 0.2);
        textColor = AppColors.accent;
        text = l10n.statusWaitlisted;
        break;
      case 'cancelled':
        backgroundColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        text = l10n.statusCancelled;
        break;
      default:
        backgroundColor = AppColors.textLight.withValues(alpha: 0.2);
        textColor = AppColors.textDark;
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

  Widget _buildGameAccountInfo(ParticipationApplication application) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gamepad,
                size: AppDimensions.iconS,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.gameAccountInfo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                  fontSize: AppDimensions.fontSizeM,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          if (application.gameUsername != null) ...[
            _buildInfoRow(l10n.inGameUsername, application.gameUsername!),
          ],
          if (application.gameUserId != null && application.gameUserId!.isNotEmpty) ...[
            _buildInfoRow(l10n.inGameUserId, application.gameUserId!),
          ],
          if (application.gameUsername == null) ...[
            Text(
              l10n.noGameAccountInfo,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestInfo(ParticipationApplication application) {
    final l10n = L10n.of(context);
    String dateText = l10n.applicationDateTime(_formatDateTime(application.appliedAt));

    // Add message if present
    if (application.message != null && application.message!.isNotEmpty) {
      dateText += '\n${l10n.messageLabel(application.message!)}';
    }

    // Add rejection reason if present
    if (application.rejectionReason != null && application.rejectionReason!.isNotEmpty) {
      dateText += '\n${l10n.rejectionReasonLabel(application.rejectionReason!)}';
    }

    return Text(
      dateText,
      style: TextStyle(
        fontSize: AppDimensions.fontSizeS,
        color: AppColors.textDark,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons(ParticipationApplication application) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            text: l10n.approve,
            onPressed: () => _approveApplication(application),
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton.danger(
            text: l10n.reject,
            onPressed: () => _rejectApplication(application),
            isFullWidth: true,
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


  Future<void> _approveApplication(ParticipationApplication application) async {
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    // 承認前に定員をチェック（申請中・キャンセル待ち共通）
    final canApprove = await _checkCapacityForApproval(application);
    if (!canApprove) return;

    final message = await _showApprovalMessageDialog(true);
    if (message == null) return; // キャンセルされた場合

    // 処理中状態に追加
    setState(() {
      _processingApplications.add(application.id);
    });

    try {

      // 現在のユーザーIDを取得（自己通知除外のため）
      final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.approved,
        adminMessage: message.isEmpty ? null : message,
        adminUserId: currentUserId,
      );

      if (result && mounted) {
        // 通知はParticipationService内で一元管理されるため、ここでは送信しない
        final l10n = L10n.of(context);
        final statusText = application.status == ParticipationStatus.waitlisted
            ? l10n.waitlistUserApproved
            : l10n.applicationApproved;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusText),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.approvalFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        // 定員オーバーエラーの場合は専用メッセージを表示
        String errorMessage = l10n.approvalFailed;
        if (e.toString().contains('定員を超過')) {
          errorMessage = l10n.capacityExceededApprovalError;
        }

        ErrorHandlerService.showErrorDialog(
          context,
          errorMessage,
        );
      }
    } finally {
      // 処理中状態から削除
      setState(() {
        _processingApplications.remove(application.id);
      });
    }
  }

  Future<void> _rejectApplication(ParticipationApplication application) async {
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    final message = await _showApprovalMessageDialog(false);
    if (message == null) return; // キャンセルされた場合

    // 処理中状態に追加
    setState(() {
      _processingApplications.add(application.id);
    });

    try {
      // 現在のユーザーIDを取得（自己通知除外のため）
      final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.rejected,
        adminMessage: message.isEmpty ? null : message,
        adminUserId: currentUserId,
      );

      if (result && mounted) {
        // 通知はParticipationService内で一元管理されるため、ここでは送信しない
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.applicationRejectedSuccess),
            backgroundColor: AppColors.warning,
          ),
        );
      } else if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rejectionFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ErrorHandlerService.showErrorDialog(
          context,
          l10n.rejectionFailed,
        );
      }
    } finally {
      // 処理中状態から削除
      setState(() {
        _processingApplications.remove(application.id);
      });
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



  /// 承認・拒否メッセージ入力ダイアログ
  Future<String?> _showApprovalMessageDialog(bool isApproval) async {
    final l10n = L10n.of(context);
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController messageController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              isApproval ? l10n.approveApplicationTitle : l10n.rejectApplicationTitle,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isApproval
                        ? l10n.approveApplicationMessageHint
                        : l10n.rejectApplicationMessageHint,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: isApproval ? l10n.messageInputLabel : l10n.rejectReasonInputLabel,
                      hintText: isApproval
                          ? l10n.approveMessagePlaceholder
                          : l10n.rejectMessagePlaceholder,
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  messageController.dispose();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
              AppButton.primary(
                text: isApproval ? l10n.approveButton : l10n.rejectButton,
                onPressed: () {
                  final message = messageController.text.trim();
                  messageController.dispose();
                  Navigator.of(dialogContext).pop(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 申請中に戻すダイアログを表示
  Future<String?> _showReturnToPendingDialog(String title, String message) async {
    final l10n = L10n.of(context);
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController messageController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  AppTextFieldMultiline(
                    controller: messageController,
                    hintText: l10n.enterReasonHint,
                    maxLines: 3,
                    doneButtonText: l10n.ok,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  messageController.dispose();
                  Navigator.of(dialogContext).pop();
                },
                child: Text(l10n.cancel),
              ),
              AppButton.primary(
                text: l10n.returnToPendingButton,
                onPressed: () {
                  final text = messageController.text;
                  messageController.dispose();
                  Navigator.of(dialogContext).pop(text);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  /// 情報行を構築するヘルパーメソッド
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ユーザープロフィール画面に遷移
  void _viewUserProfile(String userId) async {
    try {
      // ユーザー情報を取得してカスタムユーザーIDで遷移
      final userData = await _getUserData(userId);
      if (userData != null && mounted) {
        // 退会ユーザーの場合はプロフィール表示を制限
        if (!userData.isActive) {
          final l10n = L10n.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.withdrawnUserProfileNotAvailable),
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
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.userNotFoundError),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.userProfileLoadFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ユーザーアクションモーダルを表示
  void _showUserActionModal(ParticipationApplication application, UserData? userData) {
    UserActionModal.show(
      context: context,
      eventId: widget.eventId,
      eventName: widget.eventName,
      userId: application.userId,
      userName: userData?.displayName ?? application.gameUsername ?? 'Unknown',
      gameUsername: application.gameUsername,
      userData: userData,
      onGameProfileTap: () => _viewGameProfile(application),
      onUserProfileTap: () => _viewUserProfile(application.userId),
      showViolationReport: true,
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
    } else {
      // ゲーム情報が不足している場合の処理
      final l10n = L10n.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.gameProfileInfoMissing),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  /// 申請中に戻すボタン
  Widget _buildReturnToPendingButton(ParticipationApplication application, String buttonText) {
    return Row(
      children: [
        Expanded(
          child: AppButton.outline(
            text: buttonText,
            onPressed: () => _returnToPending(application),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  /// 申請中に戻す
  Future<void> _returnToPending(ParticipationApplication application) async {
    final l10n = L10n.of(context);
    // 重複処理を防ぐ
    if (_processingApplications.contains(application.id)) {
      return;
    }

    final currentStatus = application.status;
    final isFromApproval = currentStatus == ParticipationStatus.approved;

    final title = isFromApproval ? l10n.revokeApprovalTitle : l10n.revokeRejectionTitle;
    final confirmMessage = isFromApproval
        ? l10n.revokeApprovalConfirmMessage
        : l10n.revokeRejectionConfirmMessage;

    final message = await _showReturnToPendingDialog(title, confirmMessage);
    if (message == null) return;

    // 処理中状態に追加
    setState(() {
      _processingApplications.add(application.id);
    });

    try {
      // 現在のユーザーIDを取得
      final currentUserId = ref.read(currentFirebaseUserProvider)?.uid;

      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.pending,
        adminMessage: message.isEmpty
            ? (isFromApproval ? l10n.approvalRevoked : l10n.rejectionRevoked)
            : message,
        adminUserId: currentUserId,
      );

      if (result && mounted) {
        final successMessage = isFromApproval ? l10n.revokeApprovalSuccess : l10n.revokeRejectionSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        final errorMessage = isFromApproval ? l10n.revokeApprovalFailed : l10n.revokeRejectionFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = isFromApproval ? l10n.revokeApprovalFailed : l10n.revokeRejectionFailed;
        ErrorHandlerService.showErrorDialog(
          context,
          errorMessage,
        );
      }
    } finally {
      // 処理中状態から削除
      setState(() {
        _processingApplications.remove(application.id);
      });
    }
  }

  /// キャンセル理由を表示するダイアログ
  Future<void> _showCancellationReasonDialog() async {
    if (widget.cancellationReason == null || widget.cancelledUserName == null) {
      return;
    }

    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warning.withValues(alpha: 0.9),
                      AppColors.warning,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusL),
                    topRight: Radius.circular(AppDimensions.radiusL),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingS),
                      decoration: BoxDecoration(
                        color: AppColors.overlayLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: Icon(
                        Icons.cancel_outlined,
                        color: AppColors.textWhite,
                        size: AppDimensions.iconL,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cancellationReasonTitle,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: AppDimensions.fontSizeXL,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingXS),
                          Text(
                            widget.cancelledUserName!,
                            style: const TextStyle(
                              color: AppColors.overlayMedium,
                              fontSize: AppDimensions.fontSizeM,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textWhite,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.overlayLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // コンテンツ
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        widget.cancellationReason!,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingL),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: l10n.closeButton,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// キャンセル情報を表示
  Widget _buildCancellationInfo(ParticipationApplication application) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.cancellationReasonTitle,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            application.cancellationReason?.isNotEmpty == true
                ? application.cancellationReason!
                : l10n.noCancellationReasonRecorded,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
          if (application.cancelledAt != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.cancellationDateTimeLabel(_formatDateTime(application.cancelledAt!)),
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }


  /// 承認前の定員チェック（申請中・キャンセル待ち共通）
  Future<bool> _checkCapacityForApproval(ParticipationApplication application) async {
    final l10n = L10n.of(context);
    try {
      // 現在の承認済み参加者数を取得
      final currentApprovedCount = await ParticipationService.getApprovedParticipantCount(application.eventId);

      // イベント情報を取得
      final event = await EventService.getEventById(application.eventId);

      if (event == null) {
        if (mounted) {
          ErrorHandlerService.showErrorDialog(
            context,
            l10n.eventInfoFetchFailed,
          );
        }
        return false;
      }

      // 定員チェック
      if (currentApprovedCount >= event.maxParticipants) {
        if (mounted) {
          // 定員オーバーの警告ダイアログを表示
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(
                  l10n.capacityExceededTitle,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                content: Text(
                  l10n.capacityExceededMessage(currentApprovedCount, event.maxParticipants),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.ok,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorDialog(
          context,
          l10n.capacityCheckFailed,
        );
      }
      return false;
    }
  }

  /// キャンセル待ちアクションボタンを構築
  Widget _buildWaitlistActionButtons(ParticipationApplication application) {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            text: l10n.approveWaitlistUser,
            onPressed: () => _approveApplication(application),
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton.secondary(
            text: l10n.returnWaitlistToPending,
            onPressed: () => _returnToPending(application),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  /// テキスト長をチェックしてアニメーション開始判定
  void _checkTextLengthAndStartAnimation() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.eventName,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textWidth = textPainter.width;

    // 画面幅から余白を差し引いた利用可能幅を計算
    final availableWidth = MediaQuery.of(context).size.width -
        (AppDimensions.spacingL * 2) - // Container margin
        (AppDimensions.spacingM * 2) - // Container padding
        AppDimensions.iconM - // Icon width
        AppDimensions.spacingM; // Icon spacing

    // テキストが利用可能幅を超える場合のみアニメーション開始
    if (textWidth > availableWidth) {
      _startScrollAnimation();
    }
  }

  /// スクロールアニメーション開始
  void _startScrollAnimation() {
  }

}