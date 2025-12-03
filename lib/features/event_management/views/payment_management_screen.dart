import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/payment_model.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/services/payment_service.dart';

/// 参加費管理画面
class PaymentManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const PaymentManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends ConsumerState<PaymentManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  PaymentSummary? _paymentSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPaymentSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 通貨フォーマット
  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Future<void> _loadPaymentSummary() async {
    try {
      final summary = await PaymentService.getPaymentSummary(eventId: widget.eventId);
      setState(() {
        _paymentSummary = summary;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('統計データの取得に失敗しました: $e')),
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
                title: '参加費管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              if (_paymentSummary != null) _buildSummarySection(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  /// 統計サマリーセクション
  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '収支サマリー',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                '総参加者',
                '${_paymentSummary!.totalParticipants}名',
                Icons.people,
                AppColors.info,
              )),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: _buildSummaryCard(
                '支払済',
                '${_paymentSummary!.paidCount}名',
                Icons.check_circle,
                AppColors.success,
              )),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(
                '収集済金額',
                '¥${_formatCurrency(_paymentSummary!.collectedAmount)}',
                Icons.savings,
                AppColors.success,
              )),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: _buildSummaryCard(
                '未収金額',
                '¥${_formatCurrency(_paymentSummary!.pendingAmount)}',
                Icons.pending,
                AppColors.warning,
              )),
            ],
          ),
        ],
      ),
    );
  }

  /// サマリーカード
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconM),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: color,
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'すべて'),
          Tab(text: '未払い'),
          Tab(text: '確認待ち'),
          Tab(text: '完了'),
        ],
      ),
    );
  }

  /// タブバービュー
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPaymentList(null),
        _buildPaymentList(PaymentStatus.pending),
        _buildPaymentList(PaymentStatus.submitted),
        _buildPaymentList(PaymentStatus.verified),
      ],
    );
  }

  /// 支払い記録リスト
  Widget _buildPaymentList(PaymentStatus? statusFilter) {
    return StreamBuilder<List<PaymentRecord>>(
      stream: PaymentService.getPaymentRecordsStream(
        eventId: widget.eventId,
        statusFilter: statusFilter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: AppDimensions.iconXL,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  'データの読み込みに失敗しました',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final paymentRecords = snapshot.data ?? [];

        if (paymentRecords.isEmpty) {
          String message = statusFilter == null
              ? '支払い記録がありません'
              : _getEmptyMessage(statusFilter);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: AppDimensions.iconXL,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          itemCount: paymentRecords.length,
          itemBuilder: (context, index) {
            return _buildPaymentCard(paymentRecords[index]);
          },
        );
      },
    );
  }

  /// 空状態メッセージ
  String _getEmptyMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return '未払いの参加者はいません';
      case PaymentStatus.submitted:
        return '確認待ちの支払いはありません';
      case PaymentStatus.verified:
        return '完了した支払いはありません';
      case PaymentStatus.disputed:
        return '問題のある支払いはありません';
    }
  }

  /// 支払い記録カード
  Widget _buildPaymentCard(PaymentRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _getStatusColor(record.status).withValues(alpha: 0.3),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.participantName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '参加費: ¥${_formatCurrency(record.amount)}',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(record.status),
            ],
          ),
          if (record.participantNotes?.isNotEmpty == true) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '参加者からのメモ',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    record.participantNotes!,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (record.evidenceUrl != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Icon(
                  Icons.attachment,
                  size: AppDimensions.iconS,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    '支払い証跡: ${record.evidenceFileName ?? '証跡あり'}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEvidenceDialog(record),
                  icon: const Icon(Icons.visibility, size: AppDimensions.iconS),
                  label: const Text('確認'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 32),
                  ),
                ),
              ],
            ),
          ],
          if (record.status == PaymentStatus.submitted) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPayment(record, true),
                    icon: const Icon(Icons.check, size: AppDimensions.iconS),
                    label: const Text('承認'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verifyPayment(record, false),
                    icon: const Icon(Icons.close, size: AppDimensions.iconS),
                    label: const Text('差し戻し'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// ステータスバッジ
  Widget _buildStatusBadge(PaymentStatus status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconS, color: color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            text,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ステータス色
  Color _getStatusColor(PaymentStatus status) {
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

  /// ステータステキスト
  String _getStatusText(PaymentStatus status) {
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

  /// ステータスアイコン
  IconData _getStatusIcon(PaymentStatus status) {
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

  /// 証跡確認ダイアログ
  void _showEvidenceDialog(PaymentRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record.participantName}の支払い証跡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (record.evidenceUrl != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  child: Image.network(
                    record.evidenceUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: AppDimensions.iconXL,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (record.participantNotes?.isNotEmpty == true) ...[
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                '参加者からのメモ:',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(record.participantNotes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 支払い確認処理
  Future<void> _verifyPayment(PaymentRecord record, bool isVerified) async {
    try {
      await PaymentService.verifyPayment(
        paymentId: record.id,
        isVerified: isVerified,
        organizerNotes: isVerified ? '支払い確認済み' : '証跡に問題があります',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVerified ? '支払いを承認しました' : '支払いを差し戻しました'),
            backgroundColor: isVerified ? AppColors.success : AppColors.warning,
          ),
        );

        // 統計データを再読み込み
        _loadPaymentSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('処理に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}