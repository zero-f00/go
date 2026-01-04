import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../services/firebase_user_service.dart' as firebase_user;
import '../services/auth_service.dart';
import '../services/avatar_service.dart';

/// アカウント退会確認ダイアログ
/// 退会に関する重要な注意事項を表示し、ユーザーの確認を取得
class AccountWithdrawalDialog extends ConsumerStatefulWidget {
  const AccountWithdrawalDialog({super.key});

  @override
  ConsumerState<AccountWithdrawalDialog> createState() => _AccountWithdrawalDialogState();
}

class _AccountWithdrawalDialogState extends ConsumerState<AccountWithdrawalDialog> {
  bool _isProcessing = false;
  bool _confirmationChecked = false;
  String _confirmationText = '';
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: AppColors.error,
            size: AppDimensions.iconM,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.accountWithdrawalTitle,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWarningSection(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildDataDeletionInfo(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildConfirmationSection(l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _buildTextConfirmation(l10n),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.accountWithdrawalCancel,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _canProceed(l10n) ? () => _performWithdrawal(l10n) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingS,
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(l10n.accountWithdrawalConfirmButton),
        ),
      ],
    );
  }

  Widget _buildWarningSection(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: AppColors.error,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.accountWithdrawalImportantNotice,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.accountWithdrawalWarningMessage,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: AppDimensions.fontSizeS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDeletionInfo(L10n l10n) {
    final dataItems = [
      l10n.accountWithdrawalDataItem1,
      l10n.accountWithdrawalDataItem2,
      l10n.accountWithdrawalDataItem3,
      l10n.accountWithdrawalDataItem4,
      l10n.accountWithdrawalDataItem5,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountWithdrawalDataDeletionTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ...dataItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: AppColors.textSecondary)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppDimensions.fontSizeS,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.info,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.accountWithdrawalHistoryNote,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: AppDimensions.fontSizeS,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSection(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountWithdrawalConfirmTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        InkWell(
          onTap: () => setState(() => _confirmationChecked = !_confirmationChecked),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
            child: Row(
              children: [
                Checkbox(
                  value: _confirmationChecked,
                  onChanged: (value) => setState(() => _confirmationChecked = value ?? false),
                  activeColor: AppColors.error,
                ),
                Expanded(
                  child: Text(
                    l10n.accountWithdrawalCheckboxLabel,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: AppDimensions.fontSizeS,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextConfirmation(L10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountWithdrawalTextInputLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _confirmationController,
          onChanged: (value) => setState(() => _confirmationText = value),
          decoration: InputDecoration(
            hintText: l10n.accountWithdrawalTextInputHint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
          enabled: !_isProcessing,
        ),
      ],
    );
  }

  bool _canProceed(L10n l10n) {
    return _confirmationChecked &&
           _confirmationText.trim() == l10n.accountWithdrawalTextInputHint &&
           !_isProcessing;
  }

  Future<void> _performWithdrawal(L10n l10n) async {
    setState(() => _isProcessing = true);

    try {
      final userRepository = UserRepository();
      final currentUser = ref.read(currentFirebaseUserProvider);

      if (currentUser == null) {
        throw Exception(l10n.accountWithdrawalUserNotFound);
      }

      // 退会処理を実行
      await userRepository.deactivateUser(currentUser.uid);

      // AuthServiceを取得して明示的にサインアウト処理を実行
      // これにより、GoogleSignInやその他のプロバイダーのキャッシュもクリアされる
      final authService = ref.read(authServiceProvider);
      try {
        await authService.signOut();
      } catch (e) {
        // サインアウトエラーは無視して処理を継続
      }

      // プロバイダーの無効化は最小限に（認証関連のみ）
      // 注意：userRepositoryProviderは無効化しない（他ユーザーのアバター保存に影響するため）
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(firebase_user.currentUserDataProvider);
      ref.invalidate(delayedInitialSetupCheckProvider);
      ref.invalidate(needsInitialSetupProvider);
      ref.invalidate(userSettingsCompletedProvider);
      ref.invalidate(currentFirebaseUserProvider);
      ref.invalidate(displayNameProvider);
      ref.invalidate(userPhotoUrlProvider);
      ref.invalidate(isSignedInProvider);

      // ローカルアバターキャッシュもクリア
      try {
        final avatarService = AvatarService.instance;
        await avatarService.deleteAvatar();
      } catch (e) {
        // キャッシュクリア失敗は退会処理全体を停止させない
      }

      // 状態変更が確実に反映されるまで待機
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted && context.mounted) {
        Navigator.of(context).pop();

        // 成功メッセージを表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountWithdrawalSuccess),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted && context.mounted) {
        // 再認証が必要な場合の特別処理
        if (e.toString().contains('REQUIRES_REAUTHENTICATION')) {
          // ダイアログを閉じる
          Navigator.of(context).pop();

          // AuthServiceを先に取得（refを使う前に）
          final authService = ref.read(authServiceProvider);

          // 再認証が必要であることを通知
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountWithdrawalReauthTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.accountWithdrawalReauthMessage,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: l10n.accountWithdrawalReauthLogout,
                textColor: Colors.white,
                onPressed: () async {
                  // ログアウト処理を実行（authServiceは既に取得済み）
                  await authService.signOut();
                },
              ),
            ),
          );
        } else {
          // その他のエラーの場合
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.accountWithdrawalFailed(e.toString())),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}

/// アカウント退会ダイアログを表示するヘルパー関数
Future<void> showAccountWithdrawalDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // 外側タップで閉じることを防ぐ
    builder: (context) => const AccountWithdrawalDialog(),
  );
}
