import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/services/event_cancellation_service.dart';
import '../../../shared/widgets/app_text_field.dart';

/// イベント中止確認ダイアログ
class EventCancellationDialog extends StatefulWidget {
  final String eventId;
  final String eventName;

  const EventCancellationDialog({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventCancellationDialog> createState() => _EventCancellationDialogState();
}

class _EventCancellationDialogState extends State<EventCancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _selectedReason;

  // 定型的な中止理由
  final List<String> _predefinedReasons = [
    '主催者の都合による中止',
    '参加者不足による中止',
    'サーバー・ネットワークトラブルによる中止',
    'ゲーム側のメンテナンス・障害による中止',
    '緊急事態による中止',
    'その他の理由（詳細は下記に記載）',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacingL),
                _buildWarningMessage(),
                const SizedBox(height: AppDimensions.spacingL),
                _buildReasonSelection(),
                const SizedBox(height: AppDimensions.spacingL),
                _buildCustomReasonInput(),
                const SizedBox(height: AppDimensions.spacingXL),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ヘッダー部分
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.warning,
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
                'イベント中止確認',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                widget.eventName,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 警告メッセージ
  Widget _buildWarningMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.warning,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '重要な注意事項',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          const Text(
            'イベントを中止すると以下の処理が実行されます：',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            '• 承認済み参加者への中止通知\n'
            '• 申込み待ちユーザーへの中止通知\n'
            '• 運営チームメンバーへの中止通知\n'
            '• イベントステータスの「中止」への変更\n\n'
            'この操作は取り消しできません。',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 中止理由選択
  Widget _buildReasonSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '中止理由（必須）',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: _predefinedReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(
                  reason,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                  ),
                ),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// カスタム理由入力
  Widget _buildCustomReasonInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '詳細・補足説明（任意）',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AppTextFieldMultiline(
          controller: _reasonController,
          hintText: '参加者へのメッセージや詳細な説明を入力してください...',
          maxLines: 4,
          maxLength: 500,
          doneButtonText: '完了',
        ),
      ],
    );
  }

  /// アクションボタン
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: _isLoading ? '中止処理中...' : 'イベントを中止する',
            onPressed: _canConfirmCancellation() ? _confirmCancellation : null,
            type: AppButtonType.danger,
            isEnabled: _canConfirmCancellation() && !_isLoading,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'キャンセル',
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            type: AppButtonType.secondary,
            isEnabled: !_isLoading,
          ),
        ),
      ],
    );
  }

  /// 中止確認が可能かチェック
  bool _canConfirmCancellation() {
    return _selectedReason != null && _selectedReason!.isNotEmpty;
  }

  /// イベント中止を実行
  Future<void> _confirmCancellation() async {
    if (!_canConfirmCancellation() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final customReason = _reasonController.text.trim();
      final fullReason = customReason.isEmpty
        ? _selectedReason!
        : '$_selectedReason\n\n$customReason';

      final success = await EventCancellationService.cancelEvent(
        eventId: widget.eventId,
        reason: fullReason,
      );

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('イベントを中止しました。関係者に通知を送信しています。'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('イベント中止処理に失敗しました。再度お試しください。'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}