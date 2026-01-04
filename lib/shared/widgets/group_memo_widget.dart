import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'marquee_text.dart';

/// グループ管理者専用メモ機能
/// 管理者のみが閲覧・編集可能なグループメモ
class GroupMemoWidget extends StatefulWidget {
  final String eventId;
  final String groupId;
  final String groupName;
  final String? currentUserId;

  const GroupMemoWidget({
    super.key,
    required this.eventId,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  @override
  State<GroupMemoWidget> createState() => _GroupMemoWidgetState();
}

class _GroupMemoWidgetState extends State<GroupMemoWidget> {
  String _memo = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  /// グループメモを読み込み
  Future<void> _loadMemo() async {
    try {
      setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('group_memos')
          .doc('${widget.eventId}_${widget.groupId}')
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _memo = data?['memo']?.toString() ?? '';
        });
      }
    } catch (e) {
      // 読み込みエラーは無視
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// グループメモを保存
  Future<void> _saveMemo(String memo) async {
    if (widget.currentUserId == null) return;

    try {
      setState(() => _isSaving = true);

      final docRef = FirebaseFirestore.instance
          .collection('group_memos')
          .doc('${widget.eventId}_${widget.groupId}');

      final data = {
        'eventId': widget.eventId,
        'groupId': widget.groupId,
        'memo': memo.trim(),
        'updatedBy': widget.currentUserId!,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (memo.trim().isEmpty) {
        // 空の場合は削除
        await docRef.delete();
      } else {
        await docRef.set(data, SetOptions(merge: true));
      }

      setState(() => _memo = memo.trim());

      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupMemoSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.groupMemoSaveFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// メモ編集ダイアログを表示
  void _showMemoEditDialog() {
    final controller = TextEditingController(text: _memo);
    final l10n = L10n.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.note_add, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: MarqueeText(
                text: l10n.groupMemoDialogTitle(widget.groupName),
                style: const TextStyle(fontSize: AppDimensions.fontSizeL),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.warning,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Expanded(
                      child: Text(
                        l10n.groupMemoAdminOnly,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeXS,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppTextFieldMultiline(
                controller: controller,
                label: l10n.groupMemoLabel,
                hintText: l10n.groupMemoHint,
                maxLines: 5,
                minLines: 3,
                doneButtonText: l10n.doneButtonLabel,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: _isSaving ? l10n.saving : l10n.save,
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pop(context);
                    _saveMemo(controller.text);
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 権限チェック：管理者のみ表示
    if (widget.currentUserId == null) {
      return const SizedBox.shrink();
    }

    final l10n = L10n.of(context);

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showMemoEditDialog,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: _memo.isNotEmpty
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.textSecondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: _memo.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _memo.isNotEmpty ? Icons.note : Icons.note_add,
                  size: AppDimensions.iconS,
                  color: _memo.isNotEmpty
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Expanded(
                  child: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.textSecondary),
                          ),
                        )
                      : Text(
                          _memo.isNotEmpty ? _memo : l10n.groupMemoAdd,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: _memo.isNotEmpty
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontStyle: _memo.isEmpty ? FontStyle.italic : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                const SizedBox(width: AppDimensions.spacingXS),
                Icon(
                  Icons.edit,
                  size: AppDimensions.iconXS,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}