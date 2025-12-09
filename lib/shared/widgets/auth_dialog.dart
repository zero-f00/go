import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../providers/auth_provider.dart';
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
  bool _agreedToTerms = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading || !_agreedToTerms) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });
    } catch (e) {
      return;
    }

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();

      if (result != null && mounted) {
        // 利用規約同意を記録
        await authService.recordTermsAcceptance();

        // サインイン成功後、初回ユーザー設定ダイアログを表示
        await _showInitialUserSetup();
      } else {

        // Show user-friendly error message
        _showErrorDialog('Googleサインインに失敗しました');
      }
    } catch (e) {
      _showErrorDialog('Googleサインインエラーが発生しました');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    if (_isLoading || !_agreedToTerms) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithApple();

      if (result != null && mounted) {
        // 利用規約同意を記録
        await authService.recordTermsAcceptance();

        // サインイン成功後、初回ユーザー設定ダイアログを表示
        await _showInitialUserSetup();
      } else {

        // Show user-friendly error message
        _showErrorDialog('Apple IDサインインに失敗しました');
      }
    } catch (e) {
      _showErrorDialog('Apple IDサインインエラーが発生しました');
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
                      _buildTermsCheckbox(),
                      const SizedBox(height: AppDimensions.spacingL),
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

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
      child: Row(
        children: [
          Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            activeColor: AppColors.accent,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _agreedToTerms = !_agreedToTerms;
                });
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '利用規約',
                      style: const TextStyle(
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showTermsOfService,
                    ),
                    const TextSpan(text: 'と'),
                    TextSpan(
                      text: 'プライバシーポリシー',
                      style: const TextStyle(
                        color: AppColors.accent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showPrivacyPolicy,
                    ),
                    const TextSpan(text: 'に同意します'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTermsOfService() async {
    final uri = Uri.parse('https://sites.google.com/view/go-mobile-terms-of-service/home');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showErrorDialog('利用規約のページを開けませんでした。');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('利用規約のページを開く際にエラーが発生しました。');
      }
    }
  }

  Future<void> _showPrivacyPolicy() async {
    final uri = Uri.parse('https://sites.google.com/view/go-mobile-privacy-policy/home');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showErrorDialog('プライバシーポリシーのページを開けませんでした。');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('プライバシーポリシーのページを開く際にエラーが発生しました。');
      }
    }
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
        onPressed: (_isLoading || !_agreedToTerms) ? null : _signInWithGoogle,
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
        onPressed: (_isLoading || !_agreedToTerms) ? null : _signInWithApple,
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
    try {
      // サインイン成功後にプロバイダーを明示的に更新
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(displayNameProvider);
      ref.invalidate(userPhotoUrlProvider);

      // 短時間待機してプロバイダーの更新を確実にする
      await Future.delayed(const Duration(milliseconds: 300));

      // Firestoreから現在のユーザーデータをチェック
      final userRepository = ref.read(userRepositoryProvider);
      final userData = await userRepository.getCurrentUser();

      if (userData != null && userData.isSetupCompleteBasedOnUserId) {
        // 既存ユーザーかつ設定完了済みの場合、ようこそメッセージを表示して初回設定はスキップ
        if (mounted) {
          Navigator.of(context).pop(true);
          _showWelcomeBackDialog();
        }
        return;
      }

      // 認証ダイアログを閉じる
      if (mounted) {
        Navigator.of(context).pop(true);
        // 新規ユーザーまたは設定未完了の場合、初回ユーザー設定ダイアログを表示
        await UserSettingsDialog.show(context, isInitialSetup: true);
      }

    } catch (e) {
      // エラーの場合は安全側に倒して初回設定を表示
      if (mounted) {
        Navigator.of(context).pop(true);
        await UserSettingsDialog.show(context, isInitialSetup: true);
      }
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