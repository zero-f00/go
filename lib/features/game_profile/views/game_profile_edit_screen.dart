import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/text_input_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/selection_button_group.dart';
import '../../../data/models/game_profile_model.dart';
import '../providers/game_profile_provider.dart';
import '../../../shared/providers/auth_provider.dart';

/// ゲームプロフィール編集画面
class GameProfileEditScreen extends ConsumerStatefulWidget {
  final GameProfile? profile;
  final String? gameIconUrl;
  final String? gameName;
  final String gameId;

  const GameProfileEditScreen({
    super.key,
    this.profile,
    this.gameIconUrl,
    this.gameName,
    required this.gameId,
  });

  bool get isEditing => profile != null;

  @override
  ConsumerState<GameProfileEditScreen> createState() =>
      _GameProfileEditScreenState();
}

class _GameProfileEditScreenState extends ConsumerState<GameProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // フォーム入力用コントローラー
  late final TextEditingController _gameNameController;
  late final TextEditingController _gameUsernameController;
  late final TextEditingController _gameUserIdController;
  late final TextEditingController _clanController;
  late final TextEditingController _rankOrLevelController;
  late final TextEditingController _achievementsController;
  late final TextEditingController _notesController;
  late final TextEditingController _voiceChatDetailsController;

  // 選択状態
  GameExperience? _selectedExperience;
  late List<PlayStyle> _selectedPlayStyles;
  late List<ActivityTime> _selectedActivityTimes;
  late bool _useInGameVC;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.profile;


    // ゲーム名（表示用）
    final gameName = widget.gameName ?? profile?.gameId ?? '';
    _gameNameController = TextEditingController(text: gameName);

    // ユーザー入力フィールド
    final gameUsername = profile?.gameUsername ?? '';
    final gameUserId = profile?.gameUserId ?? '';
    final clan = profile?.clan ?? '';
    final rankOrLevel = profile?.rankOrLevel ?? '';
    final achievements = profile?.achievements ?? '';
    final notes = profile?.notes ?? '';
    final voiceChatDetails = profile?.voiceChatDetails ?? '';

    _gameUsernameController = TextEditingController(text: gameUsername);
    _gameUserIdController = TextEditingController(text: gameUserId);
    _clanController = TextEditingController(text: clan);
    _rankOrLevelController = TextEditingController(text: rankOrLevel);
    _achievementsController = TextEditingController(text: achievements);
    _notesController = TextEditingController(text: notes);
    _voiceChatDetailsController = TextEditingController(text: voiceChatDetails);

    // 選択状態の初期化
    _selectedExperience = profile?.experience;
    _selectedPlayStyles = List<PlayStyle>.from(profile?.playStyles ?? []);
    _selectedActivityTimes = List<ActivityTime>.from(
      profile?.activityTimes ?? [],
    );
    _useInGameVC = profile?.useInGameVC ?? false;

    // 既存プロフィールがあるのにフォームが空の場合の修正処理
    if (profile != null &&
        _gameUsernameController.text.isEmpty &&
        profile.gameUsername.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _gameUsernameController.text = profile.gameUsername;
          _gameUserIdController.text = profile.gameUserId;
          _clanController.text = profile.clan;
          _rankOrLevelController.text = profile.rankOrLevel;
          _achievementsController.text = profile.achievements;
          _notesController.text = profile.notes;
          _voiceChatDetailsController.text = profile.voiceChatDetails;
          _selectedExperience = profile.experience;
          _selectedPlayStyles = List<PlayStyle>.from(profile.playStyles);
          _selectedActivityTimes = List<ActivityTime>.from(
            profile.activityTimes,
          );
          _useInGameVC = profile.useInGameVC;
        });
      });
    }
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _gameUsernameController.dispose();
    _gameUserIdController.dispose();
    _clanController.dispose();
    _rankOrLevelController.dispose();
    _achievementsController.dispose();
    _notesController.dispose();
    _voiceChatDetailsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: widget.isEditing ? 'プロフィール編集' : 'ゲームプロフィール作成',
                showBackButton: true,
                showUserIcon: false,
                actions: [
                  if (widget.isEditing)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.textWhite,
                        size: AppDimensions.iconM,
                      ),
                      onPressed: () => _onDeleteProfile(),
                      tooltip: 'プロフィールを削除',
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingL),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: AppDimensions.cardElevation,
                          offset: const Offset(0, AppDimensions.shadowOffsetY),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppDimensions.spacingL),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileStatusCard(),
                                const SizedBox(height: AppDimensions.spacingM),
                                _buildBasicInfoSection(),
                                _buildExperienceSection(),
                                _buildPlayStyleSection(),
                                _buildActivityTimeSection(),
                                _buildVoiceChatSection(),
                                _buildAdditionalInfoSection(),
                                const SizedBox(height: AppDimensions.spacingL),
                                _buildActionButtons(),
                                const SizedBox(height: AppDimensions.spacingL),
                              ],
                            ),
                          ),
                        ),
                        if (_isSubmitting)
                          const LoadingOverlay(message: '保存中...'),
                      ],
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

  Widget _buildGameNameDisplay() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _buildGameIcon(),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ゲーム名',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  _gameNameController.text.isNotEmpty
                      ? _gameNameController.text
                      : '選択されたゲーム',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: widget.gameIconUrl?.isNotEmpty == true
            ? Image.network(
                widget.gameIconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildDefaultGameIcon(),
              )
            : _buildDefaultGameIcon(),
      ),
    );
  }

  Widget _buildDefaultGameIcon() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: Icon(
        Icons.videogame_asset,
        color: AppColors.primary,
        size: AppDimensions.iconM,
      ),
    );
  }

  Widget _buildProfileStatusCard() {
    final isEditing = widget.isEditing;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: isEditing
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isEditing
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingS),
            decoration: BoxDecoration(
              color: isEditing ? AppColors.primary : AppColors.success,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add_circle_outline,
              color: AppColors.textWhite,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? '既存プロフィールを編集' : '新しいプロフィールを作成',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  isEditing
                      ? '${widget.gameName ?? widget.profile!.gameId} のプロフィール情報を変更できます'
                      : 'すべての項目は任意入力です。後から編集も可能です',
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
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: '基本情報',
      icon: Icons.info_outline,
      children: [
        _buildGameNameDisplay(),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _gameUsernameController,
          label: 'ゲーム内ユーザー名',
          hintText: '例: プレイヤー001, GamerTag',
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _gameUserIdController,
          label: 'ゲーム内ユーザーID',
          hintText: '例: #1234, @username, user_id_12345',
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _clanController,
          label: 'クラン名',
          hintText: '例: TeamAlpha, ProGuild, [ABC]Clan',
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return _buildSection(
      title: 'ゲーム歴・レベル',
      icon: Icons.trending_up,
      children: [
        SelectionButtonGroup<GameExperience>(
          label: 'ゲーム歴',
          options: GameExperience.values,
          selectedOption: _selectedExperience,
          onSelectionChanged: (experience) {
            setState(() {
              // 既に選択されている場合は選択解除、そうでない場合は選択
              _selectedExperience = _selectedExperience == experience
                  ? null
                  : experience;
            });
          },
          optionBuilder: (experience) => experience.displayName,
          tooltipBuilder: (experience) => experience.description,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _rankOrLevelController,
          label: 'ランク・レベル',
          hintText: '例: ダイヤモンド, レベル50, プラチナⅢ',
        ),
      ],
    );
  }

  Widget _buildPlayStyleSection() {
    return _buildSection(
      title: 'プレイスタイル',
      icon: Icons.sports_esports,
      children: [
        Text(
          '当てはまるものを選択してください（任意）',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildMultiSelectionChips<PlayStyle>(
          options: PlayStyle.values,
          selectedOptions: _selectedPlayStyles,
          onSelectionChanged: (playStyles) {
            setState(() {
              _selectedPlayStyles = playStyles;
            });
          },
          optionBuilder: (style) => style.displayName,
          tooltipBuilder: (style) => style.description,
        ),
      ],
    );
  }

  Widget _buildActivityTimeSection() {
    return _buildSection(
      title: '活動時間帯',
      icon: Icons.schedule,
      children: [
        Text(
          'よくプレイする時間帯を選択してください',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildMultiSelectionChips<ActivityTime>(
          options: ActivityTime.values,
          selectedOptions: _selectedActivityTimes,
          onSelectionChanged: (times) {
            setState(() {
              _selectedActivityTimes = times;
            });
          },
          optionBuilder: (time) => time.displayName,
        ),
      ],
    );
  }

  Widget _buildVoiceChatSection() {
    return _buildSection(
      title: 'ボイスチャット',
      icon: Icons.mic,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: _useInGameVC
                ? AppColors.accent.withValues(alpha: 0.1)
                : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: _useInGameVC ? AppColors.accent : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _useInGameVC ? Icons.mic : Icons.mic_off,
                color: _useInGameVC
                    ? AppColors.accent
                    : AppColors.textSecondary,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ゲーム内VC',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: _useInGameVC
                            ? AppColors.accent
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      _useInGameVC ? '利用可能' : '利用不可',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useInGameVC,
                onChanged: (value) {
                  setState(() {
                    _useInGameVC = value;
                  });
                },
                activeThumbColor: AppColors.accent,
                activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.backgroundLight,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AppTextField(
          controller: _voiceChatDetailsController,
          label: 'VC詳細情報',
          hintText: '例: ゲーム内VCメイン、Discord: user#1234、○時以降はVC可能',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      title: 'その他の情報',
      icon: Icons.notes,
      children: [
        AppTextField(
          controller: _achievementsController,
          label: '達成実績・アピールポイント',
          hintText: '例: 世界ランキング100位、大会優勝歴あり、配信経験あり',
          maxLines: 3,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        AppTextField(
          controller: _notesController,
          label: '自由記入・メモ',
          hintText: '例: 初心者歓迎、まったりプレイ希望、ボイスチャット可能',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingM),
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
              Icon(icon, color: AppColors.accent, size: AppDimensions.iconM),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMultiSelectionChips<T>({
    required List<T> options,
    required List<T> selectedOptions,
    required Function(List<T>) onSelectionChanged,
    required String Function(T) optionBuilder,
    String Function(T)? tooltipBuilder,
  }) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      children: options
          .map(
            (option) => _buildSelectionChip(
              option: option,
              isSelected: selectedOptions.contains(option),
              onTap: () =>
                  _toggleSelection(option, selectedOptions, onSelectionChanged),
              label: optionBuilder(option),
              tooltip: tooltipBuilder?.call(option) ?? '',
            ),
          )
          .toList(),
    );
  }

  Widget _buildSelectionChip<T>({
    required T option,
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
    required String tooltip,
  }) {
    return Material(
      color: AppColors.backgroundTransparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: Tooltip(
          message: tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: _buildChipDecoration(isSelected),
            child: Text(label, style: _buildChipTextStyle(isSelected)),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildChipDecoration(bool isSelected) {
    return BoxDecoration(
      color: isSelected ? AppColors.accent : AppColors.backgroundLight,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      border: Border.all(
        color: isSelected ? AppColors.accent : AppColors.border,
        width: 2,
      ),
      boxShadow: isSelected
          ? [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ]
          : null,
    );
  }

  TextStyle _buildChipTextStyle(bool isSelected) {
    return TextStyle(
      fontSize: AppDimensions.fontSizeS,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: isSelected ? AppColors.textWhite : AppColors.textDark,
    );
  }

  void _toggleSelection<T>(
    T option,
    List<T> selectedOptions,
    Function(List<T>) onSelectionChanged,
  ) {
    final newSelection = List<T>.from(selectedOptions);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else {
      newSelection.add(option);
    }
    onSelectionChanged(newSelection);
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: AppButton.primary(
        text: widget.isEditing ? '変更を保存' : 'プロフィールを作成',
        onPressed: _isSubmitting ? null : _onSave,
        isFullWidth: true,
        isEnabled: !_isSubmitting,
      ),
    );
  }

  void _onSave() async {
    // バリデーションを削除 - すべての項目が任意のため

    final currentUserData = await ref.read(currentUserDataProvider.future);
    if (currentUserData == null) {
      _showErrorSnackBar('ユーザー情報の取得に失敗しました');
      return;
    }

    // 編集時：プロフィールの所有者確認とuserIdの修正
    if (widget.isEditing) {
      // プロフィールのuserIdが空の場合の処理は保存時に修正
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final GameProfile profile;
      bool success;

      if (widget.isEditing) {
        // 既存プロフィールの更新
        // userIdが空の場合は現在のユーザーIDで修正
        final userIdToUse = widget.profile!.userId.isEmpty
            ? currentUserData.id
            : widget.profile!.userId;

        profile = widget.profile!.copyWith(
          userId: userIdToUse,
          gameUsername: _gameUsernameController.text.trim(),
          gameUserId: _gameUserIdController.text.trim(),
          clan: _clanController.text.trim(),
          experience: _selectedExperience,
          playStyles: _selectedPlayStyles,
          rankOrLevel: _rankOrLevelController.text.trim(),
          activityTimes: _selectedActivityTimes,
          useInGameVC: _useInGameVC,
          voiceChatDetails: _voiceChatDetailsController.text.trim(),
          achievements: _achievementsController.text.trim(),
          notes: _notesController.text.trim(),
          updatedAt: DateTime.now(),
        );
        success = await ref
            .read(gameProfileServiceProvider)
            .updateGameProfile(profile);
      } else {
        // 新規プロフィールの作成
        profile = GameProfile.create(
          gameId: widget.gameId, // 必須：お気に入りゲームIDを使用
          userId: currentUserData.id,
          gameUsername: _gameUsernameController.text.trim(),
          gameUserId: _gameUserIdController.text.trim(),
          clan: _clanController.text.trim(),
          experience: _selectedExperience,
          playStyles: _selectedPlayStyles,
          rankOrLevel: _rankOrLevelController.text.trim(),
          activityTimes: _selectedActivityTimes,
          useInGameVC: _useInGameVC,
          voiceChatDetails: _voiceChatDetailsController.text.trim(),
          achievements: _achievementsController.text.trim(),
          notes: _notesController.text.trim(),
        );
        success = await ref
            .read(gameProfileServiceProvider)
            .createGameProfile(profile);
      }

      if (success && mounted) {
        Navigator.pop(context, true); // 成功フラグを返す
        _showSuccessSnackBar(
          widget.isEditing ? 'プロフィールを更新しました' : 'プロフィールを作成しました',
        );
      } else if (mounted) {
        _showErrorSnackBar('保存に失敗しました。もう一度お試しください。');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().contains('Exception: ')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'エラーが発生しました: $e';
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _onDeleteProfile() async {
    if (widget.profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィールを削除'),
        content: Text(
          '${widget.gameName ?? widget.profile!.gameId} のプロフィールを削除しますか？\n\nお気に入りゲームからも削除されます。\n\nこの操作は元に戻せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 現在のユーザー情報を取得
      final currentUserData = await ref.read(currentUserDataProvider.future);
      if (currentUserData == null) {
        _showErrorSnackBar('ユーザー情報の取得に失敗しました');
        return;
      }

      // 1. お気に入りゲームから削除（usersコレクションのfavoriteGameIdsフィールドから削除）
      try {
        await ref
            .read(userRepositoryProvider)
            .removeFavoriteGame(currentUserData.id, widget.gameId);
      } catch (e) {
        // お気に入り削除に失敗してもプロフィール削除は続行
      }

      // 2. ゲームプロフィールを削除（gameProfilesコレクションから削除）
      try {
        final profileDeleteSuccess = await ref
            .read(gameProfileServiceProvider)
            .deleteGameProfile(currentUserData.id, widget.gameId);

        if (!profileDeleteSuccess) {
          // プロフィールが存在しない場合もあるので、エラーとして扱わない
        }
      } catch (e) {
        // プロフィール削除に失敗しても続行
      }

      // プロバイダーのキャッシュを強制更新
      ref.invalidate(currentUserDataProvider);
      ref.invalidate(gameProfileListProvider);

      if (mounted) {
        _showSuccessSnackBar('ゲームプロフィールとお気に入りから削除しました');
        // 少し待ってから画面を閉じる（メッセージを表示する時間を確保）
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context, true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('エラーが発生しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.textWhite,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.textWhite, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
      ),
    );
  }
}
