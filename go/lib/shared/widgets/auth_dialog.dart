import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import 'user_settings_dialog.dart';

class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AuthDialog(),
    );
  }
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    print('🚀 AuthDialog: Google Sign-In button pressed');

    if (_isLoading) {
      print('⚠️ AuthDialog: Already loading, ignoring button press');
      return;
    }

    print('🔄 AuthDialog: Setting loading state to true...');
    try {
      setState(() {
        _isLoading = true;
      });
      print('✅ AuthDialog: Loading state set successfully');
    } catch (e) {
      print('❌ AuthDialog: Error setting loading state: $e');
      return;
    }

    try {
      print('🔄 AuthDialog: Starting Google Sign-In process...');
      print('🔄 AuthDialog: Getting authServiceProvider...');

      final authService = ref.read(authServiceProvider);
      print('✅ AuthDialog: AuthService obtained successfully');
      print('   - AuthService type: ${authService.runtimeType}');
      print('   - AuthService instance: $authService');

      print('🔄 AuthDialog: About to call authService.signInWithGoogle()...');
      final result = await authService.signInWithGoogle();
      print('✅ AuthDialog: signInWithGoogle() completed without exception');

      print('🔄 AuthDialog: signInWithGoogle() returned: ${result != null ? 'UserCredential' : 'null'}');

      if (result != null && mounted) {
        print('✅ AuthDialog: Google Sign-In successful');
        print('   - User: ${result.user?.email ?? 'unknown'}');

        // サインイン成功後、初回ユーザー設定ダイアログを表示
        await _showInitialUserSetup();
      } else {
        print('❌ AuthDialog: Google Sign-In returned null result');
        print('   - This could be due to user cancellation or an error in AuthService');
        print('   - Check AuthService logs above for details');

        // Show user-friendly error message
        String errorMessage = 'Googleサインインに失敗しました';

        // Add specific guidance for common issues
        if (kDebugMode) {
          errorMessage += '\n\n【開発者向け情報】\n'
              '• ユーザーがサインインをキャンセルした可能性があります\n'
              '• GoogleService-Info.plist の設定を確認してください\n'
              '• Bundle ID が Firebase プロジェクトと一致しているか確認してください\n'
              '• 詳細なエラーはコンソールログを確認してください';
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ AuthDialog: Google Sign-In exception caught: $e');
      print('❌ AuthDialog: Exception Type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');

      String errorMessage = 'Googleサインインエラーが発生しました';
      if (kDebugMode) {
        errorMessage += '\n\n【エラー詳細】\n${e.toString()}';
      }

      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 AuthDialog: Starting Apple Sign-In process...');
      final authService = ref.read(authServiceProvider);

      print('🔄 AuthDialog: Calling authService.signInWithApple()...');
      final result = await authService.signInWithApple();

      print('🔄 AuthDialog: signInWithApple() returned: ${result != null ? 'UserCredential' : 'null'}');

      if (result != null && mounted) {
        print('✅ AuthDialog: Apple Sign-In successful');
        print('   - User: ${result.user?.email ?? 'unknown'}');

        // サインイン成功後、初回ユーザー設定ダイアログを表示
        await _showInitialUserSetup();
      } else {
        print('❌ AuthDialog: Apple Sign-In returned null result');
        print('   - This indicates an exception occurred in AuthService');
        print('   - Check AuthService logs above for the actual error details');

        // Show user-friendly error message
        String errorMessage = 'Apple IDサインインに失敗しました';

        // Add specific guidance for simulator
        if (kDebugMode) {
          errorMessage += '\n\n【開発者向け情報】\n'
              '• iOSシミュレーターでは Apple Sign-In が制限されています\n'
              '• 実際のiOSデバイスでテストしてください\n'
              '• Apple IDでサインインした実機が必要です\n'
              '• 詳細なエラーはコンソールログを確認してください';
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌ AuthDialog: Apple Sign-In exception caught: $e');
      print('❌ AuthDialog: Exception Type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      _showErrorDialog('Apple IDサインインエラー\n\n${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.spacingL),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDescription(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildSignInButtons(),
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildSkipButton(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingS),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: const Icon(
            Icons.account_circle,
            color: AppColors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        const Expanded(
          child: Text(
            'アカウントでサインイン',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: _skipAndShowUserSettings,
          icon: const Icon(
            Icons.close,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return const Text(
      'アカウントでサインインすると、データの同期やバックアップが利用できます。',
      style: TextStyle(
        fontSize: AppDimensions.fontSizeM,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignInButtons() {
    return Column(
      children: [
        _buildGoogleSignInButton(),
        if (Platform.isIOS) ...[
          const SizedBox(height: AppDimensions.spacingM),
          _buildAppleSignInButton(),
        ],
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          elevation: 0,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.g_mobiledata,
                size: 24,
                color: AppColors.primary,
              ),
        label: Text(
          _isLoading ? 'サインイン中...' : 'Googleでサインイン',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _signInWithApple,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          elevation: 0,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(
                Icons.apple,
                size: 20,
              ),
        label: Text(
          _isLoading ? 'サインイン中...' : 'Apple IDでサインイン',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading ? null : _skipAndShowUserSettings,
      child: const Text(
        'スキップして続行',
        style: TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Future<void> _showInitialUserSetup() async {
    print('🔄 AuthDialog: Checking if initial user setup is needed...');

    try {
      // サインイン成功後にプロバイダーを明示的に更新
      print('🔄 AuthDialog: Refreshing user data providers after sign-in...');
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(displayNameProvider);
      ref.invalidate(userPhotoUrlProvider);

      // 短時間待機してプロバイダーの更新を確実にする
      await Future.delayed(const Duration(milliseconds: 300));

      // Firestoreから現在のユーザーデータをチェック
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getCurrentUser();

      print('🔍 AuthDialog: User data check result: ${userData != null ? "Found existing user" : "New user"}');

      if (userData != null && userData.isSetupCompleteBasedOnUserId) {
        // 既存ユーザーかつ設定完了済みの場合、ようこそメッセージを表示して初回設定はスキップ
        print('✅ AuthDialog: Welcome back! Setup already completed, skipping initial setup');
        Navigator.of(context).pop(true);

        // ようこそメッセージを表示
        _showWelcomeBackDialog();
        return;
      }

      // 認証ダイアログを閉じる
      Navigator.of(context).pop(true);

      // 新規ユーザーまたは設定未完了の場合、初回ユーザー設定ダイアログを表示
      print('🔄 AuthDialog: Showing initial user setup dialog for new/incomplete user...');
      final setupCompleted = await UserSettingsDialog.show(context, isInitialSetup: true);

      if (setupCompleted == true) {
        print('✅ AuthDialog: Initial user setup completed successfully');
      } else {
        print('⚠️ AuthDialog: Initial user setup was not completed');
      }

    } catch (e) {
      print('❌ AuthDialog: Error checking user data or showing initial user setup: $e');
      // エラーの場合は安全側に倒して初回設定を表示
      Navigator.of(context).pop(true);
      await UserSettingsDialog.show(context, isInitialSetup: true);
    }
  }

  void _showWelcomeBackDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('おかえりなさい！'),
          content: const Text('サインインが完了しました。\nアプリを引き続きお楽しみください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _skipAndShowUserSettings() {
    Navigator.of(context).pop(false); // スキップしたことを通知
  }
}