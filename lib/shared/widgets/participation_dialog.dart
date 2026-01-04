import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../services/participation_service.dart';
import '../services/game_profile_service.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/game_profile_model.dart';
import '../../data/repositories/user_repository.dart';
import '../models/game.dart' as SharedGame;
import '../../data/models/game_model.dart' as DataGame;
import '../../l10n/app_localizations.dart';
import 'app_button.dart';
import 'auth_dialog.dart';
import 'app_text_field.dart';

/// プロフィール要件状態
enum ProfileRequirementStatus {
  checking,      // 確認中
  ready,         // 準備完了（プロフィールあり、ユーザー名あり）
  needsSetup,    // プロフィール設定が必要
  needsUsername, // ユーザー名設定が必要
}

/// 参加申し込みダイアログ
class ParticipationDialog extends ConsumerStatefulWidget {
  final Event event;

  const ParticipationDialog({
    super.key,
    required this.event,
  });

  @override
  ConsumerState<ParticipationDialog> createState() => _ParticipationDialogState();
}

class _ParticipationDialogState extends ConsumerState<ParticipationDialog> {
  final _messageController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  GameProfile? _existingGameProfile;
  SharedGame.Game? _eventGame;

  // 統合されたプロフィール要件チェック状態
  ProfileRequirementStatus _profileStatus = ProfileRequirementStatus.checking;
  bool _needsFavoriteRegistration = false;

  // 参加者数管理
  int _currentParticipantCount = 0;
  bool _isLoadingParticipantCount = true;

  @override
  void initState() {
    super.initState();
    _checkRequirements();
    _loadParticipantCount();
    // パスワード入力の変更を監視してUIを更新
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    // パスワード入力時にボタンの活性/非活性を更新
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _messageController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 申し込み要件をチェック
  Future<void> _checkRequirements() async {
    setState(() {
      _profileStatus = ProfileRequirementStatus.checking;
    });

    final currentUser = ref.read(currentUserDataProvider).value;
    if (currentUser == null) return;

    final gameId = widget.event.gameId;
    if (gameId == null || gameId.isEmpty) {
      setState(() {
        _profileStatus = ProfileRequirementStatus.needsSetup;
      });
      return;
    }

    // ゲーム情報を取得
    final gameService = GameService.instance;
    final game = await gameService.getGameById(gameId);

    if (mounted) {
      setState(() {
        _eventGame = game;
      });
    }

    // お気に入り登録状況をチェック
    final favoriteGameIds = currentUser.favoriteGameIds;
    final isFavorited = favoriteGameIds.contains(gameId);

    if (!isFavorited) {
      // お気に入り登録していない場合
      setState(() {
        _profileStatus = ProfileRequirementStatus.needsSetup;
        _needsFavoriteRegistration = true;
      });
      return;
    }

    // プロフィール存在チェック
    final gameProfile = await GameProfileService.instance.getGameProfile(
      currentUser.id,
      gameId,
    );

    if (gameProfile == null) {
      // プロフィールが存在しない場合
      setState(() {
        _profileStatus = ProfileRequirementStatus.needsSetup;
        _needsFavoriteRegistration = false;
      });
      return;
    }

    // ユーザー名チェック
    if (gameProfile.gameUsername.isEmpty) {
      // ユーザー名が設定されていない場合
      setState(() {
        _existingGameProfile = gameProfile;
        _profileStatus = ProfileRequirementStatus.needsUsername;
        _needsFavoriteRegistration = false;
      });
      return;
    }

    // すべての要件が満たされている場合
    setState(() {
      _existingGameProfile = gameProfile;
      _profileStatus = ProfileRequirementStatus.ready;
      _needsFavoriteRegistration = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserDataProvider);

    return currentUser.when(
      data: (user) {
        if (user == null) {
          return _buildLoginRequiredDialog();
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildParticipantCountSection(),
                        _buildGameInfo(),
                        _buildProfileStatusSection(),
                        if (widget.event.hasParticipationFee) _buildParticipationFeeSection(),
                        if (widget.event.visibility == EventVisibility.inviteOnly) _buildPasswordSection(),
                        _buildMessageSection(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
      loading: () => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppDimensions.spacingM),
              Text(L10n.of(context).loadingText),
            ],
          ),
        ),
      ),
      error: (error, stack) => _buildErrorDialog(error.toString()),
    );
  }

  Widget _buildLoginRequiredDialog() {
    final l10n = L10n.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(Icons.login, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spacingS),
          Text(l10n.loginRequiredTitle),
        ],
      ),
      content: Text(l10n.loginRequiredForParticipation),
      actions: [
        AppButton.outline(
          text: l10n.closeButtonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        AppButton(
          text: l10n.loginButtonText,
          onPressed: () async {
            Navigator.of(context).pop(); // ダイアログを閉じる
            await AuthDialog.show(context);
          },
          type: AppButtonType.primary,
        ),
      ],
    );
  }

  Widget _buildErrorDialog(String error) {
    final l10n = L10n.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(Icons.error, color: AppColors.error),
          const SizedBox(width: AppDimensions.spacingS),
          Text(l10n.errorTitle),
        ],
      ),
      content: Text(l10n.userInfoFetchFailed(error)),
      actions: [
        AppButton.outline(
          text: l10n.closeButtonText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientEnd,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: AppColors.overlayLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              Icons.event_available,
              color: AppColors.textWhite,
              size: AppDimensions.iconL,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDialogTitle(),
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: AppDimensions.fontSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  widget.event.name,
                  style: const TextStyle(
                    color: AppColors.overlayMedium,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: AppColors.textWhite,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.overlayLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    if (_eventGame == null) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              color: AppColors.backgroundDark,
            ),
            child: _eventGame!.iconUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    child: Image.network(
                      _eventGame!.iconUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.gamepad,
                        color: AppColors.textSecondary,
                        size: AppDimensions.iconL,
                      ),
                    ),
                  )
                : Icon(
                    Icons.gamepad,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconL,
                  ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.eventTargetGameLabel,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  _eventGame!.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatusSection() {
    final l10n = L10n.of(context);
    switch (_profileStatus) {
      case ProfileRequirementStatus.checking:
        return _buildStatusCard(
          icon: Icons.hourglass_top,
          iconColor: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          borderColor: AppColors.info.withValues(alpha: 0.3),
          title: l10n.checkingProfileTitle,
          content: Column(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(l10n.checkingGameProfileText),
            ],
          ),
        );

      case ProfileRequirementStatus.ready:
        return _buildStatusCard(
          icon: Icons.check_circle,
          iconColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.3),
          title: l10n.profileReadyTitle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.gameUsernameSetText),
              const SizedBox(height: AppDimensions.spacingM),
              _buildProfileInfo(),
            ],
          ),
        );

      case ProfileRequirementStatus.needsSetup:
        return _buildStatusCard(
          icon: Icons.warning,
          iconColor: AppColors.warning,
          backgroundColor: AppColors.warning.withValues(alpha: 0.1),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
          title: l10n.profileSetupRequiredTitle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _needsFavoriteRegistration
                    ? l10n.registerFavoriteAndCreateProfileText
                    : l10n.createProfileForGameText,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppButton.primary(
                text: _needsFavoriteRegistration
                    ? l10n.registerFavoriteAndCreateProfileButtonText
                    : l10n.createProfileButtonText,
                onPressed: _handleCreateProfile,
                isFullWidth: true,
              ),
            ],
          ),
        );

      case ProfileRequirementStatus.needsUsername:
        return _buildStatusCard(
          icon: Icons.error,
          iconColor: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          borderColor: AppColors.error.withValues(alpha: 0.3),
          title: l10n.usernameSetupRequiredTitle,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.setGameUsernameInProfileText),
              const SizedBox(height: AppDimensions.spacingM),
              AppButton.primary(
                text: l10n.editProfileButtonText,
                onPressed: _navigateToProfileEdit,
                isFullWidth: true,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: AppDimensions.iconM),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          content,
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    if (_existingGameProfile == null) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
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
                l10n.gameUsernameLabel,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _existingGameProfile!.gameUsername,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_existingGameProfile!.gameUserId.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Icon(
                  Icons.badge,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  l10n.userIdLabelText,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _existingGameProfile!.gameUserId,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          AppButton.outline(
            text: l10n.editProfileButtonText,
            onPressed: _navigateToProfileEdit,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationFeeSection() {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: AppColors.warning, size: AppDimensions.iconM),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.participationFeeLabel,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  widget.event.participationFeeText ?? l10n.contactOrganizerForDetailsText,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    final l10n = L10n.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.eventPasswordLabel,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: l10n.enterPasswordHintText,
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
              filled: true,
              fillColor: AppColors.backgroundLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSection() {
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.messageToOrganizerLabel,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        AppTextField(
          controller: _messageController,
          hintText: l10n.messageToOrganizerHintText,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
        border: const Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: _buildFooterContent(),
    );
  }

  Widget _buildFooterContent() {
    // プロフィールが設定されていない場合は、設定ボタンのみ表示
    if (_profileStatus == ProfileRequirementStatus.needsSetup ||
        _profileStatus == ProfileRequirementStatus.needsUsername) {
      return Column(
        children: [
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            AppButton.primary(
              text: _getButtonText(),
              onPressed: _getButtonAction(),
              isFullWidth: true,
            ),
          const SizedBox(height: AppDimensions.spacingM),
          AppButton.outline(
            text: L10n.of(context).cancelButtonText,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            isFullWidth: true,
          ),
        ],
      );
    }

    // プロフィールが設定されている場合は、従来の横並び
    return Row(
      children: [
        Expanded(
          child: AppButton.outline(
            text: L10n.of(context).cancelButtonText,
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : AppButton.primary(
                  text: _getButtonText(),
                  onPressed: _canSubmitApplication() ? _handleParticipation : null,
                ),
        ),
      ],
    );
  }

  String _getDialogTitle() {
    final l10n = L10n.of(context);
    switch (widget.event.visibility) {
      case EventVisibility.public:
        return l10n.participationApplicationTitle;
      case EventVisibility.private:
        return l10n.privateEventTitle;
      case EventVisibility.inviteOnly:
        return l10n.inviteOnlyEventTitle;
    }
  }

  String _getButtonText() {
    final l10n = L10n.of(context);
    switch (_profileStatus) {
      case ProfileRequirementStatus.checking:
        return l10n.checkingStatusText;
      case ProfileRequirementStatus.needsSetup:
        return l10n.setupProfileButtonText;
      case ProfileRequirementStatus.needsUsername:
        return l10n.setupUsernameButtonText;
      case ProfileRequirementStatus.ready:
        if (widget.event.visibility == EventVisibility.private) {
          return l10n.cannotApplyButtonText;
        }
        return widget.event.visibility == EventVisibility.inviteOnly
            ? l10n.applyButtonText
            : l10n.joinButtonText;
    }
  }

  VoidCallback? _getButtonAction() {
    switch (_profileStatus) {
      case ProfileRequirementStatus.checking:
        return null;
      case ProfileRequirementStatus.needsSetup:
        return _handleCreateProfile;
      case ProfileRequirementStatus.needsUsername:
        return _navigateToProfileEdit;
      case ProfileRequirementStatus.ready:
        return _canSubmitApplication() ? _handleParticipation : null;
    }
  }

  /// 現在の参加者数を取得
  Future<void> _loadParticipantCount() async {
    try {
      final count = await ParticipationService.getApprovedParticipantCount(widget.event.id);
      if (mounted) {
        setState(() {
          _currentParticipantCount = count;
          _isLoadingParticipantCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentParticipantCount = 0;
          _isLoadingParticipantCount = false;
        });
      }
    }
  }

  bool _canSubmitApplication() {
    if (_isLoading) return false;
    if (widget.event.visibility == EventVisibility.private) return false;
    if (_profileStatus != ProfileRequirementStatus.ready) return false;
    if (widget.event.visibility == EventVisibility.inviteOnly &&
        _passwordController.text.trim().isEmpty) {
      return false;
    }
    // 満員の場合は申込不可
    if (_currentParticipantCount >= widget.event.maxParticipants) {
      return false;
    }
    return true;
  }

  Future<void> _handleParticipation() async {
    if (!_canSubmitApplication()) return;

    final currentUser = ref.read(currentUserDataProvider).value;
    if (currentUser == null || _existingGameProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ParticipationService.applyToEvent(
        eventId: widget.event.id,
        userId: currentUser.id,
        userDisplayName: currentUser.displayName,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        password: widget.event.visibility == EventVisibility.inviteOnly
            ? _passwordController.text.trim()
            : null,
        gameUsername: _existingGameProfile!.gameUsername,
        gameUserId: _existingGameProfile!.gameUserId,
        gameProfile: _existingGameProfile,
      );

      if (mounted) {
        if (result == ParticipationResult.success) {
          Navigator.of(context).pop(true);
          _showSuccessDialog();
        } else {
          _showErrorDialog(_getErrorMessage(result));
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(L10n.of(context).unexpectedErrorText);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateProfile() async {
    if (_eventGame == null) return;

    final currentUser = ref.read(currentUserDataProvider).value;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_needsFavoriteRegistration) {
        final userRepository = UserRepository();
        final dataGame = _convertToDataGame(_eventGame!);
        await userRepository.addFavoriteGame(currentUser.id, dataGame);
        ref.invalidate(currentUserDataProvider);
      }

      final result = await Navigator.of(context).pushNamed(
        '/game_profile_edit',
        arguments: {
          'gameId': _eventGame!.id,
          'gameName': _eventGame!.name,
          'gameIconUrl': _eventGame!.iconUrl,
          'existingProfile': null,
          'returnToEventDetail': true,
        },
      );

      if (result == true && mounted) {
        await _checkRequirements();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(L10n.of(context).profileCreationErrorText);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToProfileEdit() async {
    final gameId = widget.event.gameId;
    if (gameId == null || gameId.isEmpty) {
      _showErrorDialog(L10n.of(context).gameInfoNotFoundText);
      return;
    }

    final result = await Navigator.of(context).pushNamed(
      '/game_profile_edit',
      arguments: {
        'gameId': gameId,
        'gameName': _eventGame?.name ?? L10n.of(context).gameFallbackText,
        'gameIconUrl': _eventGame?.iconUrl,
        'existingProfile': _existingGameProfile,
        'returnToEventDetail': true,
      },
    );

    if (result == true && mounted) {
      await _checkRequirements();
    }
  }

  void _showSuccessDialog() {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.applicationCompleteTitle),
          ],
        ),
        content: Text(
          widget.event.visibility == EventVisibility.public
              ? l10n.participationConfirmedText
              : l10n.applicationReceivedText,
        ),
        actions: [
          AppButton.primary(
            text: l10n.okButtonText,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.errorTitle),
          ],
        ),
        content: Text(message),
        actions: [
          AppButton.outline(
            text: l10n.okButtonText,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  /// SharedGame.Game から DataGame.Game に変換
  DataGame.Game _convertToDataGame(SharedGame.Game sharedGame) {
    return DataGame.Game(
      id: sharedGame.id,
      name: sharedGame.name,
      developer: sharedGame.developer,
      description: sharedGame.description,
      genres: sharedGame.genres,
      platforms: sharedGame.platforms,
      iconUrl: sharedGame.iconUrl,
      rating: sharedGame.rating,
      isPopular: sharedGame.isPopular,
    );
  }

  /// 参加者数情報セクションを構築
  Widget _buildParticipantCountSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: _currentParticipantCount >= widget.event.maxParticipants
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: _currentParticipantCount >= widget.event.maxParticipants
              ? AppColors.error
              : AppColors.primary,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _currentParticipantCount >= widget.event.maxParticipants
                ? Icons.group_off
                : Icons.group,
            color: _currentParticipantCount >= widget.event.maxParticipants
                ? AppColors.error
                : AppColors.primary,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: _isLoadingParticipantCount
                ? Row(
                    children: [
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(L10n.of(context).participantCountLoadingText),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            L10n.of(context).participantCountLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            L10n.of(context).participantCountValueText(_currentParticipantCount, widget.event.maxParticipants),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _currentParticipantCount >= widget.event.maxParticipants
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_currentParticipantCount >= widget.event.maxParticipants)
                        Text(
                          L10n.of(context).eventFullNoteText,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(ParticipationResult result) {
    final l10n = L10n.of(context);
    switch (result) {
      case ParticipationResult.eventNotFound:
        return l10n.eventNotFoundErrorText;
      case ParticipationResult.cannotApply:
        return l10n.cannotApplyToEventErrorText;
      case ParticipationResult.alreadyApplied:
        return l10n.alreadyAppliedErrorText;
      case ParticipationResult.incorrectPassword:
        return l10n.incorrectPasswordErrorText;
      case ParticipationResult.eventFull:
        return l10n.eventFullErrorText;
      case ParticipationResult.permissionDenied:
        return l10n.permissionDeniedErrorText;
      case ParticipationResult.networkError:
        return l10n.networkErrorText;
      case ParticipationResult.unknownError:
        return l10n.unknownErrorText;
      case ParticipationResult.success:
        return l10n.applicationCompleteText;
    }
  }
}