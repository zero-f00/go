import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';

/// 違反管理画面
class ViolationManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;

  const ViolationManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<ViolationManagementScreen> createState() =>
      _ViolationManagementScreenState();
}

class _ViolationManagementScreenState
    extends ConsumerState<ViolationManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // サンプルデータ（後でFirestore連携）
  List<ViolationRecord> _violations = [];
  List<ViolationRecord> _warnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadViolationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadViolationData() async {
    // TODO: 実際のFirestoreからのデータ取得
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _violations = [
        ViolationRecord(
          id: 'violation1',
          userId: 'user1',
          userName: 'Player123',
          violationType: ViolationType.harassment,
          description: 'チャットでの不適切な発言',
          severity: ViolationSeverity.moderate,
          reportedBy: 'moderator1',
          reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
          status: ViolationStatus.resolved,
          penalty: '警告1回',
        ),
        ViolationRecord(
          id: 'violation2',
          userId: 'user2',
          userName: 'Gamer456',
          violationType: ViolationType.cheating,
          description: '不正なソフトウェアの使用疑い',
          severity: ViolationSeverity.severe,
          reportedBy: 'admin',
          reportedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          status: ViolationStatus.pending,
          penalty: null,
        ),
      ];

      _warnings = _violations
          .where((v) => v.severity == ViolationSeverity.minor ||
                      v.severity == ViolationSeverity.moderate)
          .toList();

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
                title: '違反管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              _buildEventInfo(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildViolationsTab(),
                    _buildWarningsTab(),
                    _buildStatisticsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reportViolation,
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.report, color: Colors.white),
        label: const Text(
          '違反報告',
          style: TextStyle(color: Colors.white),
        ),
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
            Icons.shield,
            color: AppColors.error,
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
          Tab(text: '違反記録'),
          Tab(text: '警告履歴'),
          Tab(text: '統計'),
        ],
      ),
    );
  }

  /// 違反記録タブ
  Widget _buildViolationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _violations.length,
        itemBuilder: (context, index) {
          return _buildViolationCard(_violations[index]);
        },
      ),
    );
  }

  /// 違反カード
  Widget _buildViolationCard(ViolationRecord violation) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _getSeverityColor(violation.severity).withValues(alpha: 0.3),
        ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      violation.userName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      _getViolationTypeText(violation.violationType),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSeverityBadge(violation.severity),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              violation.description,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: AppDimensions.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '報告日時: ${_formatDateTime(violation.reportedAt)}',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(violation.status),
            ],
          ),
          if (violation.penalty != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Icon(
                  Icons.gavel,
                  size: AppDimensions.iconS,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  'ペナルティ: ${violation.penalty}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewViolationDetail(violation),
                  icon: const Icon(Icons.visibility),
                  label: const Text('詳細'),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              if (violation.status == ViolationStatus.pending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveViolation(violation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('処理'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 重要度バッジ
  Widget _buildSeverityBadge(ViolationSeverity severity) {
    final color = _getSeverityColor(severity);
    final text = _getSeverityText(severity);

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
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// ステータスバッジ
  Widget _buildStatusBadge(ViolationStatus status) {
    Color color;
    String text;

    switch (status) {
      case ViolationStatus.pending:
        color = AppColors.warning;
        text = '未処理';
        break;
      case ViolationStatus.resolved:
        color = AppColors.success;
        text = '処理済み';
        break;
      case ViolationStatus.dismissed:
        color = AppColors.textSecondary;
        text = '却下';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  /// 警告履歴タブ
  Widget _buildWarningsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: ListView.builder(
        itemCount: _warnings.length,
        itemBuilder: (context, index) {
          return _buildWarningCard(_warnings[index]);
        },
      ),
    );
  }

  /// 警告カード
  Widget _buildWarningCard(ViolationRecord warning) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
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
              Icon(
                Icons.warning,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  warning.userName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                _formatDateTime(warning.reportedAt),
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            warning.description,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// 統計タブ
  Widget _buildStatisticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalViolations = _violations.length;
    final pendingViolations = _violations.where((v) => v.status == ViolationStatus.pending).length;
    final severeViolations = _violations.where((v) => v.severity == ViolationSeverity.severe).length;
    final warningsCount = _warnings.length;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        children: [
          _buildStatCard(
            '総違反件数',
            '$totalViolations',
            Icons.report_problem,
            AppColors.error,
          ),
          _buildStatCard(
            '未処理件数',
            '$pendingViolations',
            Icons.pending,
            AppColors.warning,
          ),
          _buildStatCard(
            '重大違反',
            '$severeViolations',
            Icons.dangerous,
            AppColors.error,
          ),
          _buildStatCard(
            '警告履歴',
            '$warningsCount',
            Icons.warning,
            AppColors.warning,
          ),
        ],
      ),
    );
  }

  /// 統計カード
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingL),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXL,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ヘルパーメソッド
  Color _getSeverityColor(ViolationSeverity severity) {
    switch (severity) {
      case ViolationSeverity.minor:
        return AppColors.info;
      case ViolationSeverity.moderate:
        return AppColors.warning;
      case ViolationSeverity.severe:
        return AppColors.error;
    }
  }

  String _getSeverityText(ViolationSeverity severity) {
    switch (severity) {
      case ViolationSeverity.minor:
        return '軽微';
      case ViolationSeverity.moderate:
        return '中程度';
      case ViolationSeverity.severe:
        return '重大';
    }
  }

  String _getViolationTypeText(ViolationType type) {
    switch (type) {
      case ViolationType.harassment:
        return 'ハラスメント';
      case ViolationType.cheating:
        return 'チート・不正行為';
      case ViolationType.spam:
        return 'スパム・迷惑行為';
      case ViolationType.abusiveLanguage:
        return '暴言・不適切な発言';
      case ViolationType.other:
        return 'その他';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// アクションメソッド
  void _reportViolation() {
    // TODO: 違反報告ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('違反報告（準備中）')),
    );
  }

  void _viewViolationDetail(ViolationRecord violation) {
    // TODO: 違反詳細表示ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${violation.userName}の違反詳細（準備中）')),
    );
  }

  void _resolveViolation(ViolationRecord violation) {
    // TODO: 違反処理ダイアログ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${violation.userName}の違反処理（準備中）')),
    );
  }
}

/// 違反記録モデル
class ViolationRecord {
  final String id;
  final String userId;
  final String userName;
  final ViolationType violationType;
  final String description;
  final ViolationSeverity severity;
  final String reportedBy;
  final DateTime reportedAt;
  final ViolationStatus status;
  final String? penalty;

  ViolationRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.violationType,
    required this.description,
    required this.severity,
    required this.reportedBy,
    required this.reportedAt,
    required this.status,
    this.penalty,
  });
}

/// 違反タイプ
enum ViolationType {
  harassment,
  cheating,
  spam,
  abusiveLanguage,
  other,
}

/// 違反の重要度
enum ViolationSeverity {
  minor,
  moderate,
  severe,
}

/// 違反のステータス
enum ViolationStatus {
  pending,
  resolved,
  dismissed,
}