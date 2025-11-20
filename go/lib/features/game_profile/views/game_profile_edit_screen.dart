import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/text_input_field.dart';
import '../../../shared/widgets/selection_button_group.dart';
import '../../../data/models/game_profile_model.dart';
import '../providers/game_profile_provider.dart';
import '../../../shared/providers/auth_provider.dart';

/// ゲームプロフィール編集画面
class GameProfileEditScreen extends ConsumerStatefulWidget {
  final GameProfile? profile;
  final String? gameIconUrl;
  final String? gameName;  // シェアデータから取得したゲーム名
  final String gameId;     // 必須：実際のゲームID
  final bool readOnly;     // 読み取り専用モード

  const GameProfileEditScreen({
    super.key,
    this.profile,
    this.gameIconUrl,
    this.gameName,
    required this.gameId,
    this.readOnly = false,
  });

  bool get isEditing => profile != null;

  @override
  ConsumerState<GameProfileEditScreen> createState() => _GameProfileEditScreenState();
}

class _GameProfileEditScreenState extends ConsumerState<GameProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // フォーム入力用コントローラー
  late final TextEditingController _gameNameController;
  late final TextEditingController _gameUsernameController;
  late final TextEditingController _gameUserIdController;
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

    print('🔄 GameProfileEditScreen: Initializing with profile data');
    print('   profile: ${profile != null ? 'exists' : 'null'}');
    print('   widget.gameId: ${widget.gameId}');
    print('   widget.gameName: ${widget.gameName}');
    print('   widget.gameIconUrl: ${widget.gameIconUrl}');
    print('   isEditing: ${widget.isEditing}');

    if (profile != null) {
      print('   profile.id: ${profile.id}');
      print('   profile.gameId: ${profile.gameId}');
      print('   profile.userId: ${profile.userId}');
      print('   profile.gameUsername: "${profile.gameUsername}"');
      print('   profile.gameUserId: "${profile.gameUserId}"');
      print('   profile.rankOrLevel: "${profile.rankOrLevel}"');
      print('   profile.achievements: "${profile.achievements}"');
      print('   profile.notes: "${profile.notes}"');
      print('   profile.voiceChatDetails: "${profile.voiceChatDetails}"');
      print('   profile.experience: ${profile.experience}');
      print('   profile.playStyles: ${profile.playStyles}');
      print('   profile.activityTimes: ${profile.activityTimes}');
      print('   profile.useInGameVC: ${profile.useInGameVC}');
    }

    _gameNameController = TextEditingController(text: widget.gameName ?? profile?.gameId ?? '');
    _gameUsernameController = TextEditingController(text: profile?.gameUsername ?? '');
    _gameUserIdController = TextEditingController(text: profile?.gameUserId ?? '');
    _rankOrLevelController = TextEditingController(text: profile?.rankOrLevel ?? '');
    _achievementsController = TextEditingController(text: profile?.achievements ?? '');
    _notesController = TextEditingController(text: profile?.notes ?? '');
    _voiceChatDetailsController = TextEditingController(text: profile?.voiceChatDetails ?? '');

    _selectedExperience = profile?.experience;
    _selectedPlayStyles = List<PlayStyle>.from(profile?.playStyles ?? []);
    _selectedActivityTimes = List<ActivityTime>.from(profile?.activityTimes ?? []);
    _useInGameVC = profile?.useInGameVC ?? false;

    print('✅ GameProfileEditScreen: Controllers initialized');
    print('   gameNameController.text: "${_gameNameController.text}"');
    print('   gameUsernameController.text: "${_gameUsernameController.text}"');
    print('   gameUserIdController.text: "${_gameUserIdController.text}"');
    print('   rankOrLevelController.text: "${_rankOrLevelController.text}"');
    print('   achievementsController.text: "${_achievementsController.text}"');
    print('   notesController.text: "${_notesController.text}"');
    print('   voiceChatDetailsController.text: "${_voiceChatDetailsController.text}"');
    print('   selectedExperience: $_selectedExperience');
    print('   selectedPlayStyles: $_selectedPlayStyles');
    print('   selectedActivityTimes: $_selectedActivityTimes');
    print('   useInGameVC: $_useInGameVC');
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _gameUsernameController.dispose();
    _gameUserIdController.dispose();
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
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
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
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
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
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        child: widget.gameIconUrl?.isNotEmpty == true
            ? Image.network(
                widget.gameIconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultGameIcon(),
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
        color: isEditing ? AppColors.primary.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isEditing ? AppColors.primary.withValues(alpha: 0.3) : AppColors.success.withValues(alpha: 0.3),
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
          label: 'ゲーム内ユーザー名（任意）',
          hintText: '例: プレイヤー001, GamerTag',
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _gameUserIdController,
          label: 'ゲーム内ユーザーID（任意）',
          hintText: '例: #1234, @username, user_id_12345',
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
              _selectedExperience = _selectedExperience == experience ? null : experience;
            });
          },
          optionBuilder: (experience) => experience.displayName,
          tooltipBuilder: (experience) => experience.description,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _rankOrLevelController,
          label: 'ランク・レベル（任意）',
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
          'よくプレイする時間帯を選択してください（任意）',
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
            color: _useInGameVC ? AppColors.accent.withValues(alpha: 0.1) : AppColors.backgroundLight,
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
                color: _useInGameVC ? AppColors.accent : AppColors.textSecondary,
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
                        color: _useInGameVC ? AppColors.accent : AppColors.textDark,
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
        TextInputField(
          controller: _voiceChatDetailsController,
          label: 'VC詳細情報（任意）',
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
        TextInputField(
          controller: _achievementsController,
          label: '達成実績・アピールポイント（任意）',
          hintText: '例: 世界ランキング100位、大会優勝歴あり、配信経験あり',
          maxLines: 3,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        TextInputField(
          controller: _notesController,
          label: '自由記入・メモ（任意）',
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
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
                  icon,
                  color: AppColors.primary,
                  size: AppDimensions.iconM,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeL,
                    fontWeight: FontWeight.w600,
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
      children: options.map((option) {
        final isSelected = selectedOptions.contains(option);
        return Material(
          color: AppColors.backgroundTransparent,
          child: InkWell(
            onTap: () {
              final newSelection = List<T>.from(selectedOptions);
              if (isSelected) {
                newSelection.remove(option);
              } else {
                newSelection.add(option);
              }
              onSelectionChanged(newSelection);
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            child: Tooltip(
              message: tooltipBuilder?.call(option) ?? '',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                decoration: BoxDecoration(
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
                ),
                child: Text(
                  optionBuilder(option),
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
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

    print('🔄 GameProfileEditScreen: Saving with user info');
    print('   FirebaseUID (id): ${currentUserData.id}');
    print('   CustomUserID (userId): ${currentUserData.userId}');

    setState(() {
      _isSubmitting = true;
    });

    try {
      final GameProfile profile;
      bool success;

      if (widget.isEditing) {
        // 既存プロフィールの更新
        profile = widget.profile!.copyWith(
          userId: currentUserData.id, // 常に現在のユーザーIDを設定
          gameUsername: _gameUsernameController.text.trim(),
          gameUserId: _gameUserIdController.text.trim(),
          experience: _selectedExperience,
          playStyles: _selectedPlayStyles,
          rankOrLevel: _rankOrLevelController.text.trim(),
          activityTimes: _selectedActivityTimes,
          useInGameVC: _useInGameVC,
          voiceChatDetails: _voiceChatDetailsController.text.trim(),
          achievements: _achievementsController.text.trim(),
          notes: _notesController.text.trim(),
        );
        success = await ref.read(gameProfileServiceProvider).updateGameProfile(profile);
        print('🔄 Updating existing profile: ${profile.gameId}');
      } else {
        // 新規プロフィールの作成
        profile = GameProfile.create(
          gameId: widget.gameId,  // 必須：お気に入りゲームIDを使用
          userId: currentUserData.id,
          gameUsername: _gameUsernameController.text.trim(),
          gameUserId: _gameUserIdController.text.trim(),
          experience: _selectedExperience,
          playStyles: _selectedPlayStyles,
          rankOrLevel: _rankOrLevelController.text.trim(),
          activityTimes: _selectedActivityTimes,
          useInGameVC: _useInGameVC,
          voiceChatDetails: _voiceChatDetailsController.text.trim(),
          achievements: _achievementsController.text.trim(),
          notes: _notesController.text.trim(),
        );
        success = await ref.read(gameProfileServiceProvider).createGameProfile(profile);
        print('🔄 Creating new profile: ${profile.gameId}');
      }

      if (success && mounted) {
        Navigator.pop(context, true); // 成功フラグを返す
        _showSuccessSnackBar(
          widget.isEditing ? 'プロフィールを更新しました' : 'プロフィールを作成しました',
        );
      } else if (mounted) {
        _showErrorSnackBar('保存に失敗しました');
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

  void _onDeleteProfile() async {
    if (widget.profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィールを削除'),
        content: Text('${widget.gameName ?? widget.profile!.gameId} のプロフィールを削除しますか？\n\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
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
      final success = await ref.read(gameProfileServiceProvider).deleteGameProfile(widget.profile!.userId, widget.profile!.gameId);

      if (success && mounted) {
        Navigator.pop(context, true); // 削除成功フラグを返す
        _showSuccessSnackBar('プロフィールを削除しました');
      } else if (mounted) {
        _showErrorSnackBar('削除に失敗しました');
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
            const Icon(Icons.check_circle, color: AppColors.textWhite, size: 20),
            const SizedBox(width: 8),
            Text(message),
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