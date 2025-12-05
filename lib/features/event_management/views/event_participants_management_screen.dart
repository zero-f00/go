import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../shared/services/payment_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/app_text_field.dart';

/// イベント参加者管理画面
class EventParticipantsManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const EventParticipantsManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
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

  Map<String, UserData> _userDataCache = {};
  Map<String, PaymentRecord> _paymentDataCache = {};

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
                onBackPressed: () => Navigator.of(context).pop(),
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
                            const Text(
                              '参加申請管理',
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
                            Tab(text: '申請中'),
                            Tab(text: '承認済み'),
                            Tab(text: '拒否済み'),
                          ],
                        ),
                      ),
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
                  'データの読み込みに失敗しました',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  'エラー: ${snapshot.error}',
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
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                      backgroundImage: userData?.photoUrl != null
                          ? NetworkImage(userData!.photoUrl!)
                          : null,
                      child: userData?.photoUrl == null
                          ? Text(
                              userData?.displayName != null ? userData!.displayName.substring(0, 1).toUpperCase() : 'U',
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
                            userData?.displayName ?? '読み込み中...',
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (userData?.userId != null)
                            Text(
                              '@${userData!.userId}',
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
                  _buildReturnToPendingButton(application, '承認を取り消して申請中に戻す'),
                ],
                if (status == 'rejected') ...[
                  const SizedBox(height: AppDimensions.spacingL),
                  _buildReturnToPendingButton(application, '拒否を取り消して申請中に戻す'),
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
        textColor = AppColors.textDark;
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

  Widget _buildGameAccountInfo(ParticipationApplication application) {
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
                'ゲームアカウント情報',
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
            _buildInfoRow('ゲーム内ユーザー名', application.gameUsername!),
          ],
          if (application.gameUserId != null && application.gameUserId!.isNotEmpty) ...[
            _buildInfoRow('ゲーム内ユーザーID', application.gameUserId!),
          ],
          if (application.gameUsername == null) ...[
            Text(
              'ゲームアカウント情報が登録されていません',
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
    String dateText = '申請日時: ${_formatDateTime(application.appliedAt)}';

    // Add message if present
    if (application.message != null && application.message!.isNotEmpty) {
      dateText += '\nメッセージ: ${application.message}';
    }

    // Add rejection reason if present
    if (application.rejectionReason != null && application.rejectionReason!.isNotEmpty) {
      dateText += '\n拒否理由: ${application.rejectionReason}';
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
    return Row(
      children: [
        Expanded(
          child: AppButton.primary(
            text: '承認',
            onPressed: () => _approveApplication(application),
            isFullWidth: true,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: AppButton.danger(
            text: '拒否',
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

  Future<PaymentRecord?> _getPaymentData(String participantId) async {
    if (_paymentDataCache.containsKey(participantId)) {
      return _paymentDataCache[participantId];
    }
    try {
      final paymentRecord = await PaymentService.getParticipantPaymentRecord(
        eventId: widget.eventId,
        participantId: participantId,
      );
      if (paymentRecord != null) {
        _paymentDataCache[participantId] = paymentRecord;
      }
      return paymentRecord;
    } catch (e) {
      return null;
    }
  }

  Future<void> _approveApplication(ParticipationApplication application) async {
    final message = await _showApprovalMessageDialog(true);
    if (message == null) return; // キャンセルされた場合

    try {

      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.approved,
        adminMessage: message.isEmpty ? null : message,
      );

      if (result && mounted) {
        // 通知を送信
        await _sendNotificationToUser(
          application.userId,
          application.userDisplayName,
          true,
          message,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('参加申請を承認しました'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('承認に失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorDialog(
          context,
          '承認に失敗しました',
        );
      }
    }
  }

  Future<void> _rejectApplication(ParticipationApplication application) async {
    final message = await _showApprovalMessageDialog(false);
    if (message == null) return; // キャンセルされた場合

    try {

      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.rejected,
        adminMessage: message.isEmpty ? null : message,
      );

      if (result && mounted) {
        // 通知を送信
        await _sendNotificationToUser(
          application.userId,
          application.userDisplayName,
          false,
          message,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('参加申請を拒否しました'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('拒否に失敗しました'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorDialog(
          context,
          '拒否に失敗しました',
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 支払い状況表示
  Widget _buildPaymentStatus(String userId) {
    return FutureBuilder<PaymentRecord?>(
      future: _getPaymentData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: AppDimensions.iconS,
                  height: AppDimensions.iconS,
                  child: const CircularProgressIndicator(strokeWidth: 2.0),
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '支払い状況確認中...',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          );
        }

        final paymentRecord = snapshot.data;

        if (paymentRecord == null) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppDimensions.iconS,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '参加費なし',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
          decoration: BoxDecoration(
            color: _getPaymentStatusColor(paymentRecord.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: _getPaymentStatusColor(paymentRecord.status).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getPaymentStatusIcon(paymentRecord.status),
                size: AppDimensions.iconS,
                color: _getPaymentStatusColor(paymentRecord.status),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '支払い: ${_getPaymentStatusText(paymentRecord.status)}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: _getPaymentStatusColor(paymentRecord.status),
                    ),
                  ),
                  Text(
                    '¥${_formatCurrency(paymentRecord.amount)}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeXS,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 支払いステータス色
  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return AppColors.warning;
      case PaymentStatus.submitted:
        return AppColors.info;
      case PaymentStatus.verified:
        return AppColors.success;
      case PaymentStatus.disputed:
        return AppColors.error;
    }
  }

  /// 支払いステータステキスト
  String _getPaymentStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return '未払い';
      case PaymentStatus.submitted:
        return '確認待ち';
      case PaymentStatus.verified:
        return '確認済み';
      case PaymentStatus.disputed:
        return '問題あり';
    }
  }

  /// 支払いステータスアイコン
  IconData _getPaymentStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.submitted:
        return Icons.upload;
      case PaymentStatus.verified:
        return Icons.check_circle;
      case PaymentStatus.disputed:
        return Icons.error;
    }
  }

  /// 通貨フォーマット
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 承認・拒否メッセージ入力ダイアログ
  Future<String?> _showApprovalMessageDialog(bool isApproval) async {
    final TextEditingController messageController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApproval ? '参加申請を承認' : '参加申請を拒否',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApproval
                  ? '申請者にメッセージを送信できます（任意）'
                  : '拒否理由をメッセージで送信できます（任意）',
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
                labelText: isApproval ? 'メッセージ' : '拒否理由',
                hintText: isApproval
                    ? '承認に関する詳細やイベント参加の注意事項など'
                    : '拒否の理由や今後の改善点など',
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          AppButton.primary(
            text: isApproval ? '承認する' : '拒否する',
            onPressed: () => Navigator.of(context).pop(messageController.text.trim()),
          ),
        ],
      ),
    );
  }

  /// 申請中に戻すダイアログを表示
  Future<String?> _showReturnToPendingDialog(String title, String message) async {
    final TextEditingController messageController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
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
              hintText: '理由を入力...',
              maxLines: 3,
              doneButtonText: '完了',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          AppButton.primary(
            text: '申請中に戻す',
            onPressed: () => Navigator.of(context).pop(messageController.text),
          ),
        ],
      ),
    );
  }

  /// 申請中に戻した際の通知を送信
  Future<void> _sendReturnToPendingNotification(
    String userId,
    String userDisplayName,
    bool isFromApproval,
    String? adminMessage,
  ) async {
    try {
      final title = isFromApproval ? 'イベント参加承認が取り消されました' : 'イベント参加申請状況が変更されました';
      String message = isFromApproval
          ? 'イベント「${widget.eventName}」への参加承認が取り消され、申請中に戻りました。'
          : 'イベント「${widget.eventName}」への参加申請が再度審査中に戻りました。';

      if (adminMessage != null && adminMessage.isNotEmpty) {
        message += '\n\n管理者メッセージ: $adminMessage';
      }

      await NotificationService.instance.createNotification(
        NotificationData(
          toUserId: userId,
          fromUserId: ref.read(authStateProvider).value?.uid ?? '',
          type: NotificationType.eventRejected,
          title: title,
          message: message,
          isRead: false,
          createdAt: DateTime.now(),
          data: {
            'eventId': widget.eventId,
            'eventName': widget.eventName,
            'newStatus': 'pending',
            'previousStatus': isFromApproval ? 'approved' : 'rejected',
            'adminMessage': adminMessage,
          },
        ),
      );
    } catch (e) {
      print('申請中に戻る通知の送信に失敗しました: $e');
    }
  }

  /// 申請者に通知を送信
  Future<void> _sendNotificationToUser(
    String userId,
    String userDisplayName,
    bool isApproval,
    String? adminMessage,
  ) async {
    try {
      final title = isApproval ? 'イベント参加申請が承認されました' : 'イベント参加申請が拒否されました';

      String message = isApproval
          ? 'イベント「${widget.eventName}」への参加申請が承認されました。'
          : 'イベント「${widget.eventName}」への参加申請が拒否されました。';

      if (adminMessage != null && adminMessage.isNotEmpty) {
        message += '\n\n運営からのメッセージ:\n$adminMessage';
      }

      await NotificationService.sendNotification(
        toUserId: userId,
        type: isApproval ? 'event_approved' : 'event_rejected',
        title: title,
        message: message,
        data: {
          'eventId': widget.eventId,
          'eventName': widget.eventName,
          'isApproval': isApproval.toString(),
          'adminMessage': adminMessage ?? '',
        },
      );

    } catch (e) {
      // 通知送信エラーは UI には表示しない（メインの処理は成功しているため）
    }
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
        Navigator.of(context).pushNamed(
          '/user_profile',
          arguments: userData.userId, // カスタムユーザーIDを使用
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー情報が見つかりません'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザープロフィールの表示に失敗しました'),
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
    // ゲームプロフィール表示の実装
    // 必要に応じて実装してください
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
    final currentStatus = application.status;
    final isFromApproval = currentStatus == ParticipationStatus.approved;

    final title = isFromApproval ? '承認を取り消しますか？' : '拒否を取り消しますか？';
    final confirmMessage = isFromApproval
        ? 'この参加者の承認を取り消して申請中に戻します。理由を入力してください（任意）。'
        : 'この参加者の拒否を取り消して申請中に戻します。理由を入力してください（任意）。';

    final message = await _showReturnToPendingDialog(title, confirmMessage);
    if (message == null) return;

    try {
      final result = await ParticipationService.updateApplicationStatus(
        application.id,
        ParticipationStatus.pending,
        adminMessage: message.isEmpty
            ? (isFromApproval ? '承認が取り消されました' : '拒否が取り消されました')
            : message,
      );

      if (result && mounted) {
        final successMessage = isFromApproval ? '承認を取り消して申請中に戻しました' : '拒否を取り消して申請中に戻しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );

        // 申請者に通知を送信（申請中に戻ったことを通知）
        await _sendReturnToPendingNotification(
          application.userId,
          application.userDisplayName,
          isFromApproval,
          message.isEmpty
              ? (isFromApproval ? '承認が取り消され、申請中に戻りました' : '拒否が取り消され、申請中に戻りました')
              : message,
        );
      } else if (mounted) {
        final errorMessage = isFromApproval ? '承認取り消しに失敗しました' : '拒否取り消しに失敗しました';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = isFromApproval ? '承認取り消しに失敗しました' : '拒否取り消しに失敗しました';
        ErrorHandlerService.showErrorDialog(
          context,
          errorMessage,
        );
      }
    }
  }
}