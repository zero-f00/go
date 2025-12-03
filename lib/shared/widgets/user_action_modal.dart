import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';
import 'admin_memo_widget.dart';
import 'user_avatar_from_id.dart';
import 'violation_report_dialog.dart';
import '../providers/auth_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/game_profile_model.dart';

/// ユーザーアクションモーダル
/// アプリプロフィール・ゲームプロフィール表示・管理者メモ・違反報告機能を統合
class UserActionModal extends ConsumerWidget {
  final String eventId;
  final String eventName;
  final String userId;
  final String userName;
  final String? gameUsername;
  final UserData? userData;
  final GameProfile? gameProfile;
  final String? gameId;
  final VoidCallback? onGameProfileTap;
  final VoidCallback? onUserProfileTap;
  final List<Widget>? additionalActions;
  final bool showViolationReport;

  const UserActionModal({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.userId,
    required this.userName,
    this.gameUsername,
    this.userData,
    this.gameProfile,
    this.gameId,
    this.onGameProfileTap,
    this.onUserProfileTap,
    this.additionalActions,
    this.showViolationReport = true,
  });

  /// モーダルを表示する静的メソッド
  static void show({
    required BuildContext context,
    required String eventId,
    String? eventName,
    required String userId,
    required String userName,
    String? gameUsername,
    UserData? userData,
    GameProfile? gameProfile,
    String? gameId,
    VoidCallback? onGameProfileTap,
    VoidCallback? onUserProfileTap,
    List<Widget>? additionalActions,
    bool showViolationReport = true,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => UserActionModal(
          eventId: eventId,
          eventName: eventName ?? 'イベント',
          userId: userId,
          userName: userName,
          gameUsername: gameUsername,
          userData: userData,
          gameProfile: gameProfile,
          gameId: gameId,
          onGameProfileTap: onGameProfileTap,
          onUserProfileTap: onUserProfileTap,
          additionalActions: additionalActions,
          showViolationReport: showViolationReport,
        )._buildContent(context, scrollController),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingL,
        AppDimensions.spacingL + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUserInfo(),
            const SizedBox(height: AppDimensions.spacingL),
            _buildProfileActions(context),
            // 管理者メモ
            Consumer(
              builder: (context, ref, child) {
                return AdminMemoWidget(
                  eventId: eventId,
                  userId: userId,
                  userName: userName,
                  currentUserId: ref.read(currentFirebaseUserProvider)?.uid,
                );
              },
            ),
            // 違反報告ボタン
            if (showViolationReport) ...[
              const SizedBox(height: AppDimensions.spacingM),
              AppButton.danger(
                text: '違反を報告',
                icon: Icons.warning_amber_rounded,
                onPressed: () => _showViolationReportDialog(context),
                isFullWidth: true,
              ),
            ],
            // 追加アクション
            if (additionalActions != null) ...[
              const SizedBox(height: AppDimensions.spacingM),
              ...additionalActions!,
            ],
            const SizedBox(height: AppDimensions.spacingM),
            AppButton.outline(
              text: 'キャンセル',
              onPressed: () => Navigator.pop(context),
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildContent(context, ScrollController());
  }

  /// ユーザー情報表示部分
  Widget _buildUserInfo() {
    final displayName = userData?.displayName ?? userName;
    final subName = gameUsername ?? userData?.userId ?? '';

    return Column(
      children: [
        UserAvatarFromId(
          userId: userId,
          size: 64,
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          iconColor: AppColors.accent,
          borderColor: AppColors.accent.withValues(alpha: 0.3),
          borderWidth: 2,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subName.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            subName.startsWith('@') ? subName : '@$subName',
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// プロフィールアクション部分
  Widget _buildProfileActions(BuildContext context) {
    return Container(
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
          const Text(
            'プロフィール表示',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // ゲームプロフィールボタン
          _buildProfileButton(
            context: context,
            title: 'ゲームプロフィール',
            subtitle: 'ゲーム内でのプロフィール情報',
            icon: Icons.sports_esports,
            color: AppColors.accent,
            onTap: onGameProfileTap,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          // ユーザープロフィールボタン
          _buildProfileButton(
            context: context,
            title: 'ユーザープロフィール',
            subtitle: 'アプリ内でのユーザー情報',
            icon: Icons.person,
            color: AppColors.info,
            onTap: onUserProfileTap,
          ),
        ],
      ),
    );
  }

  /// プロフィールボタンの共通コンポーネント
  Widget _buildProfileButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap?.call();
        },
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
                      style: const TextStyle(
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

  /// 違反報告ダイアログを表示
  void _showViolationReportDialog(BuildContext context) {
    Navigator.pop(context); // モーダルを閉じる
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ViolationReportDialog(
        eventId: eventId,
        eventName: eventName,
        violatedUserId: userId,
        violatedUserName: userName,
      ),
    );
  }
}