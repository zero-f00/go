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
import 'app_button.dart';
import 'auth_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    _checkRequirements();
  }

  @override
  void dispose() {
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
    final favoriteGameIds = currentUser.favoriteGameIds ?? [];
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
      loading: () => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppDimensions.spacingM),
              Text('読み込み中...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => _buildErrorDialog(error.toString()),
    );
  }

  Widget _buildLoginRequiredDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(Icons.login, color: AppColors.warning),
          const SizedBox(width: AppDimensions.spacingS),
          const Text('ログインが必要'),
        ],
      ),
      content: const Text('参加申し込みにはログインが必要です。'),
      actions: [
        AppButton.outline(
          text: '閉じる',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        AppButton(
          text: 'ログイン',
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      title: Row(
        children: [
          Icon(Icons.error, color: AppColors.error),
          const SizedBox(width: AppDimensions.spacingS),
          const Text('エラー'),
        ],
      ),
      content: Text('ユーザー情報の取得に失敗しました: $error'),
      actions: [
        AppButton.outline(
          text: '閉じる',
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
                  'イベント対象ゲーム',
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
    switch (_profileStatus) {
      case ProfileRequirementStatus.checking:
        return _buildStatusCard(
          icon: Icons.hourglass_top,
          iconColor: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.1),
          borderColor: AppColors.info.withValues(alpha: 0.3),
          title: 'プロフィールを確認中',
          content: Column(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              const Text('ゲームプロフィールを確認しています...'),
            ],
          ),
        );

      case ProfileRequirementStatus.ready:
        return _buildStatusCard(
          icon: Icons.check_circle,
          iconColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.1),
          borderColor: AppColors.success.withValues(alpha: 0.3),
          title: 'プロフィール設定完了',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ゲーム内ユーザー名が設定されています。'),
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
          title: 'プロフィール設定が必要',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _needsFavoriteRegistration
                    ? 'このゲームをお気に入り登録してプロフィールを作成してください。'
                    : 'このゲームのプロフィールを作成してください。',
              ),
              const SizedBox(height: AppDimensions.spacingM),
              AppButton.primary(
                text: _needsFavoriteRegistration
                    ? 'お気に入り登録してプロフィール作成'
                    : 'プロフィール作成',
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
          title: 'ユーザー名設定が必要',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('プロフィールにゲーム内ユーザー名を設定してください。'),
              const SizedBox(height: AppDimensions.spacingM),
              AppButton.primary(
                text: 'プロフィールを編集',
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
              const Text(
                'ゲーム内ユーザー名',
                style: TextStyle(
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
          if (_existingGameProfile!.gameUserId?.isNotEmpty == true) ...[
            const SizedBox(height: AppDimensions.spacingS),
            Row(
              children: [
                Icon(
                  Icons.badge,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                const Text(
                  'ユーザーID',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _existingGameProfile!.gameUserId!,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppDimensions.spacingM),
          AppButton.outline(
            text: 'プロフィールを編集',
            onPressed: _navigateToProfileEdit,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationFeeSection() {
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
                const Text(
                  '参加費',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  widget.event.participationFeeText ?? '詳細は主催者にお問い合わせください',
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'イベントパスワード',
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
              hintText: 'パスワードを入力してください',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '主催者へのメッセージ（任意）',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '主催者へのメッセージを入力（任意）',
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
      child: Row(
        children: [
          Expanded(
            child: AppButton.outline(
              text: 'キャンセル',
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
      ),
    );
  }

  String _getDialogTitle() {
    switch (widget.event.visibility) {
      case EventVisibility.public:
        return '参加申し込み';
      case EventVisibility.private:
        return 'プライベートイベント';
      case EventVisibility.inviteOnly:
        return '招待制イベント';
    }
  }

  String _getButtonText() {
    switch (_profileStatus) {
      case ProfileRequirementStatus.checking:
        return '確認中...';
      case ProfileRequirementStatus.needsSetup:
        return 'プロフィール設定が必要';
      case ProfileRequirementStatus.needsUsername:
        return 'ユーザー名設定が必要';
      case ProfileRequirementStatus.ready:
        if (widget.event.visibility == EventVisibility.private) {
          return '申し込めません';
        }
        return widget.event.visibility == EventVisibility.inviteOnly
            ? '申し込む'
            : '参加する';
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
        userDisplayName: currentUser.displayName ?? 'Unknown',
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
      _showErrorDialog('予期しないエラーが発生しました。しばらく経ってからお試しください。');
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
      _showErrorDialog('プロフィール作成中にエラーが発生しました。');
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
      _showErrorDialog('ゲーム情報が取得できませんでした。');
      return;
    }

    final result = await Navigator.of(context).pushNamed(
      '/game_profile_edit',
      arguments: {
        'gameId': gameId,
        'gameName': _eventGame?.name ?? 'ゲーム',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('申し込み完了'),
          ],
        ),
        content: Text(
          widget.event.visibility == EventVisibility.public
              ? 'イベントへの参加が確定しました！'
              : '申し込みを受け付けました。主催者による承認をお待ちください。',
        ),
        actions: [
          AppButton.primary(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('エラー'),
          ],
        ),
        content: Text(message),
        actions: [
          AppButton.outline(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
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

  String _getErrorMessage(ParticipationResult result) {
    switch (result) {
      case ParticipationResult.eventNotFound:
        return 'イベントが見つかりませんでした。';
      case ParticipationResult.cannotApply:
        return 'このイベントには参加申し込みができません。';
      case ParticipationResult.alreadyApplied:
        return '既にこのイベントに申し込み済みです。';
      case ParticipationResult.incorrectPassword:
        return 'パスワードが間違っています。';
      case ParticipationResult.permissionDenied:
        return 'アクセス権限がありません。';
      case ParticipationResult.networkError:
        return 'ネットワークエラーが発生しました。';
      case ParticipationResult.unknownError:
        return '予期しないエラーが発生しました。';
      case ParticipationResult.success:
        return '申し込みが完了しました。';
    }
  }
}