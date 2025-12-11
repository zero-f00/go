import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/friend_service.dart';
import '../../../data/models/notification_model.dart';
import '../../../shared/widgets/user_avatar_from_id.dart';
import '../../event_detail/views/event_detail_screen.dart';
import '../../../shared/utils/event_converter.dart';
import '../../../shared/widgets/appeal_dialog.dart';
import '../../../shared/services/violation_service.dart';
import '../../event_management/views/violation_management_screen.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/services/push_notification_service.dart';

/// 通知画面
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<String> _processingRequests = {}; // 処理中のリクエストID
  Set<String> _readNotifications = {}; // 既読処理済みの通知ID

  @override
  void initState() {
    super.initState();
    // 通知画面を開いた時にバッジを同期
    _syncBadgeOnOpen();
  }

  /// 通知画面を開いた時にバッジを同期
  Future<void> _syncBadgeOnOpen() async {
    try {
      // 少し遅延を入れてProviderが初期化されるのを待つ
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // OSバッジを更新
      await PushNotificationService.instance.updateBadgeCount();
    } catch (e) {
      // エラーは無視
    }
  }

  /// 通知を既読にする
  Future<void> _markAsRead(NotificationData notification) async {
    if (notification.id == null || _readNotifications.contains(notification.id!) || notification.isRead) {
      return; // IDがnullまたは既に処理済みまたは既読の場合はスキップ
    }

    try {
      setState(() {
        _readNotifications.add(notification.id!);
      });

      await NotificationService.instance.markAsRead(notification.id!);

      // プロバイダーを明示的にリフレッシュして同期
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(userNotificationsProvider);

      // OSバッジも更新
      await PushNotificationService.instance.updateBadgeCount();
    } catch (e) {
      setState(() {
        _readNotifications.remove(notification.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              notificationsAsync.when(
                data: (notifications) => AppHeader(
                  title: AppStrings.notificationTab,
                  showBackButton: false,
                  showUserIcon: true,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  actions: [
                    if (notifications.any((n) => !n.isRead))
                      Container(
                        margin: const EdgeInsets.only(right: AppDimensions.spacingS),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardShadow.withValues(alpha: 0.3),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            onTap: () => _markAllAsRead(notifications),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingM,
                                vertical: AppDimensions.spacingS,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.done_all,
                                    size: AppDimensions.iconS,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppDimensions.spacingXS),
                                  const Text(
                                    '全て既読',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: AppDimensions.fontSizeS,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => AppHeader(
                  title: AppStrings.notificationTab,
                  showBackButton: false,
                  showUserIcon: true,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                error: (_, __) => AppHeader(
                  title: AppStrings.notificationTab,
                  showBackButton: false,
                  showUserIcon: true,
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Container(
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
                    child: notificationsAsync.when(
                      data: (notifications) => _buildContent(notifications),
                      loading: () => _buildLoadingState(),
                      error: (error, _) => _buildErrorState(error.toString()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ローディング状態を構築
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: AppDimensions.spacingM),
          Text(
            '通知を取得中...',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// エラー状態を構築
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
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
              errorMessage,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            AppButton(
              text: '再試行',
              onPressed: () {
                ref.invalidate(userNotificationsProvider);
              },
              type: AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 全ての通知を既読にする
  Future<void> _markAllAsRead(List<NotificationData> notifications) async {
    try {
      final unreadNotifications = notifications.where((n) => !n.isRead && n.id != null).toList();
      final unreadIds = unreadNotifications.map((n) => n.id!).toList();

      if (unreadIds.isNotEmpty) {
        await NotificationService.instance.markMultipleAsRead(unreadIds);

        // ローカルの既読追跡セットを更新
        setState(() {
          _readNotifications.addAll(unreadIds);
        });

        // プロバイダーを明示的にリフレッシュして同期
        ref.invalidate(unreadNotificationCountProvider);
        ref.invalidate(userNotificationsProvider);

        // OSバッジも更新
        await PushNotificationService.instance.updateBadgeCount();
      }
    } catch (e) {
      // エラーハンドリング
    }
  }

  /// メインコンテンツを構築
  Widget _buildContent(List<NotificationData> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userNotificationsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingL,
          vertical: AppDimensions.spacingS,
        ),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  /// 空の状態を構築
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.iconXL * 2,
              height: AppDimensions.iconXL * 2,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.notifications_none,
                size: AppDimensions.iconXL,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            const Text(
              '通知はありません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            const Text(
              '新しい通知が届くとここに表示されます',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textLight,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 通知カードを構築
  Widget _buildNotificationCard(NotificationData notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.6),
          width: notification.isRead ? 1.0 : 2.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildNotificationIcon(notification),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeL,
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              // イベント招待の申請状態バッジ
                              if (notification.type == NotificationType.eventInvite)
                                _buildApplicationStatusBadge(notification),
                              const SizedBox(width: AppDimensions.spacingS),
                              if (!notification.isRead)
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        blurRadius: 4.0,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingXS),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatNotificationTime(notification.createdAt),
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        notification.categoryDisplayName,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (notification.type == NotificationType.friendRequest &&
                    !notification.isRead) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _buildFriendRequestActions(notification),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 通知アイコンを構築
  Widget _buildNotificationIcon(NotificationData notification) {
    // フレンドリクエスト通知の場合はユーザーアイコンを表示
    if (notification.type == NotificationType.friendRequest &&
        notification.fromUserId != null) {
      return GestureDetector(
        onTap: () {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/user_profile',
              arguments: {'userId': notification.fromUserId},
            );
          }
        },
        child: UserAvatarFromId(
          userId: notification.fromUserId,
          size: 48,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          iconColor: AppColors.primary,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          borderWidth: 1.5,
        ),
      );
    }

    // その他の通知は従来通りのアイコン表示
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.friendRequest:
        icon = Icons.person_add;
        iconColor = AppColors.primary;
        break;
      case NotificationType.friendAccepted:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case NotificationType.friendRejected:
        icon = Icons.cancel;
        iconColor = AppColors.error;
        break;
      case NotificationType.eventInvite:
        icon = Icons.event;
        iconColor = AppColors.accent;
        break;
      case NotificationType.eventReminder:
        icon = Icons.schedule;
        iconColor = AppColors.warning;
        break;
      case NotificationType.eventApproved:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case NotificationType.eventRejected:
        icon = Icons.cancel;
        iconColor = AppColors.error;
        break;
      case NotificationType.eventApplication:
        icon = Icons.event_note;
        iconColor = AppColors.primary;
        break;
      case NotificationType.eventUpdated:
        icon = Icons.edit;
        iconColor = AppColors.info;
        break;
      case NotificationType.eventDraftReverted:
        icon = Icons.event_busy;
        iconColor = AppColors.warning;
        break;
      case NotificationType.eventCancelled:
        icon = Icons.cancel;
        iconColor = AppColors.error;
        break;
      case NotificationType.eventCancelProcessed:
        icon = Icons.task_alt;
        iconColor = AppColors.success;
        break;
      case NotificationType.violationReported:
        icon = Icons.report;
        iconColor = AppColors.error;
        break;
      case NotificationType.violationProcessed:
        icon = Icons.gavel;
        iconColor = AppColors.warning;
        break;
      case NotificationType.violationDismissed:
        icon = Icons.cancel;
        iconColor = AppColors.warning;
        break;
      case NotificationType.violationDeleted:
        icon = Icons.delete;
        iconColor = AppColors.error;
        break;
      case NotificationType.appealSubmitted:
        icon = Icons.help_outline;
        iconColor = AppColors.info;
        break;
      case NotificationType.appealProcessed:
        icon = Icons.verified;
        iconColor = AppColors.success;
        break;
      case NotificationType.matchReport:
        icon = Icons.report_problem;
        iconColor = AppColors.warning;
        break;
      case NotificationType.matchReportResponse:
        icon = Icons.assignment_returned;
        iconColor = AppColors.info;
        break;
      case NotificationType.system:
        icon = Icons.info;
        iconColor = AppColors.info;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.2),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 24,
      ),
    );
  }

  /// フレンドリクエストのアクションボタンを構築
  Widget _buildFriendRequestActions(NotificationData notification) {
    final requestId = notification.data?['friendRequestId'] as String?;
    final isProcessing = requestId != null && _processingRequests.contains(requestId);

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: isProcessing ? '処理中...' : '承認',
            icon: isProcessing ? null : Icons.check,
            onPressed: isProcessing ? null : () => _acceptFriendRequest(notification),
            type: AppButtonType.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton(
            text: isProcessing ? '処理中...' : '拒否',
            icon: isProcessing ? null : Icons.close,
            onPressed: isProcessing ? null : () => _rejectFriendRequest(notification),
            type: AppButtonType.secondary,
          ),
        ),
      ],
    );
  }

  /// 通知をタップした時の処理
  Future<void> _handleNotificationTap(NotificationData notification) async {
    // 未読の場合は既読にする
    if (!notification.isRead) {
      await _markAsRead(notification);
    }

    // 通知タイプに応じた処理
    if (notification.type == NotificationType.eventInvite) {
      _handleEventInvitation(notification);
      return;
    }

    if (notification.type == NotificationType.friendRequest) {
      _handleFriendRequest(notification);
      return;
    }

    if (notification.type == NotificationType.friendAccepted) {
      _handleFriendAccepted(notification);
      return;
    }

    if (notification.type == NotificationType.eventApplication) {
      _handleEventApplication(notification);
      return;
    }

    if (notification.type == NotificationType.eventApproved ||
        notification.type == NotificationType.eventRejected) {
      _handleEventDecisionNotification(notification);
      return;
    }

    if (notification.type == NotificationType.eventCancelled ||
        notification.type == NotificationType.eventCancelProcessed) {
      _handleEventCancelNotification(notification);
      return;
    }

    if (notification.type == NotificationType.violationReported) {
      _handleViolationReported(notification);
      return;
    }

    if (notification.type == NotificationType.appealSubmitted) {
      _handleAppealSubmitted(notification);
      return;
    }

    if (notification.type == NotificationType.appealProcessed) {
      _handleAppealProcessed(notification);
      return;
    }

    if (notification.type == NotificationType.eventUpdated) {
      _handleEventUpdatedNotification(notification);
      return;
    }

    // その他の通知タイプの処理をここに追加
  }

  /// イベント招待通知の処理
  Future<void> _handleEventInvitation(NotificationData notification) async {
    final eventData = notification.data;
    if (eventData == null ||
        eventData['eventId'] == null ||
        eventData['eventName'] == null) {
      ErrorHandlerService.showErrorDialog(
        context,
        'イベント情報が見つかりません'
      );
      return;
    }

    final eventId = eventData['eventId'] as String;
    final eventName = eventData['eventName'] as String;
    final createdByName = eventData['createdByName'] as String? ?? 'ユーザー';
    final applicationStatus = eventData['applicationStatus'] as String?;

    // 既に申請済みかチェック
    if (applicationStatus == 'submitted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('既に参加申請を送信済みです。運営からの返答をお待ちください。'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    // 申請が承認済み
    if (applicationStatus == 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('このイベントへの参加が承認されています。'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }

    // 申請が拒否済み
    if (applicationStatus == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('このイベントへの参加申請は拒否されました。'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // パスワード入力ダイアログを表示
    final password = await _showPasswordInputDialog(eventName, createdByName);
    if (password == null || password.isEmpty) return;

    // パスワード検証と参加申請
    await _submitEventJoinRequest(eventId, password, notification);
  }

  /// パスワード入力ダイアログを表示
  Future<String?> _showPasswordInputDialog(String eventName, String createdByName) async {
    final passwordController = TextEditingController();
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.event,
                  color: AppColors.accent,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベント参加申請',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '${createdByName}さんからの招待',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベント名',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      eventName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              const Text(
                'パスワードを入力してイベントに参加してください',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'イベントパスワード',
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
                ),
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final password = passwordController.text.trim();
                Navigator.of(context).pop(password);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('参加申請'),
            ),
          ],
        );
      },
    );
  }

  /// イベント参加申請を送信
  Future<void> _submitEventJoinRequest(
    String eventId,
    String password,
    NotificationData notification
  ) async {
    try {
      final authState = ref.read(authStateProvider);
      if (!authState.hasValue || authState.value == null) {
        throw Exception('ユーザーが認証されていません');
      }

      final userId = authState.value!.uid;

      // EventServiceを使用してパスワード検証と参加申請を送信
      await EventService.submitEventJoinRequest(
        eventId: eventId,
        password: password,
        userId: userId,
      );

      // 申請成功時に通知の状態を更新
      await _updateNotificationApplicationStatus(
        notification,
        'submitted'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('イベント参加申請を送信しました'),
            backgroundColor: AppColors.success,
          ),
        );

        // 動的更新により自動で状態が反映されるため手動再読み込み不要
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'エラーが発生しました';
        if (e is EventServiceException) {
          errorMessage = e.message;
        } else if (e.toString().contains('password')) {
          errorMessage = 'パスワードが正しくありません';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 通知の申請状態を更新
  Future<void> _updateNotificationApplicationStatus(
    NotificationData notification,
    String status
  ) async {
    try {
      if (notification.id == null) return;

      // 通知のdataフィールドを更新
      final updatedData = Map<String, dynamic>.from(notification.data ?? {});
      updatedData['applicationStatus'] = status;
      updatedData['applicationDate'] = DateTime.now().toIso8601String();

      await NotificationService.instance.updateNotification(
        notification.id!,
        data: updatedData,
      );
    } catch (e) {
      // エラーログのみ、ユーザーには影響させない
    }
  }


  /// 通知時間をフォーマット
  String _formatNotificationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}日前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}時間前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分前';
    } else {
      return 'たった今';
    }
  }

  /// フレンドリクエストを承認
  Future<void> _acceptFriendRequest(NotificationData notification) async {
    try {
      // 未読の場合は既読にする
      if (!notification.isRead) {
        await _markAsRead(notification);
      }

      // 通知データからフレンドリクエストIDを取得
      final friendRequestId = notification.data?['friendRequestId'] as String?;
      if (friendRequestId == null) {
        throw Exception('フレンドリクエストIDが見つかりません');
      }

      // FriendServiceを使用してリクエストを承認
      final friendService = FriendService.instance;
      final success = await friendService.acceptFriendRequest(friendRequestId);

      if (success) {
        // 承認成功の場合、通知リストを更新
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドリクエストを承認しました'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // 承認失敗の場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドリクエストの承認に失敗しました'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// フレンドリクエストを拒否
  Future<void> _rejectFriendRequest(NotificationData notification) async {
    try {
      // 未読の場合は既読にする
      if (!notification.isRead) {
        await _markAsRead(notification);
      }

      // 通知データからフレンドリクエストIDを取得
      final friendRequestId = notification.data?['friendRequestId'] as String?;
      if (friendRequestId == null) {
        throw Exception('フレンドリクエストIDが見つかりません');
      }

      // FriendServiceを使用してリクエストを拒否
      final friendService = FriendService.instance;
      final success = await friendService.rejectFriendRequest(friendRequestId);

      if (success) {
        // 拒否成功の場合、通知リストを更新
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドリクエストを拒否しました'),
              backgroundColor: AppColors.info,
            ),
          );
        }
      } else {
        // 拒否失敗の場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('フレンドリクエストの拒否に失敗しました'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// イベント招待通知の申請状態バッジを構築
  Widget _buildApplicationStatusBadge(NotificationData notification) {
    if (notification.data == null) return const SizedBox.shrink();

    final applicationStatus = notification.data!['applicationStatus'] as String?;
    if (applicationStatus == null) return const SizedBox.shrink();

    String text;
    Color backgroundColor;
    Color textColor;

    switch (applicationStatus) {
      case 'submitted':
        text = '申請済み';
        backgroundColor = AppColors.warning.withValues(alpha: 0.2);
        textColor = AppColors.warning;
        break;
      case 'approved':
        text = '承認済み';
        backgroundColor = AppColors.success.withValues(alpha: 0.2);
        textColor = AppColors.success;
        break;
      case 'rejected':
        text = '拒否済み';
        backgroundColor = AppColors.error.withValues(alpha: 0.2);
        textColor = AppColors.error;
        break;
      default:
        return const SizedBox.shrink();
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

  /// フレンド申請通知の処理
  Future<void> _handleFriendRequest(NotificationData notification) async {
    final fromUserId = notification.fromUserId;
    if (fromUserId == null) {
      _showErrorMessage('申請者の情報が見つかりません');
      return;
    }

    try {
      // 申請者のユーザー情報を確認
      final userRepository = UserRepository();
      // fromUserIdはカスタムID（例: go_swift_fox_1234）なのでgetUserByCustomIdを使用
      final fromUser = await userRepository.getUserByCustomId(fromUserId);

      if (fromUser == null || !fromUser.isActive) {
        // ユーザーが存在しないか退会済みの場合
        _showWithdrawnUserMessage();
        return;
      }

      // 有効なユーザーからのフレンド申請の場合
      // フレンド申請の詳細ダイアログやページを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フレンド申請の詳細機能は実装中です'),
          backgroundColor: AppColors.info,
        ),
      );
    } catch (e) {
      _showErrorMessage('申請者の情報確認中にエラーが発生しました');
    }
  }

  /// 退会したユーザーからの通知に対するメッセージを表示
  void _showWithdrawnUserMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                Icons.person_off,
                color: AppColors.warning,
                size: AppDimensions.iconL,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            const Expanded(
              child: Text(
                '利用できません',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'この通知の送信者は退会済みのため、フレンド申請を処理できません。',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  /// フレンド申請承認通知の処理
  Future<void> _handleFriendAccepted(NotificationData notification) async {

    // フレンドリストに移動するなどの処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フレンドが追加されました！'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// イベント申込み通知の処理（運営者への通知）
  Future<void> _handleEventApplication(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['eventId'] == null) {
      _showErrorMessage('申込み情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String;

    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        _showErrorMessage('イベント情報が見つかりません');
        return;
      }

      // 通知画面から参加者管理画面へ直接遷移
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/event_participants_management',
          arguments: {
            'eventId': eventId,
            'eventName': event.name,
            'fromNotification': true, // 通知画面からの遷移フラグ
          },
        );
      }
    } catch (e) {
      _showErrorMessage('エラーが発生しました');
    }
  }

  /// イベント承認/拒否通知の処理（参加者への通知）
  Future<void> _handleEventDecisionNotification(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['eventId'] == null) {
      _showErrorMessage('イベント情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String;

    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        _showErrorMessage('イベント情報が見つかりません');
        return;
      }

      // GameEventに変換
      final gameEvent = await EventConverter.eventToGameEvent(event);

      // イベント詳細画面へ遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: gameEvent),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('エラーが発生しました');
    }
  }

  /// 違反報告通知の処理
  Future<void> _handleViolationReported(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['violationId'] == null) {
      _showErrorMessage('違反報告情報が見つかりません');
      return;
    }

    final violationId = data['violationId'] as String;
    final eventId = data['eventId'] as String? ?? '';
    final eventName = data['eventName'] as String? ?? '';
    final isAnonymous = data['isAnonymous'] as bool? ?? false;

    if (isAnonymous) {
      // 違反者への匿名通知 - 異議申立ダイアログを表示
      await _showAppealDialog(violationId, eventName);
    } else {
      // 運営者への通知 - 違反管理画面に遷移
      _navigateToViolationManagement(eventId, eventName);
    }
  }

  /// 異議申立ダイアログを表示
  Future<void> _showAppealDialog(String violationId, String eventName) async {
    try {
      // 違反記録を取得
      final violationService = ref.read(violationServiceProvider);
      final violation = await violationService.getViolation(violationId);

      if (violation == null) {
        _showErrorMessage('違反記録が見つかりません');
        return;
      }

      // 既に異議申立済みの場合
      if (violation.appealText != null && violation.appealText!.isNotEmpty) {
        _showErrorMessage('この違反記録には既に異議申立が提出されています');
        return;
      }

      // 異議申立ダイアログを表示
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppealDialog(
          violation: violation,
          eventName: eventName,
        ),
      );
    } catch (e) {
      _showErrorMessage('エラーが発生しました: $e');
    }
  }

  /// 異議申立通知の処理
  Future<void> _handleAppealSubmitted(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['eventId'] == null) {
      _showErrorMessage('イベント情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String;
    final eventName = data['eventName'] as String? ?? '';

    // 違反管理画面に遷移
    _navigateToViolationManagement(eventId, eventName);
  }

  /// 異議申立処理完了通知の処理
  Future<void> _handleAppealProcessed(NotificationData notification) async {
    final data = notification.data;
    if (data == null) {
      _showErrorMessage('通知データが見つかりません');
      return;
    }

    final appealStatus = data['appealStatus'] as String?;
    final appealResponse = data['appealResponse'] as String?;

    // 処理結果の詳細を表示
    String title = '';
    String message = '';
    Color backgroundColor = AppColors.info;

    if (appealStatus == 'approved') {
      title = '異議申立が承認されました';
      message = '違反記録が取り消されました。';
      backgroundColor = AppColors.success;
    } else if (appealStatus == 'rejected') {
      title = '異議申立が却下されました';
      message = '違反記録が維持されます。';
      backgroundColor = AppColors.warning;
    } else {
      message = '異議申立の処理が完了しました。';
    }

    if (appealResponse != null && appealResponse.isNotEmpty) {
      message += '\n\n運営からの回答:\n$appealResponse';
    }

    // 詳細ダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  /// 違反管理画面に遷移
  void _navigateToViolationManagement(String eventId, String eventName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViolationManagementScreen(
          eventId: eventId,
          eventName: eventName,
        ),
      ),
    );
  }

  /// イベント中止通知の処理
  Future<void> _handleEventCancelNotification(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['eventId'] == null) {
      _showErrorMessage('イベント情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String;

    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        _showErrorMessage('イベント情報が見つかりません');
        return;
      }

      // GameEventに変換
      final gameEvent = await EventConverter.eventToGameEvent(event);

      // イベント詳細画面へ遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: gameEvent),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('エラーが発生しました');
    }
  }

  /// イベント更新通知の処理
  Future<void> _handleEventUpdatedNotification(NotificationData notification) async {
    final data = notification.data;
    if (data == null || data['eventId'] == null) {
      _showErrorMessage('イベント情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String;

    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        _showErrorMessage('イベント情報が見つかりません');
        return;
      }

      // GameEventに変換
      final gameEvent = await EventConverter.eventToGameEvent(event);

      // イベント詳細画面へ遷移
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: gameEvent),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('エラーが発生しました');
    }
  }

  /// エラーメッセージを表示
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
