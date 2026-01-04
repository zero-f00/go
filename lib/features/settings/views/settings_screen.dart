import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/locale_provider.dart';
import '../../../shared/services/firebase_user_service.dart' as firebase_user;
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/account_withdrawal_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../l10n/app_localizations.dart';

/// 設定画面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // プライバシー設定の状態
  bool _showManagedEvents = true;
  bool _showParticipatingEvents = true;
  bool _showParticipatedEvents = true;
  bool _isLoadingPrivacySettings = true;
  bool _isSavingPrivacySettings = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// プライバシー設定を読み込む
  Future<void> _loadPrivacySettings() async {
    final userData = await ref.read(currentUserDataProvider.future);
    if (userData != null && mounted) {
      setState(() {
        _showManagedEvents = userData.showHostedEvents || userData.showManagedEvents;
        _showParticipatingEvents = userData.showParticipatingEvents;
        _showParticipatedEvents = userData.showParticipatedEvents;
        _isLoadingPrivacySettings = false;
      });
    } else {
      setState(() {
        _isLoadingPrivacySettings = false;
      });
    }
  }


  /// プライバシー設定を保存する
  Future<void> _savePrivacySetting({
    bool? showManagedEvents,
    bool? showParticipatingEvents,
    bool? showParticipatedEvents,
  }) async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isSavingPrivacySettings = true;
    });

    try {
      final userRepository = ref.read(userRepositoryProvider);
      final request = UpdateUserRequest(
        showHostedEvents: showManagedEvents,
        showManagedEvents: showManagedEvents,
        showParticipatingEvents: showParticipatingEvents,
        showParticipatedEvents: showParticipatedEvents,
      );

      await userRepository.updateUser(currentUser.uid, request);

      // プロバイダーをリフレッシュして最新データを反映
      ref.invalidate(currentUserDataProvider);

      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaved),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsSaveFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPrivacySettings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: l10n.settingsTitle,
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: AppDimensions.cardElevation,
                          offset: const Offset(0, AppDimensions.shadowOffsetY),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppDimensions.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUnifiedHeader(),
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildAccountSection(context),
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildPrivacySettingsSection(context),
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildAppSettingsSection(context),
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildAppInfoSection(context),
                          const SizedBox(height: AppDimensions.spacingL),
                          _buildAccountManagementSection(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 統一ヘッダーを構築
  Widget _buildUnifiedHeader() {
    final l10n = L10n.of(context);
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: AppColors.accent,
          size: AppDimensions.iconM,
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Text(
          l10n.settingsTitle,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  /// アプリ設定セクション（言語設定を含む）
  Widget _buildAppSettingsSection(BuildContext context) {
    final l10n = L10n.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.appSettingsSection,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildLanguageSettingItem(context),
        ],
      ),
    );
  }

  /// 言語設定アイテム
  Widget _buildLanguageSettingItem(BuildContext context) {
    final l10n = L10n.of(context);
    final currentLanguage = ref.watch(localeProvider);
    final currentLanguageName = _getLanguageDisplayName(currentLanguage, l10n);

    return InkWell(
      onTap: () => _showLanguageSelectionDialog(context),
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.borderLight),
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
                Icons.language,
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
                    l10n.languageSection,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentLanguageName,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 言語の表示名を取得
  String _getLanguageDisplayName(AppLanguage language, L10n l10n) {
    switch (language) {
      case AppLanguage.system:
        return l10n.languageSystem;
      case AppLanguage.ja:
        return l10n.languageJapanese;
      case AppLanguage.en:
        return l10n.languageEnglish;
      case AppLanguage.ko:
        return l10n.languageKorean;
      case AppLanguage.zh:
        return l10n.languageChineseSimplified;
      case AppLanguage.zhTW:
        return l10n.languageChineseTraditional;
    }
  }

  /// 言語選択ダイアログを表示
  Future<void> _showLanguageSelectionDialog(BuildContext context) async {
    final l10n = L10n.of(context);
    final currentLanguage = ref.read(localeProvider);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.language,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Text(
                l10n.languageSection,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.system,
                currentLanguage: currentLanguage,
                displayName: l10n.languageSystem,
                icon: Icons.phone_android,
              ),
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.ja,
                currentLanguage: currentLanguage,
                displayName: l10n.languageJapanese,
                icon: Icons.translate,
              ),
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.en,
                currentLanguage: currentLanguage,
                displayName: l10n.languageEnglish,
                icon: Icons.translate,
              ),
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.ko,
                currentLanguage: currentLanguage,
                displayName: l10n.languageKorean,
                icon: Icons.translate,
              ),
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.zh,
                currentLanguage: currentLanguage,
                displayName: l10n.languageChineseSimplified,
                icon: Icons.translate,
              ),
              _buildLanguageDialogOption(
                context: dialogContext,
                language: AppLanguage.zhTW,
                currentLanguage: currentLanguage,
                displayName: l10n.languageChineseTraditional,
                icon: Icons.translate,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  /// 言語選択ダイアログのオプションアイテム
  Widget _buildLanguageDialogOption({
    required BuildContext context,
    required AppLanguage language,
    required AppLanguage currentLanguage,
    required String displayName,
    required IconData icon,
  }) {
    final isSelected = language == currentLanguage;

    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLanguage(language);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textDark,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final l10n = L10n.of(context);
    final isSignedIn = ref.watch(isSignedInProvider);
    final displayName = ref.watch(displayNameProvider);
    final userPhotoUrl = ref.watch(userPhotoUrlProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.account,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          // ユーザー情報表示 - タップでプロフィール画面へ遷移
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSignedIn ? () => _navigateToUserProfile(context) : null,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Row(
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
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSignedIn ? l10n.signedIn : l10n.guestUser,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isSignedIn) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.tapToViewProfile,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontSizeXS,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSignedIn)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (isSignedIn) ...[
            const SizedBox(height: AppDimensions.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSignOutConfirmation(context),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
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

  /// プライバシー設定セクション

  Widget _buildPrivacySettingsSection(BuildContext context) {
    final l10n = L10n.of(context);
    final isSignedIn = ref.watch(isSignedInProvider);

    if (!isSignedIn) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.profileVisibilitySettings,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.profileVisibilityDescription,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
          if (_isLoadingPrivacySettings)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.spacingL),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _buildPrivacyToggle(
              icon: Icons.admin_panel_settings,
              title: l10n.eventsAsOrganizer,
              description: l10n.eventsAsOrganizerDescription,
              value: _showManagedEvents,
              onChanged: (value) {
                setState(() {
                  _showManagedEvents = value;
                });
                _savePrivacySetting(showManagedEvents: value);
              },
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildPrivacyToggle(
              icon: Icons.event_available,
              title: l10n.upcomingEventsVisibility,
              description: l10n.upcomingEventsDescription,
              value: _showParticipatingEvents,
              onChanged: (value) {
                setState(() {
                  _showParticipatingEvents = value;
                });
                _savePrivacySetting(showParticipatingEvents: value);
              },
            ),
            const SizedBox(height: AppDimensions.spacingM),
            _buildPrivacyToggle(
              icon: Icons.history,
              title: l10n.pastEventsVisibility,
              description: l10n.pastEventsDescription,
              value: _showParticipatedEvents,
              onChanged: (value) {
                setState(() {
                  _showParticipatedEvents = value;
                });
                _savePrivacySetting(showParticipatedEvents: value);
              },
            ),
          ],
          if (_isSavingPrivacySettings)
            const Padding(
              padding: EdgeInsets.only(top: AppDimensions.spacingM),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// プライバシー設定のトグルスイッチ
  Widget _buildPrivacyToggle({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
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
              icon,
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
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeXS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.appInfo,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.apps,
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
                      l10n.appTitle,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.versionLabel('1.0.0'),
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
          const SizedBox(height: AppDimensions.spacingL),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.infoAndSupport,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildInfoItem(
            context: context,
            icon: Icons.description,
            title: l10n.termsOfService,
            onTap: () => _onTermsOfServiceTap(context),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildInfoItem(
            context: context,
            icon: Icons.privacy_tip,
            title: l10n.privacyPolicy,
            onTap: () => _onPrivacyPolicyTap(context),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          _buildInfoItem(
            context: context,
            icon: Icons.contact_support,
            title: l10n.contact,
            onTap: () => _onContactTap(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingXS),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTermsOfServiceTap(BuildContext context) async {
    final l10n = L10n.of(context);
    final uri = Uri.parse('https://sites.google.com/view/go-mobile-terms-of-service/home');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, l10n.failedToOpenPage(l10n.termsOfService));
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, l10n.errorOpeningPage(l10n.termsOfService));
      }
    }
  }

  Future<void> _onPrivacyPolicyTap(BuildContext context) async {
    final l10n = L10n.of(context);
    final uri = Uri.parse('https://sites.google.com/view/go-mobile-privacy-policy/home');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, l10n.failedToOpenPage(l10n.privacyPolicy));
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, l10n.errorOpeningPage(l10n.privacyPolicy));
      }
    }
  }

  Future<void> _onContactTap(BuildContext context) async {
    final l10n = L10n.of(context);
    final uri = Uri.parse('https://forms.gle/3zueBZCCpERfLUFk7');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, l10n.failedToOpenContactForm);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, l10n.errorOpeningContactForm);
      }
    }
  }


  void _showErrorDialog(BuildContext context, String message) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.error),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performSignOut();
    }
  }

  Future<void> _performSignOut() async {
    try {
      final authService = ref.read(authServiceProvider);

      // AuthServiceでのサインアウト実行
      await authService.signOut();

      // プロバイダーを段階的に無効化（依存関係を考慮した順序）

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
      await Future.delayed(const Duration(milliseconds: 300));


      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signedOut),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = L10n.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signOutFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  /// アカウント管理セクション
  Widget _buildAccountManagementSection(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.manage_accounts,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                l10n.accountManagement,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.accountManagementDescription,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _buildAccountManagementItem(
            context: context,
            icon: Icons.person_remove,
            title: l10n.deleteAccountTitle,
            description: l10n.deleteAccountDescription,
            onTap: () => _showAccountWithdrawalDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountManagementItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.05)
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
                size: 20,
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
                      color: isDestructive ? AppColors.error : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// アカウント退会ダイアログを表示
  Future<void> _showAccountWithdrawalDialog(BuildContext context) async {
    await showAccountWithdrawalDialog(context);
  }

  /// 自分のプロフィール画面に遷移
  Future<void> _navigateToUserProfile(BuildContext context) async {
    final l10n = L10n.of(context);
    try {
      final currentUserData = await ref.read(currentUserDataProvider.future);
      if (currentUserData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToGetUserInfo),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // プロフィール画面に遷移（アプリのカスタムユーザーIDを使用）
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/user_profile',
          arguments: currentUserData.userId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToShowProfile),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}