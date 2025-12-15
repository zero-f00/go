import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/models/game.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/widgets/user_search_dialog.dart';
import '../../../shared/widgets/friend_selection_dialog.dart';
import '../../../shared/widgets/tag_input_field.dart';
import '../../../shared/widgets/streaming_url_input_field.dart';
import '../../../shared/widgets/user_tag.dart';
import '../../../shared/widgets/game_selection_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/services/validation_service.dart';
import '../../../shared/services/participation_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../game_event_management/models/game_event.dart';
import '../../../shared/widgets/past_event_images_selection_dialog.dart';
import '../../../shared/widgets/app_text_field.dart';

class EventCreationScreen extends StatefulWidget {
  final GameEvent? editingEvent; // 編集する既存イベント（コピー用データも含む）

  const EventCreationScreen({
    super.key,
    this.editingEvent,
  });

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _eventNameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _prizeContentController = TextEditingController();
  final _contactController = TextEditingController();
  final _policyController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _feeAmountController = TextEditingController();
  final _feeSupplementController = TextEditingController();
  final _eventPasswordController = TextEditingController();

  // Form state variables
  bool _hasPrize = false;
  Game? _selectedGame;
  final List<String> _selectedPlatforms = [];
  String _visibility = 'パブリック';
  String _language = '日本語';
  bool _hasStreaming = false;
  bool _hasParticipationFee = false;
  bool _hasAgeRestriction = false;
  int _minAge = 0;
  String _approvalMethod = '自動承認';

  List<String> _eventTags = [];
  List<String> _streamingUrls = [];
  List<UserData> _selectedManagers = [];
  List<UserData> _selectedSponsors = [];
  List<UserData> _blockedUsers = [];
  List<UserData> _invitedUsers = [];

  DateTime? _eventDate;
  DateTime? _registrationDeadline;
  File? _selectedImage;
  String? _existingImageUrl; // 編集モード時の既存画像URL
  bool _useExistingImage = false; // 前回の画像を使用するフラグ


  final ImagePicker _imagePicker = ImagePicker();

  // Firebase operations loading states
  bool _isCreatingEvent = false;
  bool _isSavingDraft = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeFormForEditing();
  }

  /// 編集・コピーモード時にフォームを初期化
  void _initializeFormForEditing() {
    if (widget.editingEvent != null) {
      final event = widget.editingEvent!;

      // テキストフィールドの初期値設定
      _eventNameController.text = event.name;
      _subtitleController.text = event.subtitle ?? '';
      _descriptionController.text = event.description;
      _rulesController.text = event.rules ?? '';
      _maxParticipantsController.text = event.maxParticipants.toString();
      _prizeContentController.text = event.prizeContent ?? '';
      _contactController.text = event.contactInfo ?? '';
      _policyController.text = event.policy ?? '';
      _additionalInfoController.text = event.additionalInfo ?? '';
      _streamingUrls = List.from(event.streamingUrls);


      // 参加費の初期化
      if (event.feeText != null && event.feeText!.isNotEmpty) {
        _feeAmountController.text = event.feeText!;
      } else if (event.feeAmount != null) {
        _feeAmountController.text = event.feeAmount!.toString();
      }
      _feeSupplementController.text = event.feeSupplement ?? '';

      // イベント画像の初期化（編集・コピーモード共に画像URLを設定）
      if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
        _existingImageUrl = event.imageUrl;
      }

      // イベントパスワードの初期化（招待制の場合）
      if (event.eventPassword != null && event.eventPassword!.isNotEmpty) {
        _eventPasswordController.text = event.eventPassword!;
      }

      // フォーム状態の初期値設定
      _hasPrize = event.rewards.isNotEmpty;
      _visibility = event.visibility == 'プライベート' ? 'パブリック' : event.visibility;
      _language = event.language;
      _hasStreaming = event.hasStreaming;
      _hasParticipationFee = event.hasFee;
      _eventTags = List.from(event.eventTags);
      _selectedPlatforms.clear();
      _selectedPlatforms.addAll(event.platforms);

      // 日時の初期値設定
      _eventDate = event.startDate;
      _registrationDeadline = event.registrationDeadline;

      // ゲーム情報の初期化（非同期で読み込み）
      if (event.gameId != null) {
        _loadGameForEditing(event.gameId!);
      }

      // 管理者・スポンサー情報の初期化（非同期で読み込み）
      if (event.managers.isNotEmpty) {
        _loadManagersForEditing(event.managers);
      }
      if (event.sponsors.isNotEmpty) {
        _loadSponsorsForEditing(event.sponsors);
      }

      // 年齢制限の初期化
      if (event.minAge != null) {
        _hasAgeRestriction = true;
        _minAge = event.minAge!;
      }

      // 承認方法の初期化
      _approvalMethod = event.approvalMethod;

      // NGユーザーの初期化
      if (event.blockedUsers.isNotEmpty) {
        _loadBlockedUsersForEditing(event.blockedUsers);
      }

      // 招待ユーザーの初期化
      if (event.invitedUserIds.isNotEmpty) {
        _loadInvitedUsersForEditing(event.invitedUserIds);
      }
    }
  }

  /// ゲーム情報を読み込んで初期化
  Future<void> _loadGameForEditing(String gameId) async {
    try {
      final games = await GameService.instance.getGamesByIds([gameId]);
      if (games.isNotEmpty && mounted) {
        setState(() {
          _selectedGame = games.first;
        });
      }
    } catch (e) {
      // Error loading game data
    }
  }

  /// 管理者情報を読み込んで初期化
  Future<void> _loadManagersForEditing(List<String> managerIds) async {
    try {
      final managers = <UserData>[];
      for (final managerId in managerIds) {
        final userData = await _loadUserData(managerId);
        if (userData != null) {
          managers.add(userData);
        }
      }
      if (mounted) {
        setState(() {
          _selectedManagers = managers;
        });
      }
    } catch (e) {
      // Error loading managers data
    }
  }

  /// スポンサー情報を読み込んで初期化
  Future<void> _loadSponsorsForEditing(List<String> sponsorIds) async {
    try {
      final sponsors = <UserData>[];
      for (final sponsorId in sponsorIds) {
        final userData = await _loadUserData(sponsorId);
        if (userData != null) {
          sponsors.add(userData);
        }
      }
      if (mounted) {
        setState(() {
          _selectedSponsors = sponsors;
        });
      }
    } catch (e) {
      // Error loading sponsors data
    }
  }

  /// ユーザーデータを読み込む
  Future<UserData?> _loadUserData(String userId) async {
    try {
      final userRepository = UserRepository();
      return await userRepository.getUserById(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _maxParticipantsController.dispose();
    _prizeContentController.dispose();
    _contactController.dispose();
    _policyController.dispose();
    _additionalInfoController.dispose();
    _feeAmountController.dispose();
    _feeSupplementController.dispose();
    _eventPasswordController.dispose();
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
                title: widget.editingEvent != null ? 'イベント編集' : AppStrings.createEventTitle,
                showBackButton: true,
                onBackPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.spacingL),
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildScheduleSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildGameSettingsSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildPrizeSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildManagementSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildCategorySection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildInvitationSection(),
                      if (_visibility == '招待制') const SizedBox(height: AppDimensions.spacingXL),
                      _buildExternalSection(),
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildOtherSection(),
                      const SizedBox(height: AppDimensions.spacingXXL),
                      _buildActionButtons(),
                      const SizedBox(height: AppDimensions.spacingL),
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

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    // 複数行入力の場合は新しいウィジェットを使用
    if (maxLines > 1) {
      return AppTextField(
        controller: controller,
        label: label,
        hintText: hint,
        isRequired: isRequired,
        maxLines: maxLines,
        validator: validator ?? (isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$labelは必須項目です';
                }
                return null;
              }
            : null),
      );
    }

    // 数字入力の場合は専用ウィジェットを使用
    if (keyboardType == TextInputType.number ||
        (inputFormatters != null &&
         inputFormatters.any((formatter) =>
             formatter is FilteringTextInputFormatter &&
             formatter.filterPattern.toString().contains('digitsOnly')))) {
      return AppTextField(
        controller: controller,
        label: label,
        hintText: hint,
        isRequired: isRequired,
        validator: validator,
      );
    }

    // 単一行入力の場合は従来通り
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: AppColors.textLight,
              fontSize: AppDimensions.fontSizeM,
            ),
            filled: true,
            fillColor: AppColors.backgroundLight,
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
            contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
          ),
          validator: validator ?? (isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$labelは必須項目です';
                  }
                  return null;
                }
              : null),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        DropdownButtonFormField<String>(
          initialValue: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.backgroundLight,
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
            contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
          ),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
            );
          }).toList(),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return '$labelは必須項目です';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.accent,
          inactiveThumbColor: AppColors.textLight,
          inactiveTrackColor: AppColors.backgroundDark,
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSectionContainer(
      title: AppStrings.basicInfoSection,
      icon: Icons.info,
      children: [
        _buildTextField(
          controller: _eventNameController,
          label: AppStrings.eventNameLabel,
          hint: AppStrings.eventNameHint,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _subtitleController,
          label: AppStrings.subtitleLabel,
          hint: AppStrings.subtitleHint,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _descriptionController,
          label: AppStrings.descriptionLabel,
          hint: AppStrings.descriptionHint,
          maxLines: 4,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _rulesController,
          label: AppStrings.rulesLabel,
          hint: AppStrings.rulesHint,
          maxLines: 6,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildImageSection(),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.imageLabel,
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          width: double.infinity,
          height: _hasImage() ? 200 : 150,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
            image: _getImageDecoration(),
          ),
          child: !_hasImage()
              ? Material(
                  color: AppColors.backgroundTransparent,
                  child: InkWell(
                    onTap: _selectImage,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: AppDimensions.iconXL,
                          color: AppColors.textLight,
                        ),
                        SizedBox(height: AppDimensions.spacingS),
                        Text(
                          AppStrings.addImageButton,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Material(
                  color: AppColors.backgroundTransparent,
                  child: InkWell(
                    onTap: _selectImage,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit,
                              size: AppDimensions.iconL,
                              color: Colors.white,
                            ),
                            SizedBox(height: AppDimensions.spacingS),
                            Text(
                              '画像を変更',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSizeM,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '画像を選択',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingL),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceOption(
                      icon: Icons.camera_alt,
                      label: 'カメラで撮影',
                      onTap: () => Navigator.pop(context, 'camera'),
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: 'ギャラリーから選択',
                      onTap: () => Navigator.pop(context, 'gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildImageSourceOption(
                  icon: Icons.history,
                  label: '過去のイベント画像から選択',
                  onTap: () => Navigator.pop(context, 'past_events'),
                  isWide: true,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );

    if (result != null) {
      if (result == 'past_events') {
        await _selectFromPastEventImages();
      } else {
        final ImageSource source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
            _existingImageUrl = null; // 新しい画像が選択されたら既存URLをクリア
          });
        }
      }
    }
  }

  /// 画像が選択されているかどうかを確認
  bool _hasImage() {
    return _selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
  }

  /// 画像表示用のDecorationImageを取得
  DecorationImage? _getImageDecoration() {
    if (_selectedImage != null) {
      // ローカルファイルを優先
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      // 既存の画像URLを表示
      return DecorationImage(
        image: NetworkImage(_existingImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: isWide
        ? Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingM,
              horizontal: AppDimensions.spacingL,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(color: AppColors.accent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: AppDimensions.iconL,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconXL,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFromPastEventImages() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      // ユーザーが運営した過去のイベントを取得（createdByで直接検索）
      final pastEvents = await EventService.getUserCreatedEvents(currentUser.uid);


      // 画像付きのイベントのみフィルタリング
      final eventsWithImages = pastEvents
          .where((event) => event.imageUrl != null && event.imageUrl!.isNotEmpty)
          .toList();


      if (!mounted) return;

      final selectedImageUrl = await PastEventImagesSelectionDialog.show(
        context,
        pastEvents: eventsWithImages,
        title: '過去のイベント画像から選択',
        emptyMessage: '利用可能な画像がありません',
      );

      if (selectedImageUrl != null) {
        setState(() {
          _existingImageUrl = selectedImageUrl;
          _selectedImage = null; // ローカル画像をクリア
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('過去の画像の読み込みでエラーが発生しました: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildScheduleSection() {
    return _buildSectionContainer(
      title: AppStrings.scheduleSection,
      icon: Icons.schedule,
      children: [
        _buildDateTimeField(
          label: AppStrings.eventDateLabel,
          value: _eventDate,
          onTap: () => _selectDateTime(isEventDate: true),
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildDateTimeField(
          label: AppStrings.registrationDeadlineLabel,
          value: _registrationDeadline,
          onTap: () => _selectDateTime(isEventDate: false),
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Material(
          color: AppColors.backgroundTransparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value != null
                        ? '${value.year}年${value.month}月${value.day}日 ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
                        : '日時を選択してください',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: value != null ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textDark,
                    size: AppDimensions.iconM,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameSettingsSection() {
    return _buildSectionContainer(
      title: AppStrings.gameSettingsSection,
      icon: Icons.videogame_asset,
      children: [
        _buildGameSelectionField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildPlatformSelectionField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _maxParticipantsController,
          label: AppStrings.maxParticipantsLabel,
          hint: '例：100',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _additionalInfoController,
          label: AppStrings.additionalInfoLabel,
          hint: AppStrings.additionalInfoHint,
          maxLines: 3,
        ),
        // TODO: 参加費設定機能はリリース後にアップデートで対応予定
        // const SizedBox(height: AppDimensions.spacingL),
        // _buildSwitchField(
        //   label: AppStrings.participationFeeLabel,
        //   value: _hasParticipationFee,
        //   onChanged: (value) {
        //     setState(() {
        //       _hasParticipationFee = value;
        //     });
        //   },
        // ),
        // if (_hasParticipationFee) ...[
        //   const SizedBox(height: AppDimensions.spacingL),
        //   _buildTextField(
        //     controller: _feeAmountController,
        //     label: AppStrings.feeAmountLabel,
        //     hint: '参加費（例：1000円、\$50、無料など）',
        //     keyboardType: TextInputType.text,
        //   ),
        //   const SizedBox(height: AppDimensions.spacingL),
        //   _buildTextField(
        //     controller: _feeSupplementController,
        //     label: '参加費用補足',
        //     hint: '例：イベント1回目は無料、支払い方法、キャンセルポリシーなど',
        //     maxLines: 3,
        //   ),
        // ],
      ],
    );
  }

  Widget _buildGameSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              AppStrings.gameSelectionLabel,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Material(
          color: AppColors.backgroundTransparent,
          child: InkWell(
            onTap: () {
              GameSelectionDialog.show(
                context,
                selectedGame: _selectedGame,
                title: AppStrings.gameSelectionLabel,
                allowNone: false,
                onGameSelected: (Game? game) {
                  if (game != null) {
                    setState(() {
                      _selectedGame = game;
                    });
                  }
                },
              );
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedGame == null ? 'ゲームを選択してください' : _selectedGame!.name,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeM,
                      color: _selectedGame == null ? AppColors.textLight : AppColors.textDark,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textDark,
                    size: AppDimensions.iconM,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformSelectionField() {
    const platforms = [AppStrings.iosLabel, AppStrings.androidLabel];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: AppStrings.platformLabel,
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingS,
          children: platforms.map((platform) {
            final isSelected = _selectedPlatforms.contains(platform);
            return FilterChip(
              label: Text(platform),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPlatforms.add(platform);
                  } else {
                    _selectedPlatforms.remove(platform);
                  }
                });
              },
              backgroundColor: AppColors.backgroundLight,
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
              checkmarkColor: AppColors.accent,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: AppDimensions.fontSizeS,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrizeSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.accent,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Text(
                AppStrings.prizeSection,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showPrizeInfoDialog,
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingL),
        _buildSwitchField(
          label: AppStrings.hasPrizeLabel,
          value: _hasPrize,
          onChanged: (value) {
            setState(() {
              _hasPrize = value;
            });
          },
        ),
        if (_hasPrize) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    '賞金の受け渡しは主催者と参加者間で直接行ってください。アプリでは受け渡しの仲介や保証は行いません。',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeXS,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_hasPrize) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildTextField(
            controller: _prizeContentController,
            label: AppStrings.prizeContentLabel,
            hint: '例：1位 10万円、2位 5万円、3位 1万円',
            maxLines: 3,
            isRequired: true,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildUserManagementField(
            title: AppStrings.sponsorsLabel,
            users: _selectedSponsors,
            onAddUser: _addSponsor,
            onRemoveUser: _removeSponsor,
            emptyMessage: 'スポンサーを追加してください',
            addButtonText: 'スポンサーを追加',
            addButtonIcon: Icons.business,
          ),
        ],
        ],
      ),
    );
  }

  /// 賞金設定のヘルプダイアログを表示
  void _showPrizeInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.accent),
            const SizedBox(width: AppDimensions.spacingS),
            const Text('賞金設定について'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogBulletPoint('賞金情報は参加者への案内として表示されます'),
            _buildDialogBulletPoint('実際の受け渡しは主催者と参加者間で行ってください'),
            _buildDialogBulletPoint('アプリでは受け渡しの仲介や保証は行いません'),
            _buildDialogBulletPoint('受け渡し方法は事前に参加者と相談してください'),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                '推奨: PayPal、銀行振込、現金手渡しなど、双方が安心できる方法を選択してください。',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeXS,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  /// ダイアログ内のブレットポイントを構築
  Widget _buildDialogBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    return _buildSectionContainer(
      title: AppStrings.managementSection,
      icon: Icons.admin_panel_settings,
      children: [
        _buildManagerField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildUserManagementField(
          title: '参加NGユーザー',
          users: _blockedUsers,
          onAddUser: _addBlockedUser,
          onRemoveUser: _removeBlockedUser,
          emptyMessage: 'ブロックするユーザーを追加してください',
          addButtonText: 'NGユーザーを追加',
          addButtonIcon: Icons.block,
        ),
      ],
    );
  }

  /// 運営者管理フィールド（自分追加ボタン付き）
  Widget _buildManagerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'イベント運営者',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        UserTagsList(
          users: _selectedManagers,
          onUserRemove: _removeManager,
          emptyMessage: 'イベント運営者を追加してください',
          showRemoveButtons: true,
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // ボタンを縦並びで配置
        Column(
          children: [
            // 自分を追加ボタン
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _addSelfAsManager,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        color: AppColors.primary,
                        size: AppDimensions.iconS,
                      ),
                      SizedBox(width: AppDimensions.spacingS),
                      Text(
                        '自分を追加',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),

            // ボタンを横並びで配置
            Row(
              children: [
                // フレンドから追加ボタン
                Expanded(
                  child: GestureDetector(
                    onTap: _addManagerFromFriends,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people,
                            color: AppColors.secondary,
                            size: AppDimensions.iconS,
                          ),
                          SizedBox(width: AppDimensions.spacingS),
                          Text(
                            'フレンドから',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),

                // 他のユーザーを追加ボタン
                Expanded(
                  child: GestureDetector(
                    onTap: _addManager,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(color: AppColors.accent),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.accent,
                            size: AppDimensions.iconS,
                          ),
                          SizedBox(width: AppDimensions.spacingS),
                          Text(
                            'ユーザー検索',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserManagementField({
    required String title,
    required List<UserData> users,
    required VoidCallback onAddUser,
    required Function(UserData) onRemoveUser,
    required String emptyMessage,
    required String addButtonText,
    required IconData addButtonIcon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingS),
        UserTagsList(
          users: users,
          onUserRemove: onRemoveUser,
          emptyMessage: emptyMessage,
          showRemoveButtons: true,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        GestureDetector(
          onTap: onAddUser,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.accent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  addButtonIcon,
                  color: AppColors.accent,
                  size: AppDimensions.iconM,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Text(
                  addButtonText,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addManager() async {
    await UserSearchDialog.show(
      context,
      title: 'イベント運営者を検索',
      description: 'イベントを管理する運営者を追加してください',
      onUserSelected: (user) {
        if (!_selectedManagers.any((manager) => manager.id == user.id)) {
          setState(() {
            _selectedManagers.add(user);
            // Remove from blocked users if present
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
          });
        }
      },
    );
  }

  Future<void> _addManagerFromFriends() async {
    await FriendSelectionDialog.show(
      context,
      title: 'フレンドから運営者を選択',
      description: 'フレンドの中からイベント運営者を追加してください',
      excludedUsers: _selectedManagers,
      onFriendSelected: (user) {
        if (!_selectedManagers.any((manager) => manager.id == user.id)) {
          setState(() {
            _selectedManagers.add(user);
            // Remove from blocked users if present
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
          });
        }
      },
    );
  }

  Future<void> _addSponsor() async {
    await _showSponsorSelectionDialog();
  }

  Future<void> _showSponsorSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スポンサーを追加'),
        content: const Text('どの方法でスポンサーを追加しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSelfAsSponsor();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1, size: 16),
                SizedBox(width: 8),
                Text('自分を追加'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSponsorFromFriends();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, size: 16),
                SizedBox(width: 8),
                Text('フレンドから選択'),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSponsorFromSearch();
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 16),
                SizedBox(width: 8),
                Text('ユーザー検索'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSponsorFromSearch() async {
    await UserSearchDialog.show(
      context,
      title: 'スポンサーを検索',
      description: 'イベントのスポンサーを追加してください',
      onUserSelected: (user) {
        if (!_selectedSponsors.any((sponsor) => sponsor.id == user.id)) {
          setState(() {
            _selectedSponsors.add(user);
            // Automatically add to managers
            if (!_selectedManagers.any((manager) => manager.id == user.id)) {
              _selectedManagers.add(user);
            }
            // Remove from blocked users if present
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
          });
        }
      },
    );
  }

  Future<void> _addSponsorFromFriends() async {
    await FriendSelectionDialog.show(
      context,
      title: 'フレンドからスポンサーを選択',
      description: 'フレンドの中からイベントスポンサーを追加してください',
      excludedUsers: _selectedSponsors,
      onFriendSelected: (user) {
        if (!_selectedSponsors.any((sponsor) => sponsor.id == user.id)) {
          setState(() {
            _selectedSponsors.add(user);
            // Automatically add to managers
            if (!_selectedManagers.any((manager) => manager.id == user.id)) {
              _selectedManagers.add(user);
            }
            // Remove from blocked users if present
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
          });
        }
      },
    );
  }

  Future<void> _addBlockedUser() async {
    await UserSearchDialog.show(
      context,
      title: 'NGユーザーを検索',
      description: 'このイベントをブロックするユーザーを追加してください',
      onUserSelected: (user) {
        // Validate that the user is not a manager or sponsor
        if (_selectedManagers.any((manager) => manager.id == user.id) ||
            _selectedSponsors.any((sponsor) => sponsor.id == user.id)) {
          ErrorHandlerService.showErrorDialog(context, '運営者やスポンサーをNGユーザーに設定することはできません');
          return;
        }

        if (!_blockedUsers.any((blockedUser) => blockedUser.id == user.id)) {
          setState(() {
            _blockedUsers.add(user);
          });
        }
      },
    );
  }

  void _removeManager(UserData user) {
    setState(() {
      _selectedManagers.removeWhere((manager) => manager.id == user.id);
      // Also remove from sponsors if present
      _selectedSponsors.removeWhere((sponsor) => sponsor.id == user.id);
    });
  }

  void _removeSponsor(UserData user) {
    setState(() {
      _selectedSponsors.removeWhere((sponsor) => sponsor.id == user.id);
      // Keep as manager unless manually removed
    });
  }

  void _removeBlockedUser(UserData user) {
    setState(() {
      _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
    });
  }

  /// 自分自身を運営者に追加
  Future<void> _addSelfAsManager() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザーが認証されていません')),
      );
      return;
    }

    try {
      // 複数の方法でユーザー情報を取得してみる
      UserData? selfUserData;

      // 方法1: 現在ログインしているユーザーの情報を直接取得
      try {
        final userRepository = UserRepository();
        selfUserData = await userRepository.getCurrentUser();
      } catch (e) {
        // getCurrentUserが失敗した場合は方法2を試す
      }

      // 方法2: Firebase UIDを使ってFirestoreから直接取得
      if (selfUserData == null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (doc.exists && doc.data() != null) {
            selfUserData = UserData.fromFirestore(doc);
          }
        } catch (e) {
          // Firestoreアクセスも失敗した場合は方法3を試す
        }
      }

      // 方法3: 認証情報から基本的なUserDataを作成
      if (selfUserData == null) {
        // Firebase Auth UIDを使ってユーザー情報を取得できない場合でも、
        // 最低限の情報でUserDataを作成（表示用のuserIdは未設定状態）
        selfUserData = UserData(
          id: currentUser.uid,
          userId: '', // カスタムユーザーIDが未設定の場合は空文字
          username: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'ユーザー',
          email: currentUser.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // null チェック後に使用
      if (selfUserData != null) {
        // 重複チェック
        if (!_selectedManagers.any((manager) => manager.id == selfUserData!.id)) {
          setState(() {
            _selectedManagers.add(selfUserData!);
            // 他のリストから除去
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == selfUserData!.id);
            _selectedSponsors.removeWhere((sponsor) => sponsor.id == selfUserData!.id);
            _invitedUsers.removeWhere((invitedUser) => invitedUser.id == selfUserData!.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selfUserData!.username}を運営者に追加しました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('既に運営者として追加されています')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー情報を取得できませんでした')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
      );
    }
  }

  Future<void> _addSelfAsSponsor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ユーザーが認証されていません')),
      );
      return;
    }

    try {
      // 複数の方法でユーザー情報を取得してみる
      UserData? selfUserData;

      // 方法1: 現在ログインしているユーザーの情報を直接取得
      try {
        final userRepository = UserRepository();
        selfUserData = await userRepository.getCurrentUser();
      } catch (e) {
        // getCurrentUserが失敗した場合は方法2を試す
      }

      // 方法2: getUserByIdを使用
      if (selfUserData == null) {
        try {
          final userRepository = UserRepository();
          selfUserData = await userRepository.getUserById(currentUser.uid);
        } catch (e) {
          // getUserByIdも失敗した場合は方法3を試す
        }
      }

      // 方法3: FirebaseAuthの情報から直接作成
      if (selfUserData == null) {
        selfUserData = UserData.create(
          id: currentUser.uid,
          userId: currentUser.uid,
          username: currentUser.displayName ?? 'ユーザー',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
        );
      }

      if (selfUserData != null) {
        // 重複チェック
        if (!_selectedSponsors.any((sponsor) => sponsor.id == selfUserData!.id)) {
          setState(() {
            _selectedSponsors.add(selfUserData!);
            // スポンサーは自動的に運営者にも追加
            if (!_selectedManagers.any((manager) => manager.id == selfUserData!.id)) {
              _selectedManagers.add(selfUserData!);
            }
            // ブロックリストから除外
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == selfUserData!.id);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('既にスポンサーとして追加されています')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー情報を取得できませんでした')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
      );
    }
  }

  /// 編集用NGユーザーリストの読み込み
  void _loadBlockedUsersForEditing(List<String> blockedUserIds) async {
    final userRepository = UserRepository();
    final List<UserData> blockedUsers = [];

    for (String userId in blockedUserIds) {
      try {
        final user = await userRepository.getUserByCustomId(userId);
        if (user != null) {
          blockedUsers.add(user);
        }
      } catch (e) {
        // ユーザーが見つからない場合は無視
      }
    }

    setState(() {
      _blockedUsers = blockedUsers;
    });
  }

  /// 編集用招待ユーザーリストの読み込み
  void _loadInvitedUsersForEditing(List<String> invitedUserIds) async {
    final List<UserData> invitedUsers = [];

    for (String userId in invitedUserIds) {
      try {
        // invitedUserIdsにはFirebase UIDが保存されているため、getUserByIdを使用
        final user = await _loadUserData(userId);
        if (user != null) {
          invitedUsers.add(user);
        }
      } catch (e) {
        // ユーザーが見つからない場合は無視
      }
    }

    if (mounted) {
      setState(() {
        _invitedUsers = invitedUsers;
      });
    }
  }

  Future<void> _addInvitedUser() async {
    await UserSearchDialog.show(
      context,
      title: '招待メンバーを検索',
      description: 'イベントに招待するメンバーを追加してください',
      onUserSelected: (user) {
        if (!_invitedUsers.any((invitedUser) => invitedUser.id == user.id)) {
          setState(() {
            _invitedUsers.add(user);
            // 運営者、スポンサー、ブロックリストから除外
            _selectedManagers.removeWhere((manager) => manager.id == user.id);
            _selectedSponsors.removeWhere((sponsor) => sponsor.id == user.id);
            _blockedUsers.removeWhere((blockedUser) => blockedUser.id == user.id);
          });
        }
      },
    );
  }

  void _removeInvitedUser(UserData user) {
    setState(() {
      _invitedUsers.removeWhere((invitedUser) => invitedUser.id == user.id);
    });
  }


  Widget _buildCategorySection() {
    return _buildSectionContainer(
      title: AppStrings.categorySection,
      icon: Icons.category,
      children: [
        _buildDropdownField(
          label: AppStrings.visibilityLabel,
          value: _visibility,
          options: ['パブリック', '招待制'],
          onChanged: (value) {
            setState(() {
              final previousVisibility = _visibility;
              _visibility = value!;
              // 招待制からパブリックに変更した場合、招待制の設定をクリア
              if (previousVisibility == '招待制' && _visibility == 'パブリック') {
                _eventPasswordController.clear();
                _invitedUsers.clear();
              }
            });
          },
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        TagInputField(
          label: AppStrings.eventTagsLabel,
          hint: AppStrings.eventTagsHint,
          initialTags: _eventTags,
          maxTags: 10,
          maxTagLength: 20,
          onChanged: (tags) {
            setState(() {
              _eventTags = tags;
            });
          },
          validator: (tags) => ValidationService.validateEventTags(tags),
        ),
        // TODO: 多言語化は見送り - 言語設定セクションを非表示化
        // const SizedBox(height: AppDimensions.spacingL),
        // _buildDropdownField(
        //   label: AppStrings.languageLabel,
        //   value: _language,
        //   options: ['日本語', '英語', 'その他'],
        //   onChanged: (value) {
        //     setState(() {
        //       _language = value!;
        //     });
        //   },
        // ),
      ],
    );
  }

  Widget _buildInvitationSection() {
    if (_visibility != '招待制') {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      title: AppStrings.invitationSection,
      icon: Icons.person_add,
      children: [
        // パスワード入力フィールド
        _buildTextField(
          controller: _eventPasswordController,
          label: AppStrings.eventPasswordLabel,
          hint: AppStrings.eventPasswordHint,
          isRequired: true,
          obscureText: true,
          validator: (value) => ValidationService.validateEventPassword(value, true),
        ),
        const SizedBox(height: AppDimensions.spacingL),

        // 招待メンバー管理（ユーザー検索形式）
        _buildUserManagementField(
          title: AppStrings.inviteMembersLabel,
          users: _invitedUsers,
          onAddUser: _addInvitedUser,
          onRemoveUser: _removeInvitedUser,
          emptyMessage: '招待するメンバーを追加してください',
          addButtonText: '招待メンバーを追加',
          addButtonIcon: Icons.person_add_outlined,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildExternalSection() {
    return _buildSectionContainer(
      title: AppStrings.externalSection,
      icon: Icons.link,
      children: [
        _buildTextField(
          controller: _contactController,
          label: AppStrings.contactLabel,
          hint: 'イベント公式Discord、コミュニティサイト、配信チャンネル等\n例：公式Discord: https://discord.gg/xxxxx\nコミュニティサイト: https://example.com\nYouTube: @channelname',
          maxLines: 4,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildSwitchField(
          label: AppStrings.streamingLabel,
          value: _hasStreaming,
          onChanged: (value) {
            setState(() {
              _hasStreaming = value;
            });
          },
        ),
        if (_hasStreaming) ...[
          const SizedBox(height: AppDimensions.spacingL),
          StreamingUrlInputField(
            label: AppStrings.streamingUrlLabel,
            hint: AppStrings.streamingUrlHint,
            initialUrls: _streamingUrls,
            maxUrls: 5,
            onChanged: (urls) {
              setState(() {
                _streamingUrls = urls;
              });
            },
            validator: (urls) {
              if (_hasStreaming && urls.isEmpty) {
                return '最低1つの配信URLを入力してください';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOtherSection() {
    return _buildSectionContainer(
      title: AppStrings.otherSection,
      icon: Icons.more_horiz,
      children: [
        _buildTextField(
          controller: _policyController,
          label: AppStrings.policyLabel,
          hint: '例：イベント開始24時間前まではキャンセル可能',
          maxLines: 4,
        ),
      ],
    );
  }


  Widget _buildTagField({
    required String label,
    required List<String> tags,
    required ValueChanged<List<String>> onTagsChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tags.isNotEmpty)
                Wrap(
                  spacing: AppDimensions.spacingS,
                  runSpacing: AppDimensions.spacingS,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.spacingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: AppColors.info),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingXS),
                          GestureDetector(
                            onTap: () {
                              final newTags = List<String>.from(tags);
                              newTags.remove(tag);
                              onTagsChanged(newTags);
                            },
                            child: const Icon(
                              Icons.close,
                              size: AppDimensions.fontSizeS,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppDimensions.spacingS),
              GestureDetector(
                onTap: () {
                  // TODO: タグ追加機能を実装
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: AppColors.textDark,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      'タグを追加',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Create Event Button
        AppButton.primary(
          text: _isCreatingEvent
              ? 'イベントを作成中...'
              : _getCreateButtonText(),
          isFullWidth: true,
          isEnabled: !_isCreatingEvent && !_isSavingDraft,
          onPressed: _isCreatingEvent || _isSavingDraft
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    _createEvent();
                  }
                },
        ),
        const SizedBox(height: AppDimensions.spacingM),

        // Save Draft Button
        AppButton.white(
          text: _isSavingDraft ? '下書きを保存中...' : AppStrings.saveDraftButton,
          isFullWidth: true,
          isEnabled: !_isCreatingEvent && !_isSavingDraft,
          onPressed: _isCreatingEvent || _isSavingDraft ? null : _saveDraft,
        ),
      ],
    );
  }


  void _selectDateTime({required bool isEventDate}) async {
    // 日付選択時の制限を設定
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime.now();
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    if (!isEventDate) {
      // 申込期限の場合は開催日時より前でなければならない
      if (_eventDate != null) {
        // 開催日時が設定されている場合、申込期限は開催日時の前日まで
        lastDate = _eventDate!.subtract(const Duration(days: 1));

        // lastDateが現在時刻より前の場合は、現在時刻から開催日時の前日までに調整
        if (lastDate.isBefore(DateTime.now())) {
          // 開催日時が明日以前の場合はエラー
          if (_eventDate!.isBefore(DateTime.now().add(const Duration(days: 1)))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('開催日時を明日以降に設定してから申込期限を設定してください'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }
        }

        // 初期日付は現在時刻と開催日時の前日の間で適切に設定
        if (DateTime.now().isBefore(lastDate)) {
          initialDate = DateTime.now();
        } else {
          initialDate = lastDate;
        }
      } else {
        // 開催日時が未設定の場合はエラー
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('まず開催日時を設定してください'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // TODO: 多言語化は見送り、日本語固定で実装
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) {
      // 日付選択がキャンセルされた場合もフォーカスを解除
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      return;
    }

    if (mounted) {
      // 時刻の初期値を設定
      TimeOfDay initialTime = TimeOfDay.now();

      // 申込期限で同日の場合は、開催時刻より前の時刻に制限
      if (!isEventDate && _eventDate != null &&
          date.year == _eventDate!.year &&
          date.month == _eventDate!.month &&
          date.day == _eventDate!.day) {

        // 同日の場合は開催時刻の1時間前を初期値に設定
        final eventTimeOfDay = TimeOfDay.fromDateTime(_eventDate!);
        final eventMinutes = eventTimeOfDay.hour * 60 + eventTimeOfDay.minute;
        final oneHourBeforeMinutes = eventMinutes - 60;

        if (oneHourBeforeMinutes > 0) {
          initialTime = TimeOfDay(
            hour: oneHourBeforeMinutes ~/ 60,
            minute: oneHourBeforeMinutes % 60,
          );
        } else {
          // 開催時刻が早い場合は前日を推奨
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('申込期限は開催時刻の少なくとも1時間前に設定してください'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }

      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.accent,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time == null) {
        // 時刻選択がキャンセルされた場合もフォーカスを解除
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
        return;
      }

      if (mounted) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // 申込期限の妥当性を最終チェック
        if (!isEventDate && _eventDate != null) {
          if (selectedDateTime.isAfter(_eventDate!) || selectedDateTime.isAtSameMomentAs(_eventDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('申込期限は開催日時より前に設定してください'),
                backgroundColor: AppColors.error,
              ),
            );
            FocusScope.of(context).unfocus();
            return;
          }
        }

        setState(() {
          if (isEventDate) {
            _eventDate = selectedDateTime;
            // 開催日時が変更された場合、申込期限をリセット
            if (_registrationDeadline != null &&
                (_registrationDeadline!.isAfter(selectedDateTime) ||
                 _registrationDeadline!.isAtSameMomentAs(selectedDateTime))) {
              _registrationDeadline = null;
            }
          } else {
            _registrationDeadline = selectedDateTime;
          }
        });

        // ダイアログ終了後にフォーカスを解除して、意図しないテキストフィールドへのフォーカス移動を防ぐ
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _createEvent() async {
    await _saveEventWithStatus(EventStatus.published);
  }

  void _saveDraft() async {
    // 編集モードで既存参加者がいるかチェック
    if (widget.editingEvent != null && widget.editingEvent!.id.isNotEmpty) {
      final canConvert = await _checkParticipantsBeforeDraft();
      if (!canConvert) {
        return; // ユーザーがキャンセルした、または制限により不可
      }

      // 参加者がいる場合の通知送信処理
      await _sendDraftConversionNotifications();
    }

    await _saveEventWithStatus(EventStatus.draft);
  }

  /// 下書き保存前に参加者数をチェック
  Future<bool> _checkParticipantsBeforeDraft() async {
    try {
      final participantCount = await ParticipationService.getApprovedParticipantCount(
        widget.editingEvent!.id,
      );

      if (participantCount == 0) {
        // 参加者がいない場合は制限なし
        return true;
      } else if (participantCount <= 5) {
        // 少数の参加者がいる場合は警告ダイアログを表示
        return await _showParticipantWarningDialog(participantCount);
      } else if (participantCount <= 20) {
        // 中程度の参加者がいる場合は理由入力必須の警告
        return await _showManyParticipantsWarningDialog(
          participantCount,
          action: '下書きに変更'
        );
      } else {
        // 多数の参加者がいる場合は制限
        _showTooManyParticipantsForDraftError(participantCount);
        return false;
      }
    } catch (e) {
      // エラー時は安全のため制限
      ErrorHandlerService.showErrorDialog(
        context,
        '参加者数の確認に失敗しました。\n安全のため下書きに戻すことができません。',
      );
      return false;
    }
  }

  /// 少数参加者がいる場合の警告ダイアログ
  Future<bool> _showParticipantWarningDialog(int participantCount) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              const Text(
                '参加者への影響について',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.people,
                      color: Colors.orange,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Text(
                        '現在$participantCount名が参加申込済みです',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                '下書きに戻すと、参加者は以下の影響を受けます：',
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              _buildImpactItem('イベントが非公開になり、参加者がアクセスできなくなります'),
              _buildImpactItem('参加者に通知が送信されます'),
              _buildImpactItem('参加申込は保持されますが、一時的に無効となります'),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '下書きから再公開した際、参加申込は自動的に復活します。',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeS,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'キャンセル',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                '下書きに戻す',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// 影響項目の表示ウィジェット
  Widget _buildImpactItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right,
            size: AppDimensions.iconS,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 多数参加者がいる場合のエラーダイアログ
  void _showTooManyParticipantsError(int participantCount) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block,
                color: AppColors.error,
                size: AppDimensions.iconL,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              const Text(
                '下書きに戻すことができません',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: AppColors.error,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Text(
                        '現在$participantCount名が参加申込済みです',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              const Text(
                '多数の参加者がいるイベントを下書きに戻すことはできません。',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '代替案：',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    _buildAlternativeItem('イベント情報を編集して保存'),
                    _buildAlternativeItem('イベントをキャンセル（中止）にする'),
                    _buildAlternativeItem('新規募集を停止したい場合は、定員を現在の参加者数に設定'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                '了解',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 代替案項目の表示ウィジェット
  Widget _buildAlternativeItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// イベント下書き化時の参加者への通知送信
  Future<void> _sendDraftConversionNotifications() async {
    try {
      if (widget.editingEvent == null) return;

      final eventId = widget.editingEvent!.id;
      final eventName = _eventNameController.text.trim();

      // 現在のユーザー名を取得（主催者名として使用）
      final currentUser = FirebaseAuth.instance.currentUser;
      final organizerName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? '主催者';

      // 承認済み参加者のリストを取得
      final approvedParticipants = await ParticipationService.getApprovedParticipants(eventId);

      // 通知サービスのインスタンスを取得
      final notificationService = NotificationService.instance;

      // 各参加者に通知を送信
      for (final participantId in approvedParticipants) {
        await notificationService.sendEventDraftRevertedNotification(
          toUserId: participantId,
          eventId: eventId,
          eventName: eventName,
          organizerName: organizerName,
        );
      }

      print('Draft conversion notifications sent to ${approvedParticipants.length} participants');
    } catch (e) {
      print('Error sending draft conversion notifications: $e');
      // 通知の失敗は下書き保存を阻害しないようにエラーを無視
    }
  }

  /// イベントをFirebaseに保存する共通メソッド
  Future<void> _saveEventWithStatus(EventStatus status) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ErrorHandlerService.showErrorDialog(context, 'ユーザーが認証されていません。ログインしてください。');
      return;
    }

    // イベント作成時は完全なバリデーション、下書き保存時は緩いバリデーション
    if (status == EventStatus.published) {
      final validationErrors = _validateForPublish();
      if (validationErrors.isNotEmpty) {
        _showValidationErrorDialog(validationErrors);
        return;
      }
    } else {
      // 下書き保存時は基本的な形式チェックのみ
      if (!_validateForDraft()) {
        return;
      }
    }

    setState(() {
      if (status == EventStatus.published) {
        _isCreatingEvent = true;
      } else {
        _isSavingDraft = true;
      }
      _uploadProgress = 0.0;
    });

    try {
      final eventInput = await _createEventInputFromForm(overrideStatus: status);
      String eventId;

      final isEditMode = widget.editingEvent != null && widget.editingEvent!.id.isNotEmpty;
      final isCopyMode = widget.editingEvent != null && widget.editingEvent!.id.isEmpty;

      if (isEditMode) {
        // 編集モード: 既存のイベントを更新
        eventId = widget.editingEvent!.id;
        await EventService.updateEvent(
          eventId: eventId,
          eventInput: eventInput,
          newImageFile: _selectedImage,
          currentImagePath: widget.editingEvent!.imageUrl,
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        // ステータスを更新
        await EventService.updateEventStatus(eventId, status);
      } else {
        // 新規作成モード（通常の新規作成 or コピーモード）
        File? imageFileToUse = _selectedImage;

        // コピーモードで新規画像が選択されていない場合、前回の画像URLをEventServiceに渡す
        String? existingImageUrlToUse;
        if (isCopyMode && imageFileToUse == null && _existingImageUrl != null) {
          existingImageUrlToUse = _existingImageUrl;
        }

        final result = await EventService.createEvent(
          eventInput: eventInput,
          createdBy: currentUser.uid,
          imageFile: imageFileToUse,
          existingImageUrl: existingImageUrlToUse,
          onUploadProgress: (progress) {
            setState(() {
              _uploadProgress = progress;
            });
          },
        );
        eventId = result.eventId;

        // ステータスを更新
        await EventService.updateEventStatus(eventId, status);

        // 招待制イベントの場合、招待通知を送信（新規作成時のみ）
        if (_visibility == '招待制' && _invitedUsers.isNotEmpty && status == EventStatus.published) {
          try {
            await EventService.sendEventInvitations(
              eventId: eventId,
              eventName: _eventNameController.text.trim(),
              invitedUserIds: _invitedUsers.map((user) => user.id).toList(),
              createdByUserId: currentUser.uid,
            );
          } catch (invitationError) {
            // 招待送信エラーは非致命的なので無視
          }
        }
      }

      // 成功時の遷移処理
      if (mounted) {
        if (status == EventStatus.published) {
          // イベント公開時は成功ダイアログを表示して詳細画面に遷移
          if (widget.editingEvent != null) {
            // 編集モードの場合
            ErrorHandlerService.showSuccessSnackBar(context, 'イベントを更新しました');
            Navigator.of(context).pop(eventId);
          } else {
            // 新規作成モードの場合
            await _showEventCreatedDialog(eventId);
          }
        } else {
          // 下書き保存時は成功メッセージを表示して前の画面に戻る
          final message = widget.editingEvent != null ? '変更を保存しました' : '下書きを保存しました';
          ErrorHandlerService.showSuccessSnackBar(context, message);
          Navigator.of(context).pop(eventId);
        }
      }
    } catch (e) {
      String errorMessage = 'エラーが発生しました';

      if (e is EventServiceException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'イベントの保存に失敗しました。もう一度お試しください。';
      }

      ErrorHandlerService.showErrorDialog(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingEvent = false;
          _isSavingDraft = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// フォームデータからEventInputオブジェクトを作成
  Future<EventInput> _createEventInputFromForm({EventStatus? overrideStatus}) async {
    // 選択されたゲームをshared_gamesコレクションに保存または使用回数増加
    String? gameId;
    if (_selectedGame != null) {
      gameId = await GameService.instance.getOrCacheGame(_selectedGame!);
    }

    return EventInput(
      name: _eventNameController.text.trim(),
      subtitle: _subtitleController.text.trim().isEmpty
          ? null
          : _subtitleController.text.trim(),
      description: _descriptionController.text.trim(),
      rules: _rulesController.text.trim(),
      gameId: gameId,
      platforms: List<String>.from(_selectedPlatforms),
      eventDate: _eventDate!,
      registrationDeadline: _registrationDeadline!,
      maxParticipants: int.parse(_maxParticipantsController.text.trim()),
      additionalInfo: _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim(),
      hasParticipationFee: _hasParticipationFee,
      participationFeeText: _hasParticipationFee && _feeAmountController.text.isNotEmpty
          ? _feeAmountController.text.trim()
          : null,
      participationFeeSupplement: _hasParticipationFee && _feeSupplementController.text.isNotEmpty
          ? _feeSupplementController.text.trim()
          : null,
      hasPrize: _hasPrize,
      prizeContent: _hasPrize && _prizeContentController.text.isNotEmpty
          ? _prizeContentController.text.trim()
          : null,
      sponsorIds: _selectedSponsors.map((sponsor) => sponsor.id).toList(),
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      blockedUserIds: _blockedUsers.map((user) => user.id).toList(),
      // パブリックの場合は招待ユーザーIDをクリア
      invitedUserIds: _visibility == '招待制'
          ? _invitedUsers.map((user) => user.id).toList()
          : [],
      visibility: overrideStatus == EventStatus.draft
          ? EventVisibility.private
          : _convertVisibilityToEnum(_visibility),
      eventTags: List<String>.from(_eventTags),
      language: _language,
      contactInfo: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      hasStreaming: _hasStreaming,
      streamingUrls: _hasStreaming ? _streamingUrls : [],
      policy: _policyController.text.trim().isEmpty
          ? null
          : _policyController.text.trim(),
      eventPassword: _visibility == '招待制' && _eventPasswordController.text.isNotEmpty
          ? _eventPasswordController.text.trim()
          : null,
      status: overrideStatus ?? EventStatus.published,
    );
  }

  /// 作成ボタンのテキストを取得
  String _getCreateButtonText() {
    final isEditing = widget.editingEvent != null;
    return isEditing ? 'イベントを更新・公開する' : 'イベントを公開する';
  }

  /// 文字列の可視性をEnumに変換
  EventVisibility _convertVisibilityToEnum(String visibility) {
    switch (visibility) {
      case '招待制':
        return EventVisibility.inviteOnly;
      default:
        return EventVisibility.public;
    }
  }

  /// イベント公開時の完全なバリデーション（※アスタリスク付き必須項目のみ）
  List<String> _validateForPublish() {
    final errors = <String>[];

    // ※基本情報セクションの必須項目
    if (_eventNameController.text.trim().isEmpty) {
      errors.add('イベント名を入力してください');
    }

    if (_descriptionController.text.trim().isEmpty) {
      errors.add('イベント内容を入力してください');
    }

    if (_rulesController.text.trim().isEmpty) {
      errors.add('参加ルールを入力してください');
    }

    // ※ゲーム情報セクションの必須項目
    if (_selectedGame == null) {
      errors.add('ゲームを選択してください');
    }

    if (_selectedPlatforms.isEmpty) {
      errors.add('プラットフォームを選択してください');
    }

    // ※開催設定セクションの必須項目
    if (_eventDate == null) {
      errors.add('開催日時を設定してください');
    } else if (_eventDate!.isBefore(DateTime.now())) {
      errors.add('開催日時は現在時刻より後に設定してください');
    }

    if (_registrationDeadline == null) {
      errors.add('参加申込締切を設定してください');
    } else if (_eventDate != null &&
               (_registrationDeadline!.isAfter(_eventDate!) || _registrationDeadline!.isAtSameMomentAs(_eventDate!))) {
      errors.add('参加申込締切は開催日時より前に設定してください');
    }

    if (_maxParticipantsController.text.trim().isEmpty) {
      errors.add('最大参加人数を入力してください');
    } else {
      final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());
      if (maxParticipants == null || maxParticipants <= 0) {
        errors.add('最大参加人数は正の整数で入力してください');
      }
    }

    if (_visibility == '招待制') {
      // 招待制イベント時の条件付き必須項目
      if (_invitedUsers.isEmpty) {
        errors.add('招待メンバーを追加してください');
      }
    }

    // ※賞品設定時の条件付き必須項目
    if (_hasPrize) {
      if (_prizeContentController.text.trim().isEmpty) {
        errors.add('賞品内容を入力してください');
      }

      if (_selectedManagers.isEmpty) {
        errors.add('賞品設定時は運営者を追加してください');
      }
    }

    // その他の条件付き必須項目のチェック
    if (_hasParticipationFee && _feeAmountController.text.trim().isEmpty) {
      errors.add('参加費用の詳細を入力してください');
    }

    if (_hasStreaming && _streamingUrls.isEmpty) {
      errors.add('配信URLを入力してください');
    }


    return errors;
  }

  /// 下書き保存時の緩いバリデーション（形式チェックのみ）
  bool _validateForDraft() {
    // 基本的なフォームバリデーション（形式チェック）のみ
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    // 最大参加人数が入力されている場合の形式チェック
    if (_maxParticipantsController.text.trim().isNotEmpty) {
      final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());
      if (maxParticipants == null || maxParticipants <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最大参加人数は正の整数で入力してください'),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }
    }

    // 日時が設定されている場合の妥当性チェック
    if (_eventDate != null && _registrationDeadline != null) {
      if (_registrationDeadline!.isAfter(_eventDate!) || _registrationDeadline!.isAtSameMomentAs(_eventDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('参加申込締切は開催日時より前に設定してください'),
            backgroundColor: AppColors.error,
          ),
        );
        return false;
      }
    }

    return true;
  }

  /// イベント作成成功ダイアログを表示
  Future<void> _showEventCreatedDialog(String eventId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppDimensions.iconL,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'イベントを公開しました！',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      _eventNameController.text,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSizeM,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: AppDimensions.iconM,
                    ),
                    SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        'イベント詳細画面で参加者の管理や\nイベント情報の確認ができます',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // イベント作成画面を閉じる
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textDark,
                textStyle: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('後で確認'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed(
                  '/event_detail',
                  arguments: eventId,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('詳細を見る'),
            ),
          ],
        );
      },
    );
  }

  /// バリデーションエラーダイアログを表示
  void _showValidationErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: AppDimensions.iconM,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              const Text(
                '入力内容を確認してください',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '以下の必須項目（※）を入力してください：',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),
                ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSizeM,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('確認'),
            ),
          ],
        );
      },
    );
  }

  /// フォームの基本検証（レガシー）
  bool _validateForm() {
    return ValidationService.validateForm(
      _formKey,
      additionalValidations: [
        () => ValidationService.validateDateTime(_eventDate, 'イベント日時', minDate: DateTime.now()),
        () => ValidationService.validateDateTime(_registrationDeadline, '参加申込締切', maxDate: _eventDate),
        () => ValidationService.validateList(_selectedPlatforms, 'プラットフォーム'),
        () => ValidationService.validateEventTags(_eventTags),
        () => ValidationService.validateParticipationFeeText(_feeAmountController.text, _hasParticipationFee),
        () => ValidationService.validateTextLength(_prizeContentController.text, 500, '賞品内容', isRequired: _hasPrize),
        () => _hasStreaming && _streamingUrls.isEmpty ? '配信URLを入力してください' : null,
        () => ValidationService.validateImageFile(_selectedImage, false),
      ],
    );
  }


  /// 中程度の参加者がいる場合の警告ダイアログ（6-20人）
  Future<bool> _showManyParticipantsWarningDialog(
    int participantCount, {
    String action = '下書きに変更'
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '注意が必要です',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.warning,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '現在${participantCount}名の参加者がいるため、変更には慎重な検討が必要です。',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            const Text(
              '変更理由を記入してください：',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '例：スケジュール変更により内容を更新しました',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(AppDimensions.spacingM),
              ),
              onChanged: (value) {
                // 理由を保存（実装時に追加）
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
            child: Text('${action}する'),
          ),
        ],
      ),
    );
    return result ?? false;
  }


  /// 下書き変更時のエラーダイアログ（21人以上）
  void _showTooManyParticipantsForDraftError(int participantCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'イベントの下書き化はできません',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          '参加者が${participantCount}人いるため、イベントを下書きに戻すことはできません。'
          '\n\n申し込み締切後の大幅な変更は参加者の混乱を招く可能性があります。',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
            child: const Text(
              '了解',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


}