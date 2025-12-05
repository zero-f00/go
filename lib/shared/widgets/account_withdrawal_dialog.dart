import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          const Text(
            'アカウント退会',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
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
              _buildWarningSection(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildDataDeletionInfo(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildConfirmationSection(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildTextConfirmation(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'キャンセル',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _canProceed() ? _performWithdrawal : null,
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
              : const Text('退会する'),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
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
              const Text(
                '重要な注意事項',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          const Text(
            'この操作は元に戻すことができません。退会後は同じアカウントでの再登録はできません。',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: AppDimensions.fontSizeS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDeletionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '削除されるデータ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        ...[
          'アカウント情報（ユーザー名、プロフィール画像など）',
          '作成したイベント',
          '参加申請データ',
          'ゲームプロフィール情報',
          'その他の個人データ',
        ].map((item) => Padding(
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
              const Expanded(
                child: Text(
                  'イベント履歴等では「退会したユーザー」として表示されます',
                  style: TextStyle(
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

  Widget _buildConfirmationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '確認',
          style: TextStyle(
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
                const Expanded(
                  child: Text(
                    '上記の内容を理解し、アカウント退会に同意します',
                    style: TextStyle(
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

  Widget _buildTextConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '「退会する」と入力してください',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _confirmationController,
          onChanged: (value) => setState(() => _confirmationText = value),
          decoration: InputDecoration(
            hintText: '退会する',
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

  bool _canProceed() {
    return _confirmationChecked &&
           _confirmationText.trim() == '退会する' &&
           !_isProcessing;
  }

  Future<void> _performWithdrawal() async {
    setState(() => _isProcessing = true);

    try {
      final userRepository = UserRepository();
      final currentUser = ref.read(currentFirebaseUserProvider);

      if (currentUser == null) {
        throw Exception('ユーザーが見つかりません');
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
            content: const Text('アカウント退会が完了しました'),
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
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'セキュリティ確認が必要です',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'アカウント退会にはセキュリティのため再ログインが必要です。'
                    '一度ログアウトしてから再度ログインし、もう一度退会処理を行ってください。',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 10),
              action: SnackBarAction(
                label: 'ログアウト',
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
              content: Text('退会処理に失敗しました: $e'),
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