import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/firebase_user_service.dart' as firebase_user;
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';

/// 設定画面
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: '設定',
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountSection(context, ref),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildPrivacySection(context, ref),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildAppInfoSection(context, ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final displayName = ref.watch(displayNameProvider);
    final userPhotoUrl = ref.watch(userPhotoUrlProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ユーザー情報表示
          Row(
            children: [
              UserAvatar(
                avatarUrl: userPhotoUrl,
                size: 60,
                backgroundColor: AppColors.accent,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSignedIn ? 'サインイン済み' : 'ゲストユーザー',
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
          if (isSignedIn) ...[
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSignOutConfirmation(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('サインアウト'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              Icons.info,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appTitle,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'バージョン 1.0.0',
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
    );
  }

  Widget _buildPrivacySection(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(firebase_user.currentUserDataProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.privacy_tip,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              const Text(
                'プライバシー設定',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          userData.when(
            data: (user) => user != null ? Column(
              children: [
                _buildPrivacySetting(
                  context,
                  ref,
                  title: '主催イベントを表示',
                  subtitle: 'プロフィールに主催したイベントを表示します',
                  value: user.showHostedEvents,
                  onChanged: (value) => _updateEventDisplaySetting(
                    ref,
                    showHostedEvents: value,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildPrivacySetting(
                  context,
                  ref,
                  title: '参加予定イベントを表示',
                  subtitle: 'プロフィールに参加予定のイベントを表示します',
                  value: user.showParticipatingEvents,
                  onChanged: (value) => _updateEventDisplaySetting(
                    ref,
                    showParticipatingEvents: value,
                  ),
                ),
              ],
            ) : const SizedBox.shrink(),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('設定の読み込みに失敗しました: $error'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySetting(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
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
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Future<void> _updateEventDisplaySetting(
    WidgetRef ref, {
    bool? showHostedEvents,
    bool? showParticipatingEvents,
  }) async {
    try {
      final userService = ref.read(firebase_user.userServiceProvider);
      await userService.updateCurrentUser(
        showHostedEvents: showHostedEvents,
        showParticipatingEvents: showParticipatingEvents,
      );
    } catch (e) {
      // エラーハンドリングは UserService 内で実行される
      debugPrint('Failed to update event display setting: $e');
    }
  }

  Future<void> _showSignOutConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サインアウト'),
        content: const Text('サインアウトしてもよろしいですか？\n\nローカルに保存されたデータは残りますが、クラウド同期は停止されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('サインアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performSignOut(context, ref);
    }
  }

  Future<void> _performSignOut(BuildContext context, WidgetRef ref) async {
    try {
      print('🚪 Settings: Starting sign-out process...');
      final authService = ref.read(authServiceProvider);

      // AuthServiceでのサインアウト実行
      print('🔄 Settings: Executing AuthService.signOut()...');
      await authService.signOut();
      print('✅ Settings: AuthService.signOut() completed');

      // プロバイダーを段階的に無効化（依存関係を考慮した順序）
      print('🔄 Settings: Invalidating providers in order...');

      // 1. 認証関連の基底プロバイダーを無効化
      ref.invalidate(authStateProvider); // 認証状態を最初にクリア

      // 2. 基底サービスプロバイダーを無効化
      ref.invalidate(userRepositoryProvider);

      // 3. ユーザーデータプロバイダーを無効化
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(firebase_user.currentUserDataProvider);

      // 4. 初回設定関連プロバイダーを無効化
      ref.invalidate(delayedInitialSetupCheckProvider);
      ref.invalidate(needsInitialSetupProvider);
      ref.invalidate(userSettingsCompletedProvider);

      // 5. 派生プロバイダーを無効化
      ref.invalidate(currentFirebaseUserProvider);
      ref.invalidate(displayNameProvider);
      ref.invalidate(userPhotoUrlProvider);
      ref.invalidate(isSignedInProvider); // 最後にサインイン状態をクリア

      // 認証状態変更が確実に反映されるまで待機
      print('🔄 Settings: Waiting for auth state changes to propagate...');
      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ Settings: All user-related provider caches cleared');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('サインアウトしました'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      print('❌ Settings: Sign out error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('サインアウトに失敗しました: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}