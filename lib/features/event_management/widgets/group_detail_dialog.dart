import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/services/group_management_service.dart';

/// グループ詳細表示ダイアログ
class GroupDetailDialog extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailDialog({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupDetailDialog> createState() => _GroupDetailDialogState();
}

class _GroupDetailDialogState extends ConsumerState<GroupDetailDialog> {
  GroupDetail? _groupDetail;
  bool _isLoading = true;
  final GroupManagementService _groupService = GroupManagementService();

  @override
  void initState() {
    super.initState();
    _loadGroupDetail();
  }

  Future<void> _loadGroupDetail() async {
    try {
      final detail = await _groupService.getGroupDetail(widget.groupId);
      setState(() {
        _groupDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogHeader(),
            const SizedBox(height: AppDimensions.spacingL),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_groupDetail == null)
              _buildErrorContent()
            else
              _buildGroupContent(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  /// ダイアログヘッダー
  Widget _buildDialogHeader() {
    return Row(
      children: [
        Icon(
          Icons.group,
          color: AppColors.accent,
          size: AppDimensions.iconM,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            'グループ詳細',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          color: AppColors.textDark,
        ),
      ],
    );
  }

  /// エラー表示
  Widget _buildErrorContent() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            'グループ情報の読み込みに失敗しました',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  /// グループ詳細コンテンツ
  Widget _buildGroupContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // グループ名
        _buildDetailSection(
          'グループ名',
          _groupDetail!.name,
          Icons.label,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // 説明
        if (_groupDetail!.description.isNotEmpty) ...[
          _buildDetailSection(
            'グループ説明',
            _groupDetail!.description,
            Icons.description,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],

        // メンバー数
        _buildDetailSection(
          'メンバー数',
          '${_groupDetail!.participants.length}人',
          Icons.people,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // 連絡事項
        if (_groupDetail!.announcements.isNotEmpty) ...[
          _buildDetailSection(
            'グループ連絡事項',
            _groupDetail!.announcements,
            Icons.announcement,
          ),
        ],
      ],
    );
  }

  /// 詳細セクション
  Widget _buildDetailSection(
    String title,
    String content,
    IconData icon, {
    bool isSecondary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: isSecondary
            ? AppColors.backgroundLight.withValues(alpha: 0.5)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: isSecondary
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconS,
                color: isSecondary
                    ? AppColors.textDark.withValues(alpha: 0.6)
                    : AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: isSecondary
                      ? AppColors.textDark.withValues(alpha: 0.7)
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            content,
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: isSecondary
                  ? AppColors.textDark.withValues(alpha: 0.6)
                  : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  /// 閉じるボタン
  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton.secondary(
        text: '閉じる',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}