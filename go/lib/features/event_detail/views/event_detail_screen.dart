import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/participation_dialog.dart';
import '../../../shared/widgets/user_tag_widget.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/utils/event_converter.dart';
import '../../game_event_management/models/game_event.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final GameEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Color _getStatusColor(GameEventStatus status) {
    switch (status) {
      case GameEventStatus.upcoming:
        return AppColors.info;
      case GameEventStatus.active:
        return AppColors.success;
      case GameEventStatus.completed:
        return AppColors.statusCompleted;
      case GameEventStatus.expired:
        return AppColors.statusExpired;
      case GameEventStatus.cancelled:
        return AppColors.statusExpired;
      case GameEventStatus.draft:
        return AppColors.warning;
      case GameEventStatus.published:
        return AppColors.success;
    }
  }

  /// 現在のユーザーがイベントの管理者かどうか確認
  bool _isEventManager(WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final currentUserDataAsync = ref.watch(currentUserDataProvider);

    if (!isSignedIn) {
      return false;
    }

    return currentUserDataAsync.when(
      data: (userData) {
        if (userData == null) return false;

        final currentUserId = userData.id;
        return widget.event.managers.contains(currentUserId);
      },
      loading: () => false,
      error: (_, __) => false,
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
                title: widget.event.name,
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildScheduleSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildGameInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    if (widget.event.prizeContent != null) ...[
                      _buildPrizeSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    _buildParticipationSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    if (widget.event.rules != null) ...[
                      _buildRulesSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    if (widget.event.hasStreaming &&
                        widget.event.streamingUrl != null) ...[
                      _buildStreamingSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    if (widget.event.contactInfo != null) ...[
                      _buildContactSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    if (widget.event.policy != null) ...[
                      _buildPolicySection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    if (widget.event.additionalInfo != null) ...[
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],
                    _buildManagementInfoSection(),
                    const SizedBox(height: AppDimensions.spacingXL),
                    _buildActionButtons(context, ref),
                    const SizedBox(height: AppDimensions.spacingL),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
  }) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionContainer(
      title: 'イベント概要',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.event.subtitle != null) ...[
                    Text(
                      widget.event.subtitle!,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                  ],
                  Text(
                    widget.event.description,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            _buildInfoChip(
              widget.event.type.displayName,
              Icons.category,
              AppColors.primary,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            _buildInfoChip(
              widget.event.visibility,
              Icons.visibility,
              AppColors.info,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            _buildInfoChip(
              widget.event.language,
              Icons.language,
              AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor(widget.event.status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: _getStatusColor(widget.event.status).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Text(
        widget.event.status.displayName,
        style: TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: _getStatusColor(widget.event.status),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconS, color: color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
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

  Widget _buildScheduleSection() {
    // ロケール初期化に失敗した場合はデフォルトロケールを使用
    DateFormat dateFormat;
    try {
      dateFormat = DateFormat('yyyy/MM/dd (E) HH:mm', 'ja_JP');
    } catch (e) {
      // フォールバック: デフォルトロケール使用
      dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    }

    return _buildSectionContainer(
      title: 'スケジュール',
      children: [
        _buildInfoRow(
          '開催日時',
          dateFormat.format(widget.event.startDate),
          Icons.event,
        ),
        if (widget.event.registrationDeadline != null) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoRow(
            '申込期限',
            dateFormat.format(widget.event.registrationDeadline!),
            Icons.event_busy,
          ),
        ],
      ],
    );
  }

  Widget _buildGameInfoSection() {
    return _buildSectionContainer(
      title: 'ゲーム情報',
      children: [
        if (widget.event.gameName != null) ...[
          Row(
            children: [
              if (widget.event.gameIconUrl != null) ...[
                Container(
                  width: AppDimensions.iconXL,
                  height: AppDimensions.iconXL,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    image: DecorationImage(
                      image: NetworkImage(widget.event.gameIconUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
              ],
              Expanded(
                child: Text(
                  widget.event.gameName!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (widget.event.platforms.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingXS,
              children: widget.event.platforms.map((platform) {
                return _buildInfoChip(
                  platform,
                  Icons.devices,
                  AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ] else ...[
          const Text(
            'ゲーム情報が設定されていません',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrizeSection() {
    return _buildSectionContainer(
      title: '賞品・報酬',
      children: [
        Text(
          widget.event.prizeContent!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
        if (widget.event.rewards.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingM),
          const Text(
            'ゲーム内報酬',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingXS,
            children: widget.event.rewards.entries.map((reward) {
              return _buildInfoChip(
                '${reward.key}: ${reward.value.round()}',
                Icons.emoji_events,
                AppColors.accent,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipationSection() {
    return _buildSectionContainer(
      title: '参加情報',
      children: [
        _buildInfoRow('募集人数', '${widget.event.maxParticipants}人', Icons.group),
        const SizedBox(height: AppDimensions.spacingM),
        _buildInfoRow(
          '現在の参加者数',
          '${widget.event.participantCount}人',
          Icons.people,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildInfoRow('承認方法', widget.event.approvalMethod, Icons.approval),
        if (widget.event.hasFee) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoRow(
            '参加費',
            widget.event.feeAmount != null
                ? '${widget.event.feeAmount!.round()}円'
                : '有料',
            Icons.paid,
          ),
          if (widget.event.feeSupplement != null &&
              widget.event.feeSupplement!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            _buildFeeSupplementInfo(widget.event.feeSupplement!),
          ],
        ] else ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoRow('参加費', '無料', Icons.free_breakfast),
        ],
        if (widget.event.hasAgeRestriction && widget.event.minAge != null) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoRow('年齢制限', '${widget.event.minAge}歳以上', Icons.child_care),
        ],
      ],
    );
  }

  Widget _buildRulesSection() {
    return _buildSectionContainer(
      title: 'ルール・規約',
      children: [
        Text(
          widget.event.rules!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingSection() {
    return _buildSectionContainer(
      title: '配信情報',
      children: [
        _buildInfoRow('配信URL', widget.event.streamingUrl!, Icons.live_tv),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSectionContainer(
      title: '問い合わせ先',
      children: [
        Text(
          widget.event.contactInfo!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicySection() {
    return _buildSectionContainer(
      title: 'プライバシーポリシー',
      children: [
        Text(
          widget.event.policy!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSectionContainer(
      title: 'その他情報',
      children: [
        Text(
          widget.event.additionalInfo!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementInfoSection() {
    return _buildSectionContainer(
      title: '管理情報',
      children: [
        if (widget.event.eventTags.isNotEmpty) ...[
          const Text(
            'タグ',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Wrap(
            spacing: AppDimensions.spacingS,
            runSpacing: AppDimensions.spacingXS,
            children: widget.event.eventTags.map((tag) {
              return _buildInfoChip(tag, Icons.tag, AppColors.info);
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        // 主催者情報
        if (widget.event.createdBy != null) ...[
          const Text(
            '主催者',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          UserTagWidget(
            userId: widget.event.createdBy!,
            showFullName: true,
            avatarSize: AppDimensions.iconM,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        if (widget.event.sponsors.isNotEmpty) ...[
          const Text(
            'スポンサー',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          UserTagsWidget(
            userIds: widget.event.sponsors,
            showFullName: true,
            avatarSize: AppDimensions.iconM,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        if (widget.event.managers.isNotEmpty) ...[
          const Text(
            '運営者',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          UserTagsWidget(
            userIds: widget.event.managers,
            showFullName: true,
            avatarSize: AppDimensions.iconM,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppDimensions.iconM, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS / 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final isManager = _isEventManager(ref);

    return Column(
      children: [
        // 管理者向けボタン
        if (isManager) ...[
          _buildManagerButtons(context),
          const SizedBox(height: AppDimensions.spacingL),
        ],

        // 動的参加申し込みボタン
        if (!isManager &&
            (widget.event.status == GameEventStatus.upcoming ||
                widget.event.status == GameEventStatus.active)) ...[
          _buildParticipationButton(),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // 共通ボタン
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.borderLight),
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
              Expanded(
                child: AppButton(
                  text: '共有',
                  icon: Icons.share,
                  onPressed: () {
                    // TODO: 共有機能を実装
                  },
                  type: AppButtonType.secondary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: AppButton(
                  text: 'お気に入り',
                  icon: Icons.favorite_border,
                  onPressed: () {
                    // TODO: お気に入り機能を実装
                  },
                  type: AppButtonType.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 管理者向けボタンを構築
  Widget _buildManagerButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'イベント管理',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      'このイベントの管理者権限があります',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'イベント編集',
                  icon: Icons.edit,
                  onPressed: () => _navigateToEventEdit(context),
                  type: AppButtonType.primary,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: AppButton(
                  text: '運営管理',
                  icon: Icons.dashboard,
                  onPressed: () => _navigateToOperationsDashboard(context),
                  type: AppButtonType.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// イベント編集画面への遷移
  void _navigateToEventEdit(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamed('/event_edit', arguments: widget.event).then((_) {
      // 編集から戻った場合、必要に応じて画面を更新
      // TODO: イベントの更新後にデータを再読み込みする処理を実装
    });
  }

  /// 運営ダッシュボード画面への遷移
  void _navigateToOperationsDashboard(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/operations_dashboard',
      arguments: {'eventId': widget.event.id, 'eventName': widget.event.name},
    );
  }

  /// 参加申し込みダイアログを表示
  Future<void> _showParticipationDialog() async {
    try {
      // GameEventをEventに変換
      final eventData = await EventConverter.gameEventToEvent(widget.event);

      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => ParticipationDialog(event: eventData),
        );

        if (result == true && mounted) {
          // 参加申し込み成功時の処理（必要に応じて画面を更新）
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('参加申し込みが完了しました'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      print('Error showing participation dialog: $e');
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

  /// 動的参加申し込みボタンを構築
  Widget _buildParticipationButton() {
    final currentUser = ref.watch(currentUserDataProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return AppButton(
            text: 'ログインが必要です',
            onPressed: null,
            type: AppButtonType.secondary,
            isEnabled: false,
          );
        }

        // 参加申し込み状況を監視
        final participationStatus = ref.watch(
          userParticipationStatusProvider((
            eventId: widget.event.id,
            userId: user.id,
          )),
        );

        return participationStatus.when(
          data: (application) {
            if (application == null) {
              // 未申し込み：通常の申し込みボタン
              return AppButton(
                text: '参加申し込み',
                onPressed: () => _showParticipationDialog(),
                type: AppButtonType.primary,
              );
            }

            // 申し込み済み：状態に応じたボタン表示
            switch (application.status) {
              case ParticipationStatus.pending:
                return Column(
                  children: [
                    AppButton(
                      text: '申し込み済み（承認待ち）',
                      onPressed: null,
                      type: AppButtonType.secondary,
                      isEnabled: false,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      '申し込み日: ${DateFormat('yyyy/MM/dd').format(application.appliedAt)}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              case ParticipationStatus.approved:
                return Column(
                  children: [
                    AppButton(
                      text: '参加確定',
                      onPressed: null,
                      type: AppButtonType.accent,
                      isEnabled: false,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      '参加が承認されました',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );
              case ParticipationStatus.rejected:
                return Column(
                  children: [
                    AppButton(
                      text: '参加申し込みが拒否されました',
                      onPressed: null,
                      type: AppButtonType.danger,
                      isEnabled: false,
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    if (application.rejectionReason != null)
                      Text(
                        '理由: ${application.rejectionReason}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                );
            }
          },
          loading: () => AppButton(
            text: '読み込み中...',
            onPressed: null,
            type: AppButtonType.secondary,
            isEnabled: false,
          ),
          error: (error, stack) => AppButton(
            text: 'エラーが発生しました',
            onPressed: () => _showParticipationDialog(),
            type: AppButtonType.primary,
          ),
        );
      },
      loading: () => AppButton(
        text: '読み込み中...',
        onPressed: null,
        type: AppButtonType.secondary,
        isEnabled: false,
      ),
      error: (error, stack) => AppButton(
        text: 'ログインエラー',
        onPressed: null,
        type: AppButtonType.danger,
        isEnabled: false,
      ),
    );
  }

  /// 参加費用補足情報を構築
  Widget _buildFeeSupplementInfo(String supplement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: AppDimensions.iconS,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              supplement,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
