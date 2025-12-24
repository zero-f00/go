import 'package:flutter/material.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/services/event_deletion_service.dart';

/// イベント削除確認ダイアログ
class EventDeletionDialog extends StatefulWidget {
  final String eventId;
  final String eventName;
  final bool isDraft;

  const EventDeletionDialog({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.isDraft,
  });

  @override
  State<EventDeletionDialog> createState() => _EventDeletionDialogState();
}

class _EventDeletionDialogState extends State<EventDeletionDialog> {
  bool _isLoading = false;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildWarningMessage(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildConfirmationCheckbox(),
              const SizedBox(height: AppDimensions.spacingXL),
              _buildActionButtons(),
            ],
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
            Icons.delete_forever,
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
                'イベント削除確認',
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
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.error,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '注意',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            widget.isDraft
                ? 'この下書きイベントを完全に削除します。'
                : 'このイベントを完全に削除します。',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            '削除されるデータ:\n'
            '・イベント情報\n'
            '・グループ分け設定\n'
            '・試合結果\n'
            '・リマインダー設定\n'
            '・関連する画像\n\n'
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

  /// 確認チェックボックス
  Widget _buildConfirmationCheckbox() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isConfirmed = !_isConfirmed;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: _isConfirmed ? AppColors.error : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _isConfirmed,
              onChanged: (value) {
                setState(() {
                  _isConfirmed = value ?? false;
                });
              },
              activeColor: AppColors.error,
            ),
            const Expanded(
              child: Text(
                'このイベントを削除することを確認しました',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// アクションボタン
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: _isLoading ? '削除中...' : 'イベントを削除する',
            onPressed: _canDelete() ? _confirmDeletion : null,
            type: AppButtonType.danger,
            isEnabled: _canDelete() && !_isLoading,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'キャンセル',
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
            type: AppButtonType.secondary,
            isEnabled: !_isLoading,
          ),
        ),
      ],
    );
  }

  /// 削除可能かチェック
  bool _canDelete() {
    return _isConfirmed;
  }

  /// イベント削除を実行
  Future<void> _confirmDeletion() async {
    if (!_canDelete() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await EventDeletionService.deleteEvent(widget.eventId);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('イベントを削除しました'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('イベント削除に失敗しました。再度お試しください。'),
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
