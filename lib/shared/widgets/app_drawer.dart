import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/avatar_service.dart';
import '../services/in_app_review_service.dart';
import '../providers/auth_provider.dart';
import 'user_settings_dialog.dart';
import 'auth_dialog.dart';
import 'user_avatar.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }


  Future<void> _loadAvatar() async {
    final String? avatarPath = await AvatarService.instance.getAvatarPath();
    if (avatarPath != null && File(avatarPath).existsSync()) {
      setState(() {
        _avatarFile = File(avatarPath);
      });
    }
  }

  /// ユーザーIDをクリップボードにコピー
  Future<void> _copyUserIdToClipboard(BuildContext context, String userId) async {
    try {
      await Clipboard.setData(ClipboardData(text: userId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('ユーザーID "$userId" をコピーしました'),
              ],
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('コピーに失敗しました'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.description,
                  title: '利用規約',
                  onTap: () => _onTermsOfServiceTap(context),
                ),
                _buildDrawerItem(
                  icon: Icons.privacy_tip,
                  title: 'プライバシーポリシー',
                  onTap: () => _onPrivacyPolicyTap(context),
                ),
                _buildDrawerItem(
                  icon: Icons.contact_support,
                  title: 'お問い合わせ',
                  onTap: () => _onContactTap(context),
                ),
                _buildDrawerItem(
                  icon: Icons.star_rate,
                  title: 'アプリを評価',
                  onTap: () => _onRatingTap(context),
                ),
                const Divider(
                  color: AppColors.border,
                  thickness: 1,
                  indent: AppDimensions.spacingL,
                  endIndent: AppDimensions.spacingL,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'フレンド',
                  onTap: () => _onFriendsTap(context),
                ),
                _buildDrawerItem(
                  icon: Icons.videogame_asset,
                  title: 'お気に入りのゲーム',
                  onTap: () => _onFavoriteGamesTap(context),
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: '設定',
                  onTap: () => _onSettingsTap(context),
                ),
              ],
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    try {
      final isSignedIn = ref.watch(isSignedInProvider);
      final isSetupCompleted = ref.watch(userSettingsCompletedProvider);
      final displayName = ref.watch(displayNameProvider);
      final userData = ref.watch(currentUserDataProvider);
      final userPhotoUrl = ref.watch(userPhotoUrlProvider);

      final (appUsername, appUserId) = _extractUserData(userData);
      final gradientColors = _getGradientColors(isSignedIn, isSetupCompleted);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _onUserInfoTap(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.spacingS),
                  UserAvatar(
                    size: 60,
                    avatarFile: _avatarFile,
                    avatarUrl: userPhotoUrl,
                    backgroundColor: AppColors.backgroundLight,
                    iconColor: isSignedIn ? AppColors.accent : AppColors.textSecondary,
                    borderColor: AppColors.backgroundLight.withValues(alpha: 0.8),
                    borderWidth: 2,
                    overlayIcon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSignedIn && !isSetupCompleted
                            ? Icons.warning
                            : isSignedIn
                                ? Icons.edit
                                : Icons.login,
                        size: 16,
                        color: isSignedIn && !isSetupCompleted
                            ? Colors.orange
                            : AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Text(
                    isSignedIn
                        ? (isSetupCompleted
                            ? (appUsername?.isNotEmpty == true ? appUsername! : displayName)
                            : '${appUsername?.isNotEmpty == true ? appUsername! : displayName}（設定未完了）')
                        : 'ゲストユーザー',
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: AppDimensions.fontSizeL,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  if (isSignedIn && !isSetupCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'タップして初回設定を完了',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: AppDimensions.fontSizeS,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingS,
                              vertical: AppDimensions.spacingXS / 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isSignedIn
                                        ? (appUserId?.isNotEmpty == true ? 'ID: $appUserId' : 'ID: 未設定')
                                        : 'ID: guest_001',
                                    style: const TextStyle(
                                      color: AppColors.textOnPrimary,
                                      fontSize: AppDimensions.fontSizeS,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSignedIn && appUserId?.isNotEmpty == true)
                                  GestureDetector(
                                    onTap: () => _copyUserIdToClipboard(context, appUserId!),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.copy,
                                        size: 16,
                                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingS),
                        Icon(
                          isSignedIn ? Icons.check_circle : Icons.login,
                          color: AppColors.backgroundLight.withValues(alpha: 0.8),
                          size: AppDimensions.iconS,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    } catch (e) {
      // エラー時のフォールバック表示
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.textSecondary, AppColors.textSecondary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.spacingS),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundLight.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.backgroundLight,
                    child: Icon(
                      Icons.error,
                      size: 30,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingS),
                const Text(
                  'ロード中...',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /// ユーザーデータからユーザー名とIDを抽出
  (String?, String?) _extractUserData(AsyncValue userData) {
    String? appUsername;
    String? appUserId;
    userData.when(
      data: (data) {
        appUsername = data?.username;
        appUserId = data?.userId;
      },
      loading: () {
        appUsername = null;
        appUserId = null;
      },
      error: (error, stack) {
        appUsername = null;
        appUserId = null;
      },
    );
    return (appUsername, appUserId);
  }

  /// 状態に応じたグラデーション色を取得
  List<Color> _getGradientColors(bool isSignedIn, bool isSetupCompleted) {
    if (isSignedIn && isSetupCompleted) {
      return [AppColors.primary, AppColors.accent];
    } else if (isSignedIn) {
      return [Colors.orange.withValues(alpha: 0.7), Colors.deepOrange.withValues(alpha: 0.8)];
    } else {
      return [AppColors.textSecondary.withValues(alpha: 0.6), AppColors.textSecondary.withValues(alpha: 0.8)];
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.textDark,
        size: AppDimensions.iconM,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingL,
        vertical: AppDimensions.spacingXS,
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Go - ゲームイベント管理',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            'バージョン 1.0.0',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ナビゲーション処理メソッド群
  Future<void> _onUserInfoTap(BuildContext context) async {
    Navigator.pop(context); // Drawerを閉じる

    if (!mounted) return;

    try {
      final isSignedIn = ref.read(isSignedInProvider);
      final isSetupCompleted = ref.read(userSettingsCompletedProvider);


      if (!isSignedIn) {
        // 未認証の場合：サインインダイアログを表示
        if (!mounted) return;
        final result = await AuthDialog.show(context);
        if (result == true && mounted) {
          _loadAvatar();
        }
      } else if (!isSetupCompleted) {
        // 認証済みだがユーザー設定未完了の場合：初回ユーザー設定ダイアログを表示
        if (!mounted) return;
        final setupResult = await UserSettingsDialog.show(context, isInitialSetup: true);
        if (setupResult == true && mounted) {
          // プロバイダーを強制的に更新して状態を再評価
          ref.invalidate(currentUserDataProvider);
          ref.invalidate(delayedInitialSetupCheckProvider);
          ref.invalidate(userSettingsCompletedProvider);
          _loadAvatar();

          // 少し待ってからUIを更新（プロバイダーの更新が完了するのを待つ）
          await Future.delayed(const Duration(milliseconds: 300));

          // UIを更新
          if (mounted) {
            setState(() {});
          }
        }
      } else {
        // 認証済みかつユーザー設定完了の場合：通常のユーザー設定ダイアログを表示
        if (!mounted) return;
        await UserSettingsDialog.show(context, isInitialSetup: false);
        if (mounted) {
          _loadAvatar();
        }
      }
    } catch (e) {
      // エラー時はエラーダイアログを表示
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('エラー'),
            content: Text('ユーザー情報の読み込みに失敗しました。\n\n$e'),
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
  }

  void _onTermsOfServiceTap(BuildContext context) {
    Navigator.pop(context);
    // TODO: 利用規約画面への遷移
    _showComingSoon(context, '利用規約');
  }

  void _onPrivacyPolicyTap(BuildContext context) {
    Navigator.pop(context);
    // TODO: プライバシーポリシー画面への遷移
    _showComingSoon(context, 'プライバシーポリシー');
  }


  void _onContactTap(BuildContext context) {
    Navigator.pop(context);
    // TODO: お問い合わせ画面への遷移
    _showComingSoon(context, 'お問い合わせ');
  }

  void _onRatingTap(BuildContext context) {
    Navigator.pop(context);
    // In-App Review機能を実行
    InAppReviewService.requestReview();
  }

  void _onFriendsTap(BuildContext context) {
    Navigator.pop(context);
    _navigateWithAuthCheck(context, '/friends');
  }

  void _onFavoriteGamesTap(BuildContext context) {
    Navigator.pop(context);
    _navigateWithAuthCheck(context, '/favorite-games');
  }

  void _onSettingsTap(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/settings');
  }

  /// 認証が必要な画面への遷移を処理
  void _navigateWithAuthCheck(BuildContext context, String routeName) {
    final authState = ref.watch(authStateProvider);

    authState.when(
      data: (user) {
        if (user == null) {
          // ゲストユーザーの場合はログインダイアログを表示
          _showAuthDialog(context);
        } else {
          // サインイン済みの場合は画面遷移
          Navigator.pushNamed(context, routeName);
        }
      },
      loading: () {
        // ローディング中は何もしない
      },
      error: (error, stack) {
        // エラー時はログインダイアログを表示
        _showAuthDialog(context);
      },
    );
  }

  /// 認証ダイアログを表示
  Future<void> _showAuthDialog(BuildContext context) async {
    final result = await AuthDialog.show(context);
    if (result == true) {
      // サインイン成功後、状態が更新されるまで待機
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature画面は準備中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}