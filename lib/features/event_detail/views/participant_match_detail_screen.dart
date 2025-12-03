import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/match_result_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/match_report_service.dart';

/// 参加者向け試合詳細画面（閲覧専用）
class ParticipantMatchDetailScreen extends ConsumerWidget {
  final MatchResult match;
  final Map<String, String> participantNames;
  final bool isTeamEvent;
  final String? currentUserId;
  final String? currentUserTeamId;
  final String eventId;
  final String eventName;

  const ParticipantMatchDetailScreen({
    super.key,
    required this.match,
    required this.participantNames,
    required this.isTeamEvent,
    this.currentUserId,
    this.currentUserTeamId,
    required this.eventId,
    required this.eventName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMyMatch = _isUserParticipant();

    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '試合詳細',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMatchHeader(isMyMatch),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildMatchStatus(),
                      if (match.isCompleted) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildMatchResults(),
                      ],
                      if (match.isCompleted && match.individualScores != null && match.individualScores!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildIndividualScores(),
                      ],
                      if (match.notes != null && match.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildNotes(),
                      ],
                      if (match.evidenceImages.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildEvidenceImages(),
                      ],
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildReportStatusSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildReportSection(context),
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

  /// 試合ヘッダー
  Widget _buildMatchHeader(bool isMyMatch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // あなたの試合バッジ（該当する場合のみ）
        if (isMyMatch) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.accent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: AppDimensions.cardElevation,
                  offset: const Offset(0, AppDimensions.shadowOffsetY),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingS),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    Icons.star,
                    size: AppDimensions.iconM,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Text(
                  'あなたの試合',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 試合情報カード
        Container(
          width: double.infinity,
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
              Text(
                match.matchName,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: AppDimensions.iconS,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    _formatDateTime(match.createdAt),
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 試合ステータス
  Widget _buildMatchStatus() {
    return Container(
      width: double.infinity,
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
                Icons.info_outline,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '試合情報',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // ステータス
          _buildInfoRow(
            icon: _getStatusIcon(match.status),
            label: 'ステータス',
            value: match.status.displayName,
            valueColor: _getStatusColor(match.status),
          ),
          const SizedBox(height: AppDimensions.spacingM),

          // 形式
          if (match.matchFormat != null) ...[
            _buildInfoRow(
              icon: Icons.category,
              label: '形式',
              value: match.matchFormat!,
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // 参加者
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isTeamEvent ? Icons.groups : Icons.people,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Text(
                      isTeamEvent ? 'チーム' : '参加者',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                ...match.participants.map((id) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
                  child: Text(
                    '• ${participantNames[id] ?? id}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      fontWeight: _isCurrentParticipant(id) ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 試合結果
  Widget _buildMatchResults() {
    return Container(
      width: double.infinity,
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
                Icons.emoji_events,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '試合結果',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),

          // 勝者
          if (match.winner != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.success,
                    size: AppDimensions.iconM,
                  ),
                  const SizedBox(width: AppDimensions.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '勝者',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeS,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Text(
                          participantNames[match.winner] ?? match.winner!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeL,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
          ],

          // スコア
          if (match.scores.isNotEmpty) ...[
            Text(
              'スコア',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: _buildScoreList(),
              ),
            ),
          ],

          // 完了時刻
          if (match.completedAt != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: AppDimensions.iconS,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  '完了: ${_formatDateTime(match.completedAt!)}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 個人スコア
  Widget _buildIndividualScores() {
    return Container(
      width: double.infinity,
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
                Icons.person,
                color: AppColors.info,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '個人スコア',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: match.individualScores!.entries.map((entry) {
                final isCurrentUser = entry.key == currentUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isCurrentUser) ...[
                            Icon(
                              Icons.star,
                              size: AppDimensions.iconXS,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: AppDimensions.spacingXS),
                          ],
                          Text(
                            participantNames[entry.key] ?? entry.key,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeM,
                              color: AppColors.textDark,
                              fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${entry.value}点',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? AppColors.accent : AppColors.info,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 備考
  Widget _buildNotes() {
    return Container(
      width: double.infinity,
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
                Icons.notes,
                color: AppColors.textSecondary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '備考',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            match.notes!,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 情報行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconS,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textDark,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// スコアリスト構築
  List<Widget> _buildScoreList() {
    final sortedScores = match.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedScores.asMap().entries.map((entry) {
      final index = entry.key;
      final scoreEntry = entry.value;
      final isWinner = scoreEntry.key == match.winner;
      final isCurrentParticipant = _isCurrentParticipant(scoreEntry.key);

      return Padding(
        padding: EdgeInsets.only(
          bottom: index < sortedScores.length - 1 ? AppDimensions.spacingS : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (index == 0) ...[
                    Icon(
                      Icons.emoji_events,
                      size: AppDimensions.iconS,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                  ] else ...[
                    SizedBox(width: AppDimensions.iconS + AppDimensions.spacingXS),
                  ],
                  if (isCurrentParticipant) ...[
                    Icon(
                      Icons.star,
                      size: AppDimensions.iconXS,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                  ],
                  Expanded(
                    child: Text(
                      participantNames[scoreEntry.key] ?? scoreEntry.key,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: isWinner ? FontWeight.w600 : FontWeight.normal,
                        color: isWinner ? AppColors.success : AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${scoreEntry.value}点',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: isWinner ? AppColors.success : AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// ユーザーが参加者かどうか
  bool _isUserParticipant() {
    if (isTeamEvent && currentUserTeamId != null) {
      return match.participants.contains(currentUserTeamId!);
    }
    if (currentUserId != null) {
      return match.participants.contains(currentUserId!);
    }
    return false;
  }

  /// 現在の参加者かどうか
  bool _isCurrentParticipant(String participantId) {
    if (isTeamEvent && currentUserTeamId != null) {
      return participantId == currentUserTeamId;
    }
    if (currentUserId != null) {
      return participantId == currentUserId;
    }
    return false;
  }

  /// ステータスの色を取得
  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return AppColors.info;
      case MatchStatus.inProgress:
        return AppColors.warning;
      case MatchStatus.completed:
        return AppColors.success;
    }
  }

  /// ステータスのアイコンを取得
  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.scheduled:
        return Icons.schedule;
      case MatchStatus.inProgress:
        return Icons.timer;
      case MatchStatus.completed:
        return Icons.check_circle;
    }
  }

  /// 報告状況セクション
  Widget _buildReportStatusSection() {
    return Consumer(
      builder: (context, ref, child) {
        final currentUserId = ref.watch(currentFirebaseUserProvider)?.uid;
        if (currentUserId == null) return const SizedBox.shrink();

        return StreamBuilder<List<MatchReport>>(
          stream: MatchReportService().watchUserReports(currentUserId),
          builder: (context, snapshot) {
            final reports = snapshot.data ?? [];
            final matchReports = reports.where((r) => r.matchId == match.id).toList();

            if (matchReports.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
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
                        Icons.assignment_outlined,
                        color: AppColors.info,
                        size: AppDimensions.iconM,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        'あなたの報告状況',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeL,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  ...matchReports.map((report) => _buildReportItem(report)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 報告アイテム
  Widget _buildReportItem(MatchReport report) {
    Color statusColor;
    IconData statusIcon;

    switch (report.status) {
      case MatchReportStatus.submitted:
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      case MatchReportStatus.reviewing:
        statusColor = AppColors.info;
        statusIcon = Icons.visibility;
        break;
      case MatchReportStatus.resolved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case MatchReportStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                size: AppDimensions.iconS,
                color: statusColor,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                report.issueType,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  report.status.displayName,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            report.description,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          if (report.adminResponse != null) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: AppDimensions.iconXS,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      Text(
                        '運営回答',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    report.adminResponse!,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            '${_formatDateTime(report.createdAt)} 報告',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// エビデンス画像セクション
  Widget _buildEvidenceImages() {
    return Container(
      width: double.infinity,
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
                Icons.image,
                color: AppColors.info,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                'エビデンス画像',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingS,
                  vertical: AppDimensions.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${match.evidenceImages.length}枚',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '運営がアップロードした試合の証拠画像です',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimensions.spacingS,
              mainAxisSpacing: AppDimensions.spacingS,
              childAspectRatio: 1,
            ),
            itemCount: match.evidenceImages.length,
            itemBuilder: (context, index) {
              final imageUrl = match.evidenceImages[index];
              final metadata = match.evidenceImageMetadata?[imageUrl];

              return GestureDetector(
                onTap: () => _showEvidenceImageDialog(context, imageUrl, metadata),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.backgroundLight,
                              child: Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                                size: AppDimensions.iconL,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.backgroundLight,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.accent,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          top: AppDimensions.spacingXS,
                          right: AppDimensions.spacingXS,
                          child: Container(
                            padding: const EdgeInsets.all(AppDimensions.spacingXS),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                            ),
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: AppDimensions.iconXS,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// エビデンス画像拡大表示ダイアログ
  void _showEvidenceImageDialog(BuildContext context, String imageUrl, Map<String, dynamic>? metadata) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // 背景タップで閉じる
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),
            // 画像表示
            Center(
              child: Container(
                margin: const EdgeInsets.all(AppDimensions.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ヘッダー
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppDimensions.radiusM),
                          topRight: Radius.circular(AppDimensions.radiusM),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image,
                            color: AppColors.info,
                            size: AppDimensions.iconM,
                          ),
                          const SizedBox(width: AppDimensions.spacingS),
                          Text(
                            'エビデンス画像',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeL,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 画像
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: AppColors.backgroundLight,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: AppColors.textSecondary,
                                      size: AppDimensions.iconXL,
                                    ),
                                    const SizedBox(height: AppDimensions.spacingS),
                                    Text(
                                      '画像の読み込みに失敗しました',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // メタデータ（あれば表示）
                    if (metadata != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimensions.spacingM),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(AppDimensions.radiusM),
                            bottomRight: Radius.circular(AppDimensions.radiusM),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (metadata['uploaderName'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: AppDimensions.iconS,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppDimensions.spacingS),
                                  Text(
                                    'アップロード者: ${metadata['uploaderName']}',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeS,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.spacingXS),
                            ],
                            if (metadata['uploadedAt'] != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: AppDimensions.iconS,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppDimensions.spacingS),
                                  Text(
                                    'アップロード日時: ${_formatDateTime(DateTime.parse(metadata['uploadedAt']))}',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontSizeS,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 問題報告セクション
  Widget _buildReportSection(BuildContext context) {
    return Container(
      width: double.infinity,
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
                Icons.report_problem,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                '問題の報告',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            '試合結果に誤りがある場合は運営に報告できます',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReportDialog(context),
              icon: Icon(
                Icons.flag,
                size: AppDimensions.iconS,
              ),
              label: Text(
                '問題を報告する',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 問題報告ダイアログを表示
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ReportMatchDialog(
        match: match,
        participantNames: participantNames,
        eventId: eventId,
        eventName: eventName,
      ),
    );
  }

  /// 日時フォーマット
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 試合問題報告ダイアログ
class _ReportMatchDialog extends ConsumerStatefulWidget {
  final MatchResult match;
  final Map<String, String> participantNames;
  final String eventId;
  final String eventName;

  const _ReportMatchDialog({
    required this.match,
    required this.participantNames,
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<_ReportMatchDialog> createState() => _ReportMatchDialogState();
}

class _ReportMatchDialogState extends ConsumerState<_ReportMatchDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIssueType = 'スコア誤り';
  bool _isSubmitting = false;
  final MatchReportService _reportService = MatchReportService();

  final List<String> _issueTypes = [
    'スコア誤り',
    '勝者判定誤り',
    '参加者誤り',
    '試合ステータス誤り',
    'その他',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(
            Icons.report_problem,
            color: AppColors.warning,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          const Text(
            '問題を報告',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 試合情報
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '試合: ${widget.match.matchName}',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '参加者: ${widget.match.participants.map((id) => widget.participantNames[id] ?? id).join(' vs ')}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 問題の種類
            Text(
              '問題の種類',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: DropdownButton<String>(
                value: _selectedIssueType,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedIssueType = newValue;
                    });
                  }
                },
                items: _issueTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),

            // 詳細説明
            Text(
              '詳細説明',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '問題の詳細を説明してください...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('報告する'),
        ),
      ],
    );
  }

  /// 報告を送信
  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('詳細説明を入力してください'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser?.uid == null) {
        throw Exception('ログインが必要です');
      }

      final reportId = await _reportService.submitMatchReport(
        matchId: widget.match.id!,
        reporterId: currentUser!.uid,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        eventId: widget.eventId,
        matchName: widget.match.matchName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('問題を報告しました。運営が確認次第対応いたします。'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('報告の送信に失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}