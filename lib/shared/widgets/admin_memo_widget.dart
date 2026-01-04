import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// 管理者専用ユーザーメモ機能
/// イベントとユーザーに紐づくメモを管理者のみが閲覧・編集可能
class AdminMemoWidget extends StatefulWidget {
  final String eventId;
  final String userId;
  final String userName;
  final String? currentUserId; // 現在のユーザーID（管理者権限チェック用）

  const AdminMemoWidget({
    super.key,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.currentUserId,
  });

  @override
  State<AdminMemoWidget> createState() => _AdminMemoWidgetState();
}

class _AdminMemoWidgetState extends State<AdminMemoWidget> {
  String _memo = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  /// メモを読み込み
  Future<void> _loadMemo() async {
    try {
      setState(() => _isLoading = true);

      final doc = await FirebaseFirestore.instance
          .collection('admin_memos')
          .doc('${widget.eventId}_${widget.userId}')
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

  /// メモを保存
  Future<void> _saveMemo(String memo) async {
    if (widget.currentUserId == null) return;

    try {
      setState(() => _isSaving = true);

      final docRef = FirebaseFirestore.instance
          .collection('admin_memos')
          .doc('${widget.eventId}_${widget.userId}');

      final data = {
        'eventId': widget.eventId,
        'userId': widget.userId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).adminMemoSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).adminMemoSaveFailed),
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
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: AppColors.primary),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                l10n.adminMemoTitle(widget.userName),
                style: const TextStyle(fontSize: AppDimensions.fontSizeL),
                overflow: TextOverflow.ellipsis,
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
                      Icons.lock,
                      color: AppColors.warning,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Expanded(
                      child: Text(
                        l10n.adminMemoOnlyAdminVisible,
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
                label: l10n.adminMemoContentLabel,
                hintText: l10n.adminMemoHint,
                maxLines: 5,
                minLines: 3,
                doneButtonText: l10n.doneButton,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          AppButton.primary(
            text: _isSaving ? l10n.saving : l10n.save,
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pop(dialogContext);
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
                  ? AppColors.info.withValues(alpha: 0.1)
                  : AppColors.textSecondary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: _memo.isNotEmpty
                    ? AppColors.info.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _memo.isNotEmpty ? Icons.note : Icons.note_add,
                  size: AppDimensions.iconS,
                  color: _memo.isNotEmpty
                      ? AppColors.info
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
                          _memo.isNotEmpty ? _memo : L10n.of(context).adminMemoAdd,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeXS,
                            color: _memo.isNotEmpty
                                ? AppColors.info
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