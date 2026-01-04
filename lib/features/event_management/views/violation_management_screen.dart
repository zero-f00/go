import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_selection_violation_modal.dart';
import '../../../shared/widgets/violation_edit_dialog.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/widgets/appeal_process_dialog.dart';
import '../../../data/models/violation_record_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/services/violation_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/utils/withdrawn_user_helper.dart';
import '../../../features/game_profile/providers/game_profile_provider.dart';
import '../../../features/game_profile/views/game_profile_view_screen.dart';
import '../../../features/profile/views/user_profile_screen.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/event_info_card.dart';
import '../../../l10n/app_localizations.dart';

/// 違反管理画面
class ViolationManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventName;
  final bool fromNotification;

  const ViolationManagementScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    this.fromNotification = false,
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

      // Firestoreから違反サービスを取得
      final violationService = ref.read(violationServiceProvider);

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
          // ユーザーデータ取得エラーを無視
        }
      }

      // ゲーム内ユーザー名を取得（違反者のみ）
      try {
        final applications = await ParticipationService.getEventApplicationsFromServer(widget.eventId, forceFromServer: true);

        for (final application in applications) {
          if (userIds.contains(application.userId) && application.gameUsername != null) {
            _gameUsernameCache[application.userId] = application.gameUsername!;
          }
        }
      } catch (e) {
        // ゲーム内ユーザー名取得エラーを無視
      }

      if (mounted) {
        setState(() {
          _violations = violationsList;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        final l10n = L10n.of(context);
        setState(() {
          // より詳細なエラーメッセージを表示
          _errorMessage = e.toString().contains('permission-denied')
              ? l10n.firestorePermissionDeniedError
              : e.toString().contains('Failed to get document')
              ? l10n.firestoreConnectionError
              : l10n.dataFetchError(e.toString());
          _isLoading = false;
          // エラーの場合でも空のデータで初期化
          _violations = [];
        });
      }
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
                title: l10n.violationTitle,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              EventInfoCard(
                eventName: widget.eventName,
                eventId: widget.eventId,
                enableTap: widget.fromNotification,
                iconData: Icons.shield,
                iconColor: AppColors.error,
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
                            Text(
                              l10n.violationRecords,
                              style: const TextStyle(
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
                              tooltip: l10n.operationGuideTooltip,
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
          label: Text(
            l10n.violationReport,
            style: const TextStyle(color: Colors.white),
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
      final l10n = L10n.of(context);
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
              Text(
                l10n.noViolationRecords,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.noViolationReportsYet,
                style: const TextStyle(
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
    final l10n = L10n.of(context);
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
                          : WithdrawnUserHelper.getDisplayUsername(context, _userDataCache[violation.violatedUserId]),
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    // 実名をサブ表示（ゲーム内ユーザー名がある場合のみ）
                    if (_gameUsernameCache[violation.violatedUserId]?.isNotEmpty == true &&
                        _userDataCache[violation.violatedUserId] != null)
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
                          WithdrawnUserHelper.getDisplayUsername(context, _userDataCache[violation.violatedUserId]),
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
                l10n.reportedAt(_formatDateTime(violation.reportedAt)),
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
                  l10n.penaltyValue(violation.penalty!),
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
                      label: Text(l10n.detailButton),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editViolation(violation),
                      icon: const Icon(Icons.edit),
                      label: Text(l10n.editButton),
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
                        label: Text(_canProcessViolation(violation) ? l10n.violationProcessButton : l10n.waitingAppealPeriod),
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
                          label: Text(l10n.processAppeal),
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
                        label: Text(l10n.rejectButton),
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
                        label: Text(l10n.revertToPending),
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
                      label: Text(l10n.deleteButton),
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
    final l10n = L10n.of(context);
    Color color;
    String text;

    switch (status) {
      case ViolationStatus.pending:
        color = AppColors.warning;
        text = l10n.statusPending;
        break;
      case ViolationStatus.underReview:
        color = AppColors.info;
        text = l10n.statusInvestigating;
        break;
      case ViolationStatus.resolved:
        color = AppColors.success;
        text = l10n.statusResolved;
        break;
      case ViolationStatus.dismissed:
        color = AppColors.textSecondary;
        text = l10n.statusRejected;
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
    final l10n = L10n.of(context);
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
              child: Text(l10n.retryButton),
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
    final l10n = L10n.of(context);
    switch (severity) {
      case ViolationSeverity.minor:
        return l10n.severityMinor;
      case ViolationSeverity.moderate:
        return l10n.severityModerate;
      case ViolationSeverity.severe:
        return l10n.severitySevere;
    }
  }

  String _getViolationTypeText(ViolationType type) {
    return type.displayName;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
    final l10n = L10n.of(context);
    // ゲーム内ユーザー名または実名を取得
    final gameUsername = _gameUsernameCache[violation.violatedUserId];
    final displayName = WithdrawnUserHelper.getDisplayUsername(context, _userDataCache[violation.violatedUserId]);
    final userDisplayName = gameUsername?.isNotEmpty == true ? gameUsername! : displayName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.violationDetailTitle(violation.violationType.displayName)),
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
                          l10n.violatorLabel(userDisplayName),
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        if (gameUsername?.isNotEmpty == true && displayName != null && displayName.isNotEmpty)
                          Text(
                            l10n.realNameLabel(displayName),
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
              _buildDetailRow(l10n.violationTypeLabel, violation.violationType.displayName),
              _buildDetailRow(l10n.severityLabel, violation.severity.displayName),
              _buildDetailRow(l10n.reportedAtLabel, _formatDateTime(violation.reportedAt)),
              _buildReporterRow(context, violation),
              _buildDetailRow(l10n.statusLabel, violation.status.displayName),
              if (violation.penalty != null)
                _buildDetailRow(l10n.penaltyLabel, violation.penalty!),
              if (violation.notes != null)
                _buildDetailRow(l10n.notesLabel, violation.notes!),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.detailContentLabel,
                style: const TextStyle(
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
            child: Text(l10n.closeButton),
          ),
        ],
      ),
    );
  }

  /// 違反処理ダイアログ
  void _showResolveViolationDialog(ViolationRecord violation) {
    final l10n = L10n.of(context);
    final penaltyController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.processViolationTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: penaltyController,
                decoration: InputDecoration(
                  labelText: l10n.penaltyContentLabel,
                  hintText: l10n.penaltyContentHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: notesController,
                label: l10n.notesOptionalLabel,
                hintText: l10n.processingNotesHint,
                maxLines: 3,
                doneButtonText: l10n.doneButtonText,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              if (penaltyController.text.trim().isEmpty) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pleaseEnterPenalty)),
                  );
                }
                return;
              }

              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception(l10n.userNotAuthenticated);
                }

                final violationService = ref.read(violationServiceProvider);
                await violationService.resolveViolation(
                  violationId: violation.id!,
                  resolvedByUserId: currentUser.uid,
                  penalty: penaltyController.text.trim(),
                  notes: notesController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.violationProcessed)),
                    );
                  }
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToProcess(e.toString()))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.processButton),
          ),
        ],
      ),
    );
  }

  /// 削除確認ダイアログ
  void _showDeleteViolationDialog(ViolationRecord violation) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: AppDimensions.iconM),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.deleteViolationRecordTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.importantCannotUndo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(l10n.deleteViolationRecordConfirm),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              l10n.deleteViolationRecordWarning,
              style: const TextStyle(fontSize: AppDimensions.fontSizeS),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception(l10n.userNotAuthenticated);
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
                    SnackBar(
                      content: Text(l10n.violationRecordDeleted),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToDelete(e.toString()))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
  }

  /// 却下ダイアログ
  void _showDismissViolationDialog(ViolationRecord violation) {
    final l10n = L10n.of(context);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.warning, size: AppDimensions.iconM),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.rejectViolationRecordTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.aboutRejection,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                l10n.rejectionDescription,
                style: const TextStyle(fontSize: AppDimensions.fontSizeS),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(l10n.rejectViolationRecordConfirm),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: notesController,
                label: l10n.rejectReasonOptionalLabel,
                hintText: l10n.rejectReasonHint,
                maxLines: 3,
                doneButtonText: l10n.doneButtonText,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUser = ref.read(currentFirebaseUserProvider);
                if (currentUser == null) {
                  throw Exception(l10n.userNotAuthenticated);
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
                    SnackBar(
                      content: Text(l10n.violationRecordRejected),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToReject(e.toString()))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.rejectButton),
          ),
        ],
      ),
    );
  }

  /// 報告者行ウィジェット（タップ可能）
  Widget _buildReporterRow(BuildContext context, ViolationRecord violation) {
    final l10n = L10n.of(context);
    final reporterData = _userDataCache[violation.reportedByUserId];
    final displayName = WithdrawnUserHelper.getDisplayUsername(context, reporterData);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              l10n.reporterLabel,
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
                          ' (@${reporterData.username})',
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
    final l10n = L10n.of(context);
    try {
      // ユーザーのゲームプロフィールを取得
      final gameProfileService = ref.read(gameProfileServiceProvider);
      final gameProfiles = await gameProfileService.getUserGameProfiles(userId);

      if (gameProfiles.isEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.gameProfileNotFound),
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
            content: Text(l10n.failedToGetGameProfile(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// ゲーム選択ダイアログを表示
  Future<GameProfile?> _showGameSelectionDialog(List<GameProfile> profiles) async {
    final l10n = L10n.of(context);
    return await showDialog<GameProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectGameTitle),
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
            child: Text(l10n.cancelButton),
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
    final l10n = L10n.of(context);
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
            Text(l10n.violationManagementGuide),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpSection(
                l10n.guideBasicOperations,
                l10n.guideCardButtonsDesc,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpItem(
                Icons.visibility,
                l10n.guideDetailTitle,
                l10n.guideDetailDesc,
                AppColors.textSecondary,
              ),
              _buildHelpItem(
                Icons.edit,
                l10n.guideEditTitle,
                l10n.guideEditDesc,
                AppColors.primary,
              ),
              _buildHelpItem(
                Icons.check,
                l10n.guideProcessTitle,
                l10n.guideProcessDesc,
                AppColors.accent,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpSection(
                l10n.guideImportantOperations,
                l10n.guideCautionOperations,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildHelpItem(
                Icons.cancel,
                l10n.guideRejectTitle,
                l10n.guideRejectDesc,
                AppColors.warning,
              ),
              _buildHelpItem(
                Icons.delete,
                l10n.guideDeleteTitle,
                l10n.guideDeleteDesc,
                AppColors.error,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildHelpSection(
                l10n.guideRestoreFeature,
                l10n.guideMistakeRecovery,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              _buildHelpItem(
                Icons.undo,
                l10n.guideRecoveryTitle,
                l10n.guideRecoveryDesc,
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
                        l10n.guideRecoveryHint,
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
            child: Text(l10n.closeButton),
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
    final l10n = L10n.of(context);
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreViolationRecordTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.restoreViolationRecordConfirm(violation.status.displayName),
                style: const TextStyle(fontSize: AppDimensions.fontSizeM),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: l10n.restoreReasonOptionalLabel,
                  hintText: l10n.restoreReasonHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
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
                    SnackBar(
                      content: Text(l10n.violationRecordRestored),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadViolationData();
              } catch (e) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.failedToRestore(e.toString())),
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
            child: Text(l10n.restoreButton),
          ),
        ],
      ),
    );
  }

  /// 異議申立期間情報表示
  Widget _buildAppealDeadlineInfo(ViolationRecord violation) {
    final l10n = L10n.of(context);
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
      statusText = l10n.appealSubmittedWaiting;
    } else if (canProcess) {
      // 期限切れ or 処理可能
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusText = l10n.processableStatus;
    } else if (remainingHours != null && remainingHours > 0) {
      // まだ期限内
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
      statusText = l10n.appealPeriodRemaining(remainingHours);
    } else {
      // 期限切れ
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusText = l10n.appealDeadlineExpired;
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
              l10n.deadlineLabel(_formatDateTime(violation.appealDeadline!)),
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
            content: Text(L10n.of(context).errorWithDetails(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}
