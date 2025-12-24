import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/event_service.dart';
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

    // 通知はStreamProviderでリアルタイム監視されているため、
    // Pull-to-Refreshは不要（Cloud Functionsからの通知は自動的に反映される）
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingS,
      ),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 通知アイコンを構築
  Widget _buildNotificationIcon(NotificationData notification) {
    // 廃止されたフレンドリクエスト通知の場合はユーザーアイコンを表示（互換性のため）
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
      case NotificationType.eventFull:
        icon = Icons.group_off;
        iconColor = AppColors.warning;
        break;
      case NotificationType.eventCapacityWarning:
        icon = Icons.warning;
        iconColor = AppColors.warning;
        break;
      case NotificationType.eventWaitlist:
        icon = Icons.hourglass_empty;
        iconColor = AppColors.warning;
        break;
      case NotificationType.participantCancelled:
        icon = Icons.cancel_outlined;
        iconColor = AppColors.warning;
        break;
      case NotificationType.system:
        icon = Icons.info;
        iconColor = AppColors.info;
        break;
      case NotificationType.follow:
        icon = Icons.person_add_alt_1;
        iconColor = AppColors.primary;
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
        notification.type == NotificationType.eventRejected ||
        notification.type == NotificationType.eventWaitlist) {
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

    if (notification.type == NotificationType.participantCancelled) {
      _handleParticipantCancelled(notification);
      return;
    }

    if (notification.type == NotificationType.eventUpdated) {
      _handleEventUpdatedNotification(notification);
      return;
    }

    if (notification.type == NotificationType.eventReminder) {
      _handleEventReminderNotification(notification);
      return;
    }

    if (notification.type == NotificationType.eventDraftReverted) {
      _handleEventDraftRevertedNotification(notification);
      return;
    }

    if (notification.type == NotificationType.matchReport) {
      _handleMatchReportNotification(notification);
      return;
    }

    if (notification.type == NotificationType.matchReportResponse) {
      _handleMatchReportResponseNotification(notification);
      return;
    }

    if (notification.type == NotificationType.follow) {
      _handleFollowNotification(notification);
      return;
    }

    if (notification.type == NotificationType.violationProcessed ||
        notification.type == NotificationType.violationDismissed ||
        notification.type == NotificationType.violationDeleted) {
      _handleViolationStatusNotification(notification);
      return;
    }

    if (notification.type == NotificationType.eventFull ||
        notification.type == NotificationType.eventCapacityWarning) {
      _handleEventCapacityNotification(notification);
      return;
    }

    // その他の通知タイプ（system等）は何もしない
  }

  /// イベント招待通知の処理
  Future<void> _handleEventInvitation(NotificationData notification) async {
    final eventData = notification.data;
    if (eventData == null || eventData['eventId'] == null) {
      _showErrorMessage('イベント情報が見つかりません');
      return;
    }

    final eventId = eventData['eventId'] as String;

    try {
      // イベント情報を取得
      final event = await EventService.getEventById(eventId);
      if (event == null) {
        _showErrorMessage('イベントが見つかりません。削除された可能性があります。');
        return;
      }

      // GameEventに変換
      final gameEvent = await EventConverter.eventToGameEvent(event);

      // イベント詳細画面へ遷移（詳細を確認してから参加申請できる）
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: gameEvent),
          ),
        );
      }
    } catch (e) {
      _showErrorMessage('イベント情報の取得中にエラーが発生しました');
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

  /// フレンド申請通知の処理（廃止済み - 既存データ互換性のため残存）
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

      // この機能は廃止されました。相互フォローに移行済みです。
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('この機能は廃止されました'),
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
          'この通知の送信者は退会済みのため、この通知を処理できません。',
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

  /// フレンド申請承認通知の処理（廃止済み - 既存データ互換性のため残存）
  Future<void> _handleFriendAccepted(NotificationData notification) async {

    // この機能は廃止されました。相互フォローに移行済みです。
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('相互フォローになりました！'),
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

  /// 参加キャンセル通知の処理（運営者への通知）
  Future<void> _handleParticipantCancelled(NotificationData notification) async {
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

      // 参加者管理画面へ遷移
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/event_participants_management',
          arguments: {
            'eventId': eventId,
            'eventName': event.name,
            'fromNotification': true, // 通知画面からの遷移フラグ
            'notificationType': 'participantCancelled', // キャンセル通知であることを明示
            'cancelledUserId': data['userId'], // キャンセルしたユーザーID
            'cancelledUserName': data['userName'], // キャンセルしたユーザー名
            'cancellationReason': data['cancellationReason'], // キャンセル理由
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

  /// イベントリマインダー通知の処理
  Future<void> _handleEventReminderNotification(NotificationData notification) async {
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

  /// イベント下書き化通知の処理
  Future<void> _handleEventDraftRevertedNotification(NotificationData notification) async {
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
        // 下書き化されたイベントは取得できない可能性があるため、メッセージを表示
        _showErrorMessage('このイベントは下書き状態のため詳細を表示できません');
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
      _showErrorMessage('このイベントは下書き状態のため詳細を表示できません');
    }
  }

  /// 試合報告通知の処理（運営者向け）
  Future<void> _handleMatchReportNotification(NotificationData notification) async {
    final data = notification.data;
    if (data == null) {
      _showErrorMessage('報告情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String?;
    final matchId = data['matchId'] as String?;
    final matchName = data['matchName'] as String?;

    if (eventId == null || matchId == null) {
      _showErrorMessage('試合情報が見つかりません');
      return;
    }

    try {
      // 試合結果管理画面に遷移
      Navigator.pushNamed(
        context,
        '/result_management',
        arguments: {
          'eventId': eventId,
          'eventName': '', // 画面内で取得
          'highlightMatchId': matchId, // 該当試合をハイライト
        },
      );
    } catch (e) {
      _showErrorMessage('画面遷移でエラーが発生しました');
    }
  }

  /// 試合報告回答通知の処理（報告者向け）
  Future<void> _handleMatchReportResponseNotification(NotificationData notification) async {
    final data = notification.data;
    if (data == null) {
      _showErrorMessage('報告情報が見つかりません');
      return;
    }

    final eventId = data['eventId'] as String?;
    final matchId = data['matchId'] as String?;
    final status = data['status'] as String?;

    if (eventId == null || matchId == null) {
      _showErrorMessage('試合情報が見つかりません');
      return;
    }

    try {
      String statusMessage = '';
      switch (status) {
        case 'reviewing':
          statusMessage = '運営が報告内容を確認中です';
          break;
        case 'resolved':
          statusMessage = '報告が解決されました';
          break;
        case 'rejected':
          statusMessage = '報告が却下されました';
          break;
        default:
          statusMessage = '報告の状況が更新されました';
      }

      // ステータスメッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage),
          backgroundColor: status == 'resolved' ? AppColors.success : AppColors.info,
          duration: const Duration(seconds: 3),
        ),
      );

      // 試合結果管理画面に遷移（参加者でも確認可能）
      Navigator.pushNamed(
        context,
        '/result_management',
        arguments: {
          'eventId': eventId,
          'eventName': '', // 画面内で取得
          'highlightMatchId': matchId,
        },
      );
    } catch (e) {
      _showErrorMessage('画面遷移でエラーが発生しました');
    }
  }

  /// フォロー通知の処理
  Future<void> _handleFollowNotification(NotificationData notification) async {
    final fromUserId = notification.fromUserId;
    if (fromUserId == null) {
      _showErrorMessage('ユーザー情報が見つかりません');
      return;
    }

    try {
      // フォロワーのユーザー情報を確認
      // fromUserIdはFirebase UIDなので、getUserByIdで検索
      final userRepository = UserRepository();
      var fromUser = await userRepository.getUserById(fromUserId);

      // Firebase UIDで見つからない場合は、カスタムIDでも検索を試みる
      fromUser ??= await userRepository.getUserByCustomId(fromUserId);

      if (fromUser == null || !fromUser.isActive) {
        _showWithdrawnUserMessage();
        return;
      }

      // フォロワーのプロフィール画面へ遷移（カスタムユーザーIDを使用）
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/user_profile',
          arguments: {'userId': fromUser.userId},
        );
      }
    } catch (e) {
      _showErrorMessage('ユーザー情報の取得中にエラーが発生しました');
    }
  }

  /// 違反ステータス通知の処理（violationProcessed, violationDismissed, violationDeleted）
  Future<void> _handleViolationStatusNotification(NotificationData notification) async {
    final data = notification.data;

    String title = '';
    String message = '';
    IconData icon = Icons.info;
    Color iconColor = AppColors.info;

    switch (notification.type) {
      case NotificationType.violationProcessed:
        title = '違反報告が処理されました';
        message = data?['processedMessage'] as String? ?? '違反報告が運営によって処理されました。';
        icon = Icons.gavel;
        iconColor = AppColors.warning;
        break;
      case NotificationType.violationDismissed:
        title = '違反報告が棄却されました';
        message = data?['dismissReason'] as String? ?? '違反報告の内容が確認できなかったため棄却されました。';
        icon = Icons.cancel;
        iconColor = AppColors.warning;
        break;
      case NotificationType.violationDeleted:
        title = '違反記録が削除されました';
        message = data?['deleteReason'] as String? ?? '違反記録が削除されました。';
        icon = Icons.delete;
        iconColor = AppColors.error;
        break;
      default:
        return;
    }

    // 詳細ダイアログを表示
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
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(icon, color: iconColor, size: AppDimensions.iconL),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
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

  /// イベント定員関連通知の処理（eventFull, eventCapacityWarning）
  Future<void> _handleEventCapacityNotification(NotificationData notification) async {
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
