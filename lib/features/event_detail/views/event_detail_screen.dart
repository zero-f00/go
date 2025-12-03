import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/participation_dialog.dart';
import '../../../shared/widgets/user_tag.dart';
import '../../../shared/widgets/zoomable_image_widget.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/utils/event_converter.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../shared/services/event_service.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/widgets/user_action_modal.dart';
import '../../../shared/widgets/streaming_player_widget.dart';
import 'participant_match_results_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final GameEvent event;
  final bool shouldNavigateToParticipantManagement;
  final bool fromOperationsDashboard;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.shouldNavigateToParticipantManagement = false,
    this.fromOperationsDashboard = false,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {

  @override
  void initState() {
    super.initState();

    // 通知画面から参加者管理への遷移フラグがある場合、
    // 画面描画後に運営ダッシュボードに遷移する
    if (widget.shouldNavigateToParticipantManagement) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToManagementDashboard();
      });
    }
  }

  /// 運営ダッシュボードに遷移
  void _navigateToManagementDashboard() {
    if (mounted) {
      Navigator.pushNamed(
        context,
        '/event_management_dashboard',
        arguments: {
          'eventId': widget.event.id,
          'eventName': widget.event.name,
          'shouldNavigateToParticipantManagement': widget.shouldNavigateToParticipantManagement,
        },
      );
    }
  }

  /// 戻るボタンの処理
  void _handleBackPressed() {
    if (widget.fromOperationsDashboard) {
      // 運営ダッシュボードからの遷移の場合は通知画面に戻る
      Navigator.of(context).popUntil((route) {
        return route.settings.name == '/notification' || route.isFirst;
      });
    } else {
      // 通常の戻る動作
      Navigator.of(context).pop();
    }
  }

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
        return AppColors.error;
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
        final customUserId = userData.userId;

        // Firebase UIDとカスタムユーザーIDの両方をチェック
        final isManagerByUid = widget.event.managers.contains(currentUserId);
        final isManagerByCustomId = widget.event.managers.contains(customUserId);
        final isCreator = widget.event.createdBy == currentUserId;

        return isManagerByUid || isManagerByCustomId || isCreator;
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// 現在のユーザーが承認済み参加者かどうか確認
  Stream<bool> _isApprovedParticipant(WidgetRef ref) {
    final currentUser = ref.watch(currentFirebaseUserProvider);
    if (currentUser == null) {
      return Stream.value(false);
    }

    return ParticipationService.getEventApplications(widget.event.id).map((applications) {
      return applications.any((app) =>
        app.userId == currentUser.uid &&
        app.status == ParticipationStatus.approved
      );
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
                title: widget.event.name,
                showBackButton: true,
                onBackPressed: () => _handleBackPressed(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  children: [
                    // 1. イベント画像セクション
                    if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty) ...[
                      _buildEventImageSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 2. 基本情報（イベント名・サブタイトル・説明）
                    _buildBasicInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // 2.5. 中止情報（中止されたイベントの場合のみ表示）
                    if (widget.event.status == GameEventStatus.cancelled) ...[
                      _buildCancellationInfoSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 3. イベントタグ（タグがある場合のみ表示）
                    if (widget.event.eventTags.isNotEmpty) ...[
                      _buildEventTagsSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 4. ルール（入力済みの場合のみ表示）
                    if (widget.event.rules != null && widget.event.rules!.isNotEmpty) ...[
                      _buildRulesSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 5. 開催日時・申込期限
                    _buildScheduleSection(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // 6. ゲーム情報・対象プラットフォーム
                    _buildGameInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // 7. 参加情報（最大参加人数等）
                    _buildParticipationSection(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // 8. 追加情報・注意事項（入力済みの場合のみ表示）
                    if (widget.event.additionalInfo != null && widget.event.additionalInfo!.isNotEmpty) ...[
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 9. 参加費用（参加費ありの場合のみ表示）
                    if (widget.event.hasFee) ...[
                      _buildParticipationFeeSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 10. 賞金・スポンサー情報（入力済みの場合のみ表示）
                    if (widget.event.prizeContent != null && widget.event.prizeContent!.isNotEmpty) ...[
                      _buildPrizeSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 11. イベント運営者
                    _buildManagementInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),

                    // 12. 公開範囲・NGユーザー（管理者専用）
                    if (_isEventManager(ref)) ...[
                      _buildAdminOnlySection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 12. 配信プレイヤー（配信予定がある場合のみ表示）
                    if (widget.event.hasStreaming && widget.event.streamingUrls.isNotEmpty) ...[
                      _buildStreamingPlayerSection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],

                    // 14. キャンセル・変更ポリシー（入力済みの場合のみ表示）
                    if (widget.event.policy != null && widget.event.policy!.isNotEmpty) ...[
                      _buildPolicySection(),
                      const SizedBox(height: AppDimensions.spacingL),
                    ],


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
    IconData? icon,
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
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
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
      icon: Icons.info,
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
                        color: AppColors.textLight,
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
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: [
            // スペシャルタイプ以外のみ表示
            if (widget.event.type.displayName != 'スペシャル' &&
                widget.event.type.displayName != 'special' &&
                widget.event.type != GameEventType.special) ...[
              _buildInfoChip(
                widget.event.type.displayName,
                Icons.category,
                AppColors.primary,
              ),
            ],
            _buildInfoChip(
              widget.event.status.displayName,
              Icons.radio_button_checked,
              _getStatusColor(widget.event.status),
            ),
            _buildInfoChip(widget.event.visibility, Icons.visibility, AppColors.info),
            _buildInfoChip(widget.event.language, Icons.language, AppColors.accent),
          ],
        ),
      ],
    );
  }

  /// 中止情報セクションを構築
  Widget _buildCancellationInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1.5,
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
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベント中止のお知らせ',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      'このイベントは中止されました',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.error.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.event.cancellationReason != null &&
              widget.event.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _buildCancellationReasonDisplay(),
          ],
          if (widget.event.cancelledAt != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: AppDimensions.iconS,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Text(
                  '中止日時: ${widget.event.cancelledAt!.month}/${widget.event.cancelledAt!.day} ${widget.event.cancelledAt!.hour.toString().padLeft(2, '0')}:${widget.event.cancelledAt!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
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

  /// 中止理由の詳細表示
  Widget _buildCancellationReasonDisplay() {
    final reason = widget.event.cancellationReason!;

    // 理由が「詳細: 」を含む場合、主要理由と詳細を分離
    String primaryReason = reason;
    String? additionalDetails;

    if (reason.contains('\n\n詳細: ')) {
      final parts = reason.split('\n\n詳細: ');
      if (parts.length >= 2) {
        primaryReason = parts[0];
        additionalDetails = parts.sublist(1).join('\n\n詳細: ');
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: AppDimensions.iconS,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spacingXS),
              const Text(
                '中止理由',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            primaryReason,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (additionalDetails != null && additionalDetails.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: AppDimensions.iconS,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      const Text(
                        '詳細・補足説明',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    additionalDetails,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildEventTagsSection() {
    return _buildSectionContainer(
      title: AppStrings.eventTagsLabel,
      icon: Icons.local_offer,
      children: [
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: widget.event.eventTags
              .map((tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingM,
                      vertical: AppDimensions.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
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
      icon: Icons.schedule,
      children: [
        _buildInfoRow('開催日時', dateFormat.format(widget.event.startDate), Icons.event),
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
      icon: Icons.videogame_asset,
      children: [
        if (widget.event.gameName != null) ...[
          Row(
            children: [
              Container(
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: widget.event.gameIconUrl != null && widget.event.gameIconUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        child: Image.network(
                          widget.event.gameIconUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ EventDetail: Failed to load game icon: ${widget.event.gameIconUrl}');
                            return _buildGameIconFallback();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: AppDimensions.iconM,
                                height: AppDimensions.iconM,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : _buildGameIconFallback(),
              ),
              const SizedBox(width: AppDimensions.spacingM),
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
          Row(
            children: [
              Container(
                width: AppDimensions.iconXL,
                height: AppDimensions.iconXL,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildGameIconFallback(),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ゲーム情報未設定',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      'このイベントではゲーム情報が指定されていません',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrizeSection() {
    return _buildSectionContainer(
      title: '賞金内容',
      icon: Icons.emoji_events,
      children: [
        Text(
          widget.event.prizeContent!,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  '賞金の受け渡しは主催者と参加者間で直接行われます。受け渡し方法や詳細については主催者にお問い合わせください。',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.event.sponsors.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildSponsorInfo(),
        ],
      ],
    );
  }

  /// 参加費用セクションを構築
  Widget _buildParticipationFeeSection() {
    return _buildSectionContainer(
      title: '参加費用',
      icon: Icons.payments,
      children: [
        // 参加費金額表示：feeText（文字列）を優先し、なければfeeAmount（数値）を使用
        if (widget.event.feeText != null && widget.event.feeText!.isNotEmpty) ...[
          _buildInfoRow('参加金額', widget.event.feeText!, Icons.payments),
          const SizedBox(height: AppDimensions.spacingM),
        ] else if (widget.event.feeAmount != null) ...[
          _buildInfoRow('参加金額', '${widget.event.feeAmount!.round()}円', Icons.payments),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        // 参加費補足情報表示
        if (widget.event.feeSupplement != null && widget.event.feeSupplement!.isNotEmpty) ...[
          Text(
            '参加費用補足',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            widget.event.feeSupplement!,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  /// スポンサー情報を構築
  Widget _buildSponsorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.business, size: AppDimensions.iconM, color: AppColors.textLight),
            const SizedBox(width: AppDimensions.spacingS),
            Text(
              'スポンサー',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildClickableUserTagsList(widget.event.sponsors),
      ],
    );
  }

  Widget _buildParticipationSection() {
    return _buildSectionContainer(
      title: '参加情報',
      icon: Icons.group,
      children: [
        _buildInfoRow('募集人数', '${widget.event.maxParticipants}人', Icons.group),
        const SizedBox(height: AppDimensions.spacingM),
        _buildInfoRow('現在の参加者数', '${widget.event.participantCount}人', Icons.people),
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
      icon: Icons.gavel,
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

  Widget _buildStreamingPlayerSection() {
    return _buildSectionContainer(
      title: '配信視聴',
      icon: Icons.live_tv,
      children: [
        StreamingPlayerWidget(
          streamingUrls: widget.event.streamingUrls,
          autoPlay: false,
          showControls: true,
        ),
      ],
    );
  }


  Widget _buildPolicySection() {
    return _buildSectionContainer(
      title: 'キャンセル・変更ポリシー',
      icon: Icons.policy,
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
      title: '追加情報・注意事項',
      icon: Icons.info_outline,
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
    // 運営者リストを構築（managers + createdBy）
    final allManagers = <String>[];
    if (widget.event.managers.isNotEmpty) {
      allManagers.addAll(widget.event.managers);
    }
    if (widget.event.createdBy != null &&
        widget.event.createdBy!.isNotEmpty &&
        !allManagers.contains(widget.event.createdBy!)) {
      allManagers.add(widget.event.createdBy!);
    }

    return _buildSectionContainer(
      title: '運営情報',
      icon: Icons.admin_panel_settings,
      children: [
        // 運営者情報
        if (allManagers.isNotEmpty) ...[
          const Text(
            '運営者',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildClickableUserTagsList(allManagers),
        ],
        // スポンサー情報
        if (widget.event.sponsors.isNotEmpty) ...[
          if (allManagers.isNotEmpty) const SizedBox(height: AppDimensions.spacingM),
          const Text(
            'スポンサー',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildClickableUserTagsList(widget.event.sponsors),
        ],
      ],
    );
  }

  /// 管理者専用情報セクション
  Widget _buildAdminOnlySection() {
    return _buildSectionContainer(
      title: '管理者専用情報',
      icon: Icons.security,
      children: [
        // 公開範囲表示
        _buildInfoRow(
          '公開範囲',
          _getVisibilityDisplayName(),
          Icons.visibility,
        ),

        // イベントパスワード設定状況（招待制の場合）
        if (widget.event.visibility == '招待制') ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoRow(
            'パスワード設定',
            '設定済み', // 招待制イベントの場合は設定済みと表示
            Icons.lock,
          ),
        ],

        // 招待ユーザー一覧（TODO: 実際のデータが必要）
        if (widget.event.visibility == '招待制') ...[
          const SizedBox(height: AppDimensions.spacingM),
          const Text(
            '招待ユーザー',
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
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: AppDimensions.iconS,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Expanded(
                  child: Text(
                    '招待制イベントではパスワード認証により参加を制御しています',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // NGユーザー一覧
        const SizedBox(height: AppDimensions.spacingM),
        const Text(
          'NGユーザー',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildBlockedUsersSection(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppDimensions.iconM, color: AppColors.textLight),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  color: AppColors.textLight,
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

        // 参加者向けメニューボタン（承認済み参加者のみ表示）
        StreamBuilder<bool>(
          stream: _isApprovedParticipant(ref),
          builder: (context, snapshot) {
            final isApproved = snapshot.data ?? false;
            if (isApproved) {
              return Column(
                children: [
                  _buildParticipantMenuButton(context),
                  const SizedBox(height: AppDimensions.spacingL),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // 動的参加申し込みボタン（管理者も参加申込み可能）
        if (widget.event.status == GameEventStatus.upcoming ||
            widget.event.status == GameEventStatus.active) ...[
          _buildParticipationButton(),
          const SizedBox(height: AppDimensions.spacingM),
        ],

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
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          // 管理機能メニュー
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '管理機能',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // イベント編集ボタン
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToEventEdit(context),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spacingS),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: AppColors.primary,
                              size: AppDimensions.iconM,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'イベント編集',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeM,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingXS),
                                Text(
                                  'イベント情報の編集・更新',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeS,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.primary,
                            size: AppDimensions.iconM,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // 運営管理ボタン
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToOperationsDashboard(context),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppDimensions.spacingS),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Icon(
                              Icons.dashboard,
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
                                  '運営管理',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeM,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingXS),
                                Text(
                                  '参加者・グループ・結果管理',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeS,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.accent,
                            size: AppDimensions.iconM,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// イベント編集画面への遷移
  void _navigateToEventEdit(BuildContext context) {
    Navigator.of(context).pushNamed('/event_edit', arguments: widget.event).then((_) {
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

  /// 参加者メニューボタンを構築
  Widget _buildParticipantMenuButton(BuildContext context) {
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
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.success,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '参加者メニュー',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      '承認済み参加者向け機能',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          // 参加者機能メニュー
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '参加者機能',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // グループ情報ボタン
                _buildParticipantFeatureButton(
                  icon: Icons.group,
                  title: 'グループ情報',
                  subtitle: '所属グループの確認',
                  color: AppColors.info,
                  onTap: () => _navigateToParticipantGroupView(context),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // 参加者一覧ボタン
                _buildParticipantFeatureButton(
                  icon: Icons.people,
                  title: '参加者一覧',
                  subtitle: 'イベント参加者の確認',
                  color: AppColors.accent,
                  onTap: () => _navigateToParticipantListView(context),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // 戦績・結果確認ボタン
                _buildParticipantFeatureButton(
                  icon: Icons.analytics,
                  title: '戦績・結果確認',
                  subtitle: '試合結果とランキングの確認',
                  color: AppColors.secondary,
                  onTap: () => _navigateToMatchResults(context),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // 違反報告ボタン
                _buildParticipantFeatureButton(
                  icon: Icons.report_problem,
                  title: '違反報告',
                  subtitle: '迷惑行為の報告',
                  color: AppColors.warning,
                  onTap: () => _navigateToViolationReport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantFeatureButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppDimensions.iconM,
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
                      subtitle,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
                size: AppDimensions.iconM,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 参加者用画面への遷移メソッド
  void _navigateToParticipantGroupView(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/participant_group_view',
      arguments: {
        'eventId': widget.event.id,
        'eventName': widget.event.name,
      },
    );
  }

  void _navigateToParticipantListView(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/participant_list_view',
      arguments: {
        'eventId': widget.event.id,
        'eventName': widget.event.name,
      },
    );
  }

  void _navigateToMatchResults(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParticipantMatchResultsScreen(
          eventId: widget.event.id,
          eventName: widget.event.name,
        ),
      ),
    );
  }

  void _navigateToViolationReport(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/violation_report',
      arguments: {
        'eventId': widget.event.id,
        'eventName': widget.event.name,
      },
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
          userParticipationStatusProvider((eventId: widget.event.id, userId: user.id))
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
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow.withValues(alpha: 0.1),
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
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Icon(
                              Icons.pending_actions,
                              color: AppColors.warning,
                              size: AppDimensions.iconM,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '申し込み済み（承認待ち）',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeL,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingXS),
                                Text(
                                  '申し込み日: ${DateFormat('yyyy/MM/dd').format(application.appliedAt)}',
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
                    ],
                  ),
                );
              case ParticipationStatus.approved:
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow.withValues(alpha: 0.1),
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
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: AppDimensions.iconM,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '参加確定',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeL,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingXS),
                                const Text(
                                  '参加が承認されました',
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
                    ],
                  ),
                );
              case ParticipationStatus.rejected:
                return Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardShadow.withValues(alpha: 0.1),
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
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Icon(
                              Icons.cancel,
                              color: AppColors.error,
                              size: AppDimensions.iconM,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '参加申し込みが拒否されました',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSizeL,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacingXS),
                                if (application.rejectionReason != null)
                                  Text(
                                    '理由: ${application.rejectionReason}',
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
                    ],
                  ),
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
            color: AppColors.textDark,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              supplement,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 公開設定の表示名を取得
  String _getVisibilityDisplayName() {
    return widget.event.visibility;
  }


  /// イベント画像セクションを構築
  Widget _buildEventImageSection() {
    return ZoomableImageWidget(
      imageUrl: widget.event.imageUrl!,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8.0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }


  /// NGユーザー（ブロック済みユーザー）一覧を構築
  Widget _buildBlockedUsersSection() {
    if (widget.event.blockedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: AppDimensions.iconS,
              color: AppColors.success,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            const Expanded(
              child: Text(
                'NGユーザーは設定されていません',
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

    return _buildClickableUserTagsList(widget.event.blockedUsers, isBlockedUsers: true);
  }

  /// クリック可能なユーザータグリストを構築（UserTagデザイン + プロフィール遷移）
  Widget _buildClickableUserTagsList(List<String> userIds, {bool isBlockedUsers = false}) {
    return FutureBuilder<List<UserData>>(
      future: _fetchUsersFromIds(userIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: const Center(
              child: SizedBox(
                width: AppDimensions.iconM,
                height: AppDimensions.iconM,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Text(
              'ユーザー情報の読み込みに失敗しました',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.error,
              ),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Text(
              'ユーザーが見つかりません',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return Wrap(
          children: users.map((user) => GestureDetector(
            onTap: () => _navigateToUserProfile(user.id, isBlockedUser: isBlockedUsers),
            child: UserTag(
              user: user,
              showRemoveButton: false,
              size: AppDimensions.iconL,
            ),
          )).toList(),
        );
      },
    );
  }

  /// ユーザーIDリストからUserDataを取得
  Future<List<UserData>> _fetchUsersFromIds(List<String> userIds) async {
    final userRepository = UserRepository();
    final users = <UserData>[];

    for (final userId in userIds) {
      try {
        // Firebase UIDで検索を試行
        UserData? user = await userRepository.getUserById(userId);
        if (user != null) {
          users.add(user);
        } else {
          // カスタムIDで検索
          user = await userRepository.getUserByCustomId(userId);
          if (user != null) {
            users.add(user);
          }
        }
      } catch (e) {
        // エラーは無視して次のユーザーを処理
      }
    }

    return users;
  }



  /// ユーザープロフィール画面に遷移
  Future<void> _navigateToUserProfile(String userId, {bool isBlockedUser = false}) async {
    try {
      // ユーザー情報を取得
      final userRepository = UserRepository();
      final userData = await userRepository.getUserById(userId);

      if (userData == null) {
        // ユーザー情報が取得できない場合は直接プロフィール画面に遷移
        if (mounted) {
          Navigator.of(context).pushNamed(
            '/user_profile',
            arguments: userId,
          );
        }
        return;
      }

      // UserActionModalを表示
      if (mounted) {
        UserActionModal.show(
          context: context,
          eventId: widget.event.id,
          eventName: widget.event.name,
          userId: userId,
          userName: userData.displayName ?? userData.username,
          userData: userData,
          gameId: widget.event.gameId,
          onGameProfileTap: () {
            // ゲームプロフィール表示
            if (widget.event.gameId != null) {
              Navigator.of(context).pushNamed(
                '/game_profile_view',
                arguments: {
                  'userId': userId,
                  'gameId': widget.event.gameId!,
                },
              );
            }
          },
          onUserProfileTap: () {
            // ユーザープロフィール表示
            Navigator.of(context).pushNamed(
              '/user_profile',
              arguments: userId,
            );
          },
          showViolationReport: isBlockedUser, // NGユーザーの場合のみ違反報告機能を有効化
        );
      }
    } catch (e) {
      // エラー時は直接プロフィール画面に遷移
      if (mounted) {
        Navigator.of(context).pushNamed(
          '/user_profile',
          arguments: userId,
        );
      }
    }
  }

  /// ゲームアイコンのフォールバック表示
  Widget _buildGameIconFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Icon(
        Icons.videogame_asset_outlined,
        color: AppColors.primary,
        size: AppDimensions.iconL,
      ),
    );
  }

}

