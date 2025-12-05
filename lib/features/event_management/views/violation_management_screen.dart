import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_selection_violation_modal.dart';
import '../../../shared/widgets/violation_edit_dialog.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/widgets/appeal_dialog.dart';
import '../../../shared/widgets/appeal_process_dialog.dart';
import '../../../data/models/violation_record_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/services/violation_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../features/game_profile/providers/game_profile_provider.dart';
import '../../../features/game_profile/views/game_profile_view_screen.dart';
import '../../../features/profile/views/user_profile_screen.dart';
import '../../../shared/widgets/app_text_field.dart';

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
    extends ConsumerState<ViolationManagementScreen> {
  List<ViolationRecord> _violations = [];
  Map<String, UserData> _userDataCache = {}; // userId -> UserData のマップ
  Map<String, String> _gameUsernameCache = {}; // userId -> gameUsername のマップ
  bool _isLoading = true;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _loadViolationData();
  }

  Future<void> _loadViolationData() async {

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Firestore接続テスト
      final violationService = ref.read(violationServiceProvider);

      // 現在のユーザー情報を取得
      final currentUser = ref.read(currentFirebaseUserProvider);

      // Firestoreコレクションの存在確認
      final collectionExists = await violationService.checkCollectionExists();

      // データが存在しない場合はテストデータを作成
      if (!collectionExists || currentUser == null) {
        if (currentUser != null) {
          try {
            await violationService.createTestViolations(
              eventId: widget.eventId,
              eventName: widget.eventName,
              reporterId: currentUser.uid,
              count: 3,
            );
          } catch (e) {
          }
        }
      }

      // 違反記録データを取得
      List<ViolationRecord> violationsList = [];

      try {
        violationsList = await violationService.getEventViolations(widget.eventId);
      } catch (e) {
        throw Exception('イベント違反記録の取得に失敗: $e');
      }

      // ユーザー名を取得（違反者と報告者両方）
      final userRepository = ref.read(userRepositoryProvider);
      final userIds = violationsList
          .map((v) => v.violatedUserId)
          .toSet();

      // 報告者のIDも追加
      final reporterIds = violationsList
          .map((v) => v.reportedByUserId)
          .toSet();
      userIds.addAll(reporterIds);


      for (final userId in userIds) {
        try {
          final userData = await userRepository.getUserById(userId) ??
              await userRepository.getUserByCustomId(userId);
          if (userData != null) {
            _userDataCache[userId] = userData;
          } else {
          }
        } catch (e) {
        }
      }

      // ゲーム内ユーザー名を取得（違反者のみ）
      try {
        final applicationsStream = ParticipationService.getEventApplications(widget.eventId);
        final applications = await applicationsStream.first;

        for (final application in applications) {
          if (userIds.contains(application.userId) && application.gameUsername != null) {
            _gameUsernameCache[application.userId] = application.gameUsername!;
          }
        }
      } catch (e) {
      }

      if (mounted) {
        setState(() {
          _violations = violationsList;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {

      if (mounted) {
        setState(() {
          // より詳細なエラーメッセージを表示
          _errorMessage = e.toString().contains('permission-denied')
              ? 'Firestoreへのアクセス権限がありません。セキュリティルールを確認してください。'
              : e.toString().contains('Failed to get document')
              ? 'Firestoreへの接続に失敗しました。ネットワーク接続を確認してください。'
              : 'データの取得に失敗しました: $e';
          _isLoading = false;
          // エラーの場合でも空のデータで初期化
          _violations = [];
        });
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
                title: '違反管理',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
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
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.spacingL,
                          AppDimensions.spacingM,
                          AppDimensions.spacingL,
                          4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppColors.error,
                              size: AppDimensions.iconM,
                            ),
                            const SizedBox(width: AppDimensions.spacingS),
                            const Text(
                              '違反管理',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeL,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _showHelpDialog,
                              icon: Icon(
                                Icons.help_outline,
                                color: AppColors.info,
                                size: AppDimensions.iconM,
                              ),
                              tooltip: '操作説明',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _errorMessage != null
                            ? _buildErrorState()
                            : _buildViolationsTab(),
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
          onPressed: _reportViolation,
          backgroundColor: AppColors.error,
          icon: const Icon(Icons.report, color: Colors.white),
          label: const Text(
            '違反報告',
            style: TextStyle(color: Colors.white),
          ),
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
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          child: Row(
            children: [
              Icon(
                Icons.shield,
                color: AppColors.error,
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

  /// 違反記録一覧
  Widget _buildViolationsTab() {
    if (_isLoading) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(AppDimensions.spacingL),
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      );
    }

    if (_violations.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                size: AppDimensions.iconXXL,
                color: AppColors.textLight,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              const Text(
                '違反記録はありません',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              const Text(
                'このイベントでは違反報告がまだありません',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _getSeverityColor(violation.severity).withValues(alpha: 0.5),
          width: 1,
        ),
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
                    // ゲーム内ユーザー名を主表示（ない場合はdisplayNameをフォールバック）
                    Text(
                      _gameUsernameCache[violation.violatedUserId]?.isNotEmpty == true
                          ? _gameUsernameCache[violation.violatedUserId]!
                          : _userDataCache[violation.violatedUserId]?.displayName ?? 'ユーザー不明',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    // 実名をサブ表示（ゲーム内ユーザー名がある場合のみ）
                    if (_gameUsernameCache[violation.violatedUserId]?.isNotEmpty == true &&
                        _userDataCache[violation.violatedUserId]?.displayName != null)
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
                          _userDataCache[violation.violatedUserId]!.displayName,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      _getViolationTypeText(violation.violationType),
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.textDark,
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
                color: AppColors.textDark,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '報告日時: ${_formatDateTime(violation.reportedAt)}',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              _buildStatusBadge(violation.status),
            ],
          ),
          // 異議申立期間表示
          if (violation.status == ViolationStatus.pending && violation.appealDeadline != null)
            _buildAppealDeadlineInfo(violation),
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
          Column(
            children: [
              // 1行目：基本アクション（詳細・編集）
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewViolationDetail(violation),
                      icon: const Icon(Icons.visibility),
                      label: const Text('詳細'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editViolation(violation),
                      icon: const Icon(Icons.edit),
                      label: const Text('編集'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),

              // 2行目：ステータスに応じたアクション
              if (violation.status == ViolationStatus.pending) ...[
                // 未処理の場合
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _canProcessViolation(violation) ? () => _resolveViolation(violation) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canProcessViolation(violation) ? AppColors.accent : AppColors.textLight,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(_canProcessViolation(violation) ? Icons.check : Icons.schedule),
                        label: Text(_canProcessViolation(violation) ? '違反処理' : '異議申立期間中（待機）'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    if (violation.appealText != null && violation.appealText!.isNotEmpty && violation.appealStatus == AppealStatus.pending) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _processAppeal(violation),
                          icon: const Icon(Icons.help_outline),
                          label: const Text('異議申立を処理'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _dismissViolation(violation),
                        icon: const Icon(Icons.cancel),
                        label: const Text('却下'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (violation.status != ViolationStatus.underReview) ...[
                // 処理済み・却下済みの場合
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _revertViolation(violation),
                        icon: const Icon(Icons.undo),
                        label: const Text('未処理に戻す'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: const BorderSide(color: AppColors.info),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // 3行目：削除（すべてのステータスで表示）
              const SizedBox(height: AppDimensions.spacingS),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteViolation(violation),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('削除'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
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
      case ViolationStatus.underReview:
        color = AppColors.info;
        text = '調査中';
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

  /// エラー状態表示
  Widget _buildErrorState() {
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
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ElevatedButton(
              onPressed: _loadViolationData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
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
    return type.displayName;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// イベント詳細画面に遷移
  void _navigateToEventDetail() {
    Navigator.pushNamed(
      context,
      '/event_detail',
      arguments: widget.eventId,
    );
  }

  /// アクションメソッド
  void _reportViolation() {
    UserSelectionViolationModal.show(
      context: context,
      eventId: widget.eventId,
      eventName: widget.eventName,
      onViolationReported: () {
        _loadViolationData();
      },
    );
  }

  void _viewViolationDetail(ViolationRecord violation) {
    _showViolationDetailDialog(violation);
  }

  void _editViolation(ViolationRecord violation) {
    _showViolationEditDialog(violation);
  }

  void _resolveViolation(ViolationRecord violation) {
    _showResolveViolationDialog(violation);
  }

  void _deleteViolation(ViolationRecord violation) {
    _showDeleteViolationDialog(violation);
  }

  void _dismissViolation(ViolationRecord violation) {
    _showDismissViolationDialog(violation);
  }

  void _revertViolation(ViolationRecord violation) {
    _showRevertViolationDialog(violation);
  }

  /// 違反編集ダイアログ
  void _showViolationEditDialog(ViolationRecord violation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ViolationEditDialog(
        violation: violation,
      ),
    ).then((result) {
      // 編集が完了したらデータを再読み込み
      if (result == true) {
        _loadViolationData();
      }
    });
  }

  /// 違反詳細表示ダイアログ
  void _showViolationDetailDialog(ViolationRecord violation) {
    // ゲーム内ユーザー名または実名を取得
    final gameUsername = _gameUsernameCache[violation.violatedUserId];
    final displayName = _userDataCache[violation.violatedUserId]?.displayName;
    final userDisplayName = gameUsername?.isNotEmpty == true ? gameUsername! : (displayName ?? 'ユーザー不明');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('違反詳細 - ${violation.violationType.displayName}'),
            const SizedBox(height: AppDimensions.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
                vertical: AppDimensions.spacingS,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.error,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '違反者: $userDisplayName',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        if (gameUsername?.isNotEmpty == true && displayName != null)
                          Text(
                            '実名: $displayName',
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
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('違反タイプ', violation.violationType.displayName),
              _buildDetailRow('重要度', violation.severity.displayName),
              _buildDetailRow('報告日時', _formatDateTime(violation.reportedAt)),
              _buildReporterRow(context, violation),
              _buildDetailRow('ステータス', violation.status.displayName),
              if (violation.penalty != null)
                _buildDetailRow('ペナルティ', violation.penalty!),
              if (violation.notes != null)
                _buildDetailRow('備考', violation.notes!),
              const SizedBox(height: AppDimensions.spacingM),
              const Text(
                '詳細内容:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppDimensions.fontSizeM,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  violation.description,
                  style: const TextStyle(fontSize: AppDimensions.fontSizeM),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 違反処理ダイアログ
  void _showResolveViolationDialog(ViolationRecord violation) {
    final penaltyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('違反処理'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: penaltyController,
                decoration: const InputDecoration(
                  labelText: 'ペナルティ内容',
                  hintText: '例: 警告1回、1週間参加停止',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: notesController,
                label: '備考（任意）',
                hintText: '処理に関するメモ',
                maxLines: 3,
                doneButtonText: '完了',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (penaltyController.text.trim().isEmpty) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ペナルティ内容を入力してください')),
                  );
                }
                return;
              }

              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception('ユーザーが認証されていません');
                }

                final violationService = ref.read(violationServiceProvider);
                await violationService.resolveViolation(
                  violationId: violation.id!,
                  resolvedByUserId: currentUser.uid,
                  penalty: penaltyController.text.trim(),
                  notes: notesController.text.trim(),
                );

                Navigator.pop(context);
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('違反を処理しました')),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('処理に失敗しました: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('処理する'),
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログ
  void _showDeleteViolationDialog(ViolationRecord violation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: AppDimensions.iconM),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('違反記録削除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ 重要：この操作は取り消せません',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            const Text('この違反記録を完全に削除しますか？'),
            const SizedBox(height: AppDimensions.spacingS),
            const Text(
              '• データベースから完全に削除されます\n'
              '• この操作は元に戻せません\n'
              '• 通常は「却下」の使用を推奨します',
              style: TextStyle(fontSize: AppDimensions.fontSizeS),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception('ユーザーが認証されていません');
                }

                // イベント運営者情報を取得
                final organizerIds = await _getEventOrganizerIds();

                // 通知を送信
                final notificationService = NotificationService.instance;
                await notificationService.sendViolationDeletedNotification(
                  violatedUserId: violation.violatedUserId,
                  reportedByUserId: violation.reportedByUserId,
                  eventId: widget.eventId,
                  eventName: widget.eventName,
                  violationId: violation.id!,
                  deletedByUserId: currentUser.uid,
                  organizerIds: organizerIds,
                );

                // 違反記録を削除
                final violationService = ref.read(violationServiceProvider);
                await violationService.deleteViolation(violation.id!);

                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('違反記録を削除しました。関係者に通知されます。'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// 却下ダイアログ
  void _showDismissViolationDialog(ViolationRecord violation) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.warning, size: AppDimensions.iconM),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('違反記録却下'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ℹ️ 却下について',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              const Text(
                '• 記録は残りますが却下済みになります\n'
                '• 後から「復旧」で未処理に戻せます\n'
                '• 違反として不適切と判断した場合に使用',
                style: TextStyle(fontSize: AppDimensions.fontSizeS),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              const Text('この違反記録を却下しますか？'),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: notesController,
                label: '却下理由（任意）',
                hintText: '却下する理由を記載してください',
                maxLines: 3,
                doneButtonText: '完了',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception('ユーザーが認証されていません');
                }

                // イベント運営者情報を取得
                final organizerIds = await _getEventOrganizerIds();

                // 通知を送信
                final notificationService = NotificationService.instance;
                await notificationService.sendViolationDismissedNotification(
                  violatedUserId: violation.violatedUserId,
                  reportedByUserId: violation.reportedByUserId,
                  eventId: widget.eventId,
                  eventName: widget.eventName,
                  violationId: violation.id!,
                  dismissedByUserId: currentUser.uid,
                  organizerIds: organizerIds,
                  reason: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                // 違反記録を却下
                final violationService = ref.read(violationServiceProvider);
                await violationService.dismissViolation(
                  violationId: violation.id!,
                  resolvedByUserId: currentUser.uid,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('違反記録を却下しました。関係者に通知されます。'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('却下に失敗しました: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('却下'),
          ),
        ],
      ),
    );
  }

  /// 報告者行ウィジェット（タップ可能）
  Widget _buildReporterRow(BuildContext context, ViolationRecord violation) {
    final reporterData = _userDataCache[violation.reportedByUserId];
    final displayName = reporterData?.displayName ?? violation.reportedByUserName;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '報告者:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppDimensions.fontSizeS,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context); // 詳細ダイアログを閉じる
                  UserActionModal.show(
                    context: context,
                    eventId: widget.eventId,
                    eventName: widget.eventName,
                    userId: violation.reportedByUserId,
                    userName: displayName,
                    userData: reporterData,
                    showViolationReport: false, // 報告者自身には違反報告ボタンを表示しない
                    onUserProfileTap: () => _navigateToUserProfile(violation.reportedByUserId),
                    onGameProfileTap: () => _navigateToGameProfile(violation.reportedByUserId, reporterData),
                  );
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingXS,
                    horizontal: AppDimensions.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reporterData?.username != null && reporterData!.username.isNotEmpty)
                        Text(
                          ' (@${reporterData!.username})',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.info,
                          ),
                        ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      Icon(
                        Icons.person,
                        size: AppDimensions.iconS,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 詳細行ウィジェット
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppDimensions.fontSizeS,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
            ),
          ),
        ],
      ),
    );
  }

  /// ユーザープロフィール画面に遷移
  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(userId: userId),
      ),
    );
  }

  /// ゲームプロフィール画面に遷移
  void _navigateToGameProfile(String userId, UserData? userData) async {
    try {
      // ユーザーのゲームプロフィールを取得
      final gameProfileService = ref.read(gameProfileServiceProvider);
      final gameProfiles = await gameProfileService.getUserGameProfiles(userId);

      if (gameProfiles.isEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('このユーザーのゲームプロフィールが見つかりません'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // 複数のゲームプロフィールがある場合は選択ダイアログを表示
      if (gameProfiles.length > 1) {
        final selectedProfile = await _showGameSelectionDialog(gameProfiles);
        if (selectedProfile != null) {
          _navigateToGameProfileView(selectedProfile, userData);
        }
      } else {
        // プロフィールが1つの場合はそのまま遷移
        _navigateToGameProfileView(gameProfiles.first, userData);
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ゲームプロフィールの取得に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ゲーム選択ダイアログを表示
  Future<GameProfile?> _showGameSelectionDialog(List<GameProfile> profiles) async {
    return await showDialog<GameProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームを選択'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: profiles.map((profile) {
              return ListTile(
                title: Text(profile.gameId),
                subtitle: Text(profile.gameUsername),
                onTap: () => Navigator.pop(context, profile),
              );
            }).toList(),
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

  /// ゲームプロフィール画面に遷移
  void _navigateToGameProfileView(GameProfile profile, UserData? userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameProfileViewScreen(
          profile: profile,
          userData: userData,
          gameName: profile.gameId, // ここでは仮にgameIdを使用
          gameIconUrl: null, // 必要に応じて追加
        ),
      ),
    );
  }

  /// ヘルプダイアログを表示
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: AppColors.info,
              size: AppDimensions.iconM,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('違反管理の操作説明'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                '📝 基本操作',
                '違反記録カードにある各ボタンの機能を説明します。',
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpItem(
                Icons.visibility,
                '詳細',
                '違反記録の詳細情報を表示します。',
                AppColors.textSecondary,
              ),
              _buildHelpItem(
                Icons.edit,
                '編集',
                '違反の種類、重要度、説明などを編集できます。',
                AppColors.primary,
              ),
              _buildHelpItem(
                Icons.check,
                '処理',
                '違反を確認し、ペナルティを記録して解決済みにします。',
                AppColors.accent,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpSection(
                '⚠️ 重要な操作',
                '以下の操作は慎重に実行してください。',
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildHelpItem(
                Icons.cancel,
                '却下',
                '違反として不適切と判断した場合に使用。記録は残りますが「却下済み」になります。',
                AppColors.warning,
              ),
              _buildHelpItem(
                Icons.delete,
                '削除',
                'データベースから完全に削除します。この操作は取り消せません。通常は「却下」の使用を推奨します。',
                AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpSection(
                '🔄 復旧機能',
                '誤操作した場合の対処法です。',
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildHelpItem(
                Icons.undo,
                '復旧',
                '処理済み・却下済みの記録を未処理状態に戻します。削除した記録は復旧できません。',
                AppColors.info,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates,
                      color: AppColors.info,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        'ヒント：誤って処理や却下した場合は「復旧」ボタンで元に戻せます',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// ヘルプセクションのヘッダー
  Widget _buildHelpSection(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          description,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// ヘルプアイテム
  Widget _buildHelpItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingXS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconS,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 復旧確認ダイアログ
  void _showRevertViolationDialog(ViolationRecord violation) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('違反記録復旧'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'この違反記録を未処理状態に戻しますか？\n'
                '現在のステータス: ${violation.status.displayName}',
                style: const TextStyle(fontSize: AppDimensions.fontSizeM),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: '復旧理由（任意）',
                  hintText: '復旧する理由を記載してください',
                  border: OutlineInputBorder(),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final violationService = ref.read(violationServiceProvider);
                await violationService.revertViolation(
                  violationId: violation.id!,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );

                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('違反記録を復旧しました'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('復旧に失敗しました: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
            ),
            child: const Text('復旧する'),
          ),
        ],
      ),
    );
  }

  /// 異議申立期間情報表示
  Widget _buildAppealDeadlineInfo(ViolationRecord violation) {
    final violationService = ref.read(violationServiceProvider);
    final remainingHours = violationService.getRemainingAppealHours(violation);
    final canProcess = violationService.canProcessWithoutAppeal(violation);

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (violation.appealText != null && violation.appealText!.isNotEmpty) {
      // 異議申立が提出済み
      statusColor = AppColors.info;
      statusIcon = Icons.help_outline;
      statusText = '異議申立済み - 処理待ち';
    } else if (canProcess) {
      // 期限切れ or 処理可能
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusText = '処理可能';
    } else if (remainingHours != null && remainingHours > 0) {
      // まだ期限内
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = '異議申立期間中 - あと$remainingHours時間';
    } else {
      // 期限切れ
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusText = '異議申立期限切れ - 処理可能';
    }

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingS),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            size: AppDimensions.iconS,
            color: statusColor,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          if (violation.appealDeadline != null)
            Text(
              '期限: ${_formatDateTime(violation.appealDeadline!)}',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeXS,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  /// 違反記録が処理可能かどうかを判定
  bool _canProcessViolation(ViolationRecord violation) {
    final violationService = ref.read(violationServiceProvider);
    return violationService.canProcessWithoutAppeal(violation);
  }

  /// 日付フォーマット（時刻なし）
  String _formatDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}';
  }

  /// イベント運営者IDを取得
  Future<List<String>> _getEventOrganizerIds() async {
    try {
      // 簡易実装：現在のユーザーを含む運営者リストを返す
      // 本来はEventRepositoryから取得すべき
      final currentUser = ref.read(currentFirebaseUserProvider);
      final organizerIds = <String>[
        if (currentUser != null) currentUser.uid,
        // TODO: 実際のイベントの運営者IDをEventRepositoryから取得
      ];
      return organizerIds;
    } catch (e) {
      // エラー時は現在のユーザーのみを返す
      final currentUser = ref.read(currentFirebaseUserProvider);
      return currentUser != null ? [currentUser.uid] : [];
    }
  }

  /// 異議申立処理
  Future<void> _processAppeal(ViolationRecord violation) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AppealProcessDialog(
          violation: violation,
          eventName: widget.eventName,
        ),
      );

      if (result == true) {
        // 処理が完了したら違反リストを再読み込み
        await _loadViolationData();
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}
