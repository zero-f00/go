import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_strings.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/models/game.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/widgets/user_search_dialog.dart';
import '../../../shared/widgets/tag_input_field.dart';
import '../../../shared/widgets/user_tag.dart';
import '../../../shared/widgets/game_selection_dialog.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/event_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/error_handler_service.dart';
import '../../../shared/services/validation_service.dart';
import '../../game_event_management/models/game_event.dart';

class EventCreationScreen extends StatefulWidget {
  final GameEvent? editingEvent; // 編集する既存イベント

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
  final _streamingUrlController = TextEditingController();
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
  List<UserData> _selectedManagers = [];
  List<UserData> _selectedSponsors = [];
  List<UserData> _blockedUsers = [];
  List<UserData> _invitedUsers = [];

  DateTime? _eventDate;
  DateTime? _registrationDeadline;
  File? _selectedImage;

  // 公開設定
  EventStatus _publicationStatus = EventStatus.published;
  DateTime? _scheduledPublishDate;

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

  /// 編集モード時にフォームを初期化
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
      _streamingUrlController.text = event.streamingUrl ?? '';
      if (event.feeAmount != null) {
        _feeAmountController.text = event.feeAmount!.toString();
      }
      _feeSupplementController.text = event.feeSupplement ?? '';

      // フォーム状態の初期値設定
      _hasPrize = event.rewards.isNotEmpty;
      _visibility = event.visibility;
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

      // 公開設定の初期化
      _publicationStatus = event.eventStatus;
      _scheduledPublishDate = event.scheduledPublishAt;

      // 承認方法の初期化
      _approvalMethod = event.approvalMethod;
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
      print('ゲーム読み込みエラー: $e');
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
      print('管理者読み込みエラー: $e');
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
      print('スポンサー読み込みエラー: $e');
    }
  }

  /// ユーザーデータを読み込む
  Future<UserData?> _loadUserData(String userId) async {
    try {
      final userRepository = UserRepository();
      return await userRepository.getUserById(userId);
    } catch (e) {
      print('ユーザーデータ読み込みエラー: $e');
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
    _streamingUrlController.dispose();
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
                      const SizedBox(height: AppDimensions.spacingXL),
                      _buildPublicationSection(),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
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
          height: _selectedImage != null ? 200 : 150,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: AppColors.border,
              style: BorderStyle.solid,
            ),
            image: _selectedImage != null
                ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _selectedImage == null
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
                            color: AppColors.textSecondary,
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
    final result = await showModalBottomSheet<ImageSource>(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'カメラで撮影',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'ギャラリーから選択',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingL),
          ],
        ),
      ),
    );

    if (result != null) {
      final XFile? image = await _imagePicker.pickImage(
        source: result,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    }
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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

  Widget _buildScheduleSection() {
    return _buildSectionContainer(
      title: AppStrings.scheduleSection,
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
                    color: AppColors.textSecondary,
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
        const SizedBox(height: AppDimensions.spacingL),
        _buildSwitchField(
          label: AppStrings.participationFeeLabel,
          value: _hasParticipationFee,
          onChanged: (value) {
            setState(() {
              _hasParticipationFee = value;
            });
          },
        ),
        if (_hasParticipationFee) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildTextField(
            controller: _feeAmountController,
            label: AppStrings.feeAmountLabel,
            hint: '参加費（例：1000円、\$50、無料など）',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildTextField(
            controller: _feeSupplementController,
            label: '参加費用補足',
            hint: '例：イベント1回目は無料、支払い方法、キャンセルポリシーなど',
            maxLines: 3,
          ),
        ],
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
                    color: AppColors.textSecondary,
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
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
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
    return _buildSectionContainer(
      title: AppStrings.prizeSection,
      children: [
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
            emptyMessage: '協賛者を追加してください',
            addButtonText: '協賛者を追加',
            addButtonIcon: Icons.business,
          ),
        ],
      ],
    );
  }

  Widget _buildManagementSection() {
    return _buildSectionContainer(
      title: AppStrings.managementSection,
      children: [
        _buildUserManagementField(
          title: 'イベント運営者',
          users: _selectedManagers,
          onAddUser: _addManager,
          onRemoveUser: _removeManager,
          emptyMessage: 'イベント運営者を追加してください',
          addButtonText: '運営者を追加',
          addButtonIcon: Icons.person_add,
          isRequired: true,
        ),
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

  Future<void> _addSponsor() async {
    await UserSearchDialog.show(
      context,
      title: '協賛者を検索',
      description: 'イベントの協賛者を追加してください',
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

  Future<void> _addBlockedUser() async {
    await UserSearchDialog.show(
      context,
      title: 'NGユーザーを検索',
      description: 'このイベントをブロックするユーザーを追加してください',
      onUserSelected: (user) {
        // Validate that the user is not a manager or sponsor
        if (_selectedManagers.any((manager) => manager.id == user.id) ||
            _selectedSponsors.any((sponsor) => sponsor.id == user.id)) {
          ErrorHandlerService.showErrorDialog(context, '運営者や協賛者をNGユーザーに設定することはできません');
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

  Future<void> _addInvitedUser() async {
    await UserSearchDialog.show(
      context,
      title: '招待メンバーを検索',
      description: 'イベントに招待するメンバーを追加してください',
      onUserSelected: (user) {
        if (!_invitedUsers.any((invitedUser) => invitedUser.id == user.id)) {
          setState(() {
            _invitedUsers.add(user);
            // 運営者、協賛者、ブロックリストから除外
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
      children: [
        _buildDropdownField(
          label: AppStrings.visibilityLabel,
          value: _visibility,
          options: ['パブリック', 'プライベート', '招待制'],
          onChanged: (value) {
            setState(() {
              _visibility = value!;
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
        const SizedBox(height: AppDimensions.spacingL),
        _buildDropdownField(
          label: AppStrings.languageLabel,
          value: _language,
          options: ['日本語', '英語', 'その他'],
          onChanged: (value) {
            setState(() {
              _language = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInvitationSection() {
    if (_visibility != '招待制') {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      title: AppStrings.invitationSection,
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
      children: [
        _buildTextField(
          controller: _contactController,
          label: AppStrings.contactLabel,
          hint: '例：Discord: @username, Twitter: @username',
          maxLines: 3,
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
          _buildTextField(
            controller: _streamingUrlController,
            label: AppStrings.streamingUrlLabel,
            hint: AppStrings.streamingUrlHint,
            keyboardType: TextInputType.url,
          ),
        ],
      ],
    );
  }

  Widget _buildOtherSection() {
    return _buildSectionContainer(
      title: AppStrings.otherSection,
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

  Widget _buildPublicationSection() {
    return _buildSectionContainer(
      title: '公開設定',
      children: [
        // 公開方式選択
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '公開方式',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            // 即座に公開
            RadioListTile<EventStatus>(
              value: EventStatus.published,
              groupValue: _publicationStatus,
              onChanged: (value) {
                setState(() {
                  _publicationStatus = value!;
                  _scheduledPublishDate = null;
                });
              },
              title: const Text('即座に公開'),
              subtitle: const Text('イベント作成と同時に公開されます'),
              contentPadding: EdgeInsets.zero,
            ),
            // 予約公開
            RadioListTile<EventStatus>(
              value: EventStatus.scheduled,
              groupValue: _publicationStatus,
              onChanged: (value) {
                setState(() {
                  _publicationStatus = value!;
                });
              },
              title: const Text('予約公開'),
              subtitle: const Text('指定した日時に自動で公開されます'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),

        // 予約公開日時選択
        if (_publicationStatus == EventStatus.scheduled) ...[
          const SizedBox(height: AppDimensions.spacingL),
          _buildDateTimeField(
            label: '公開日時',
            value: _scheduledPublishDate,
            onTap: () => _selectPublishDateTime(),
            isRequired: true,
          ),
        ],
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
                      color: AppColors.textSecondary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      'タグを追加',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeS,
                        color: AppColors.textSecondary,
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
        // Upload Progress Indicator
        if (_isCreatingEvent || _isSavingDraft) ...[
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(
                      child: Text(
                        _isCreatingEvent ? 'イベントを作成中...' : '下書きを保存中...',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_selectedImage != null && _uploadProgress > 0) ...[
                  const SizedBox(height: AppDimensions.spacingS),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    '画像アップロード: ${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingL),
        ],

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

  void _selectPublishDateTime() async {
    final now = DateTime.now();
    final initialDate = _scheduledPublishDate ?? now.add(const Duration(hours: 1));
    final firstDate = now;
    final lastDate = _eventDate ?? now.add(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return;

    final selectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _scheduledPublishDate = selectedDateTime;
    });
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

    if (date != null && mounted) {
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

      if (time != null && mounted) {
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
      }
    }
  }

  void _createEvent() async {
    await _saveEventWithStatus(_publicationStatus);
  }

  void _saveDraft() async {
    await _saveEventWithStatus(EventStatus.draft);
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
      final eventInput = await _createEventInputFromForm();

      final result = await EventService.createEvent(
        eventInput: eventInput,
        createdBy: currentUser.uid,
        imageFile: _selectedImage,
        onUploadProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      // ステータスを更新（下書き以外の場合）
      if (status != EventStatus.draft) {
        await EventService.updateEventStatus(result.eventId, status);

        // 招待制イベントの場合、招待通知を送信
        if (_visibility == '招待制' && _invitedUsers.isNotEmpty && status == EventStatus.published) {
          try {
            await EventService.sendEventInvitations(
              eventId: result.eventId,
              eventName: _eventNameController.text.trim(),
              invitedUserIds: _invitedUsers.map((user) => user.id).toList(),
              createdByUserId: currentUser.uid,
            );
          } catch (invitationError) {
            print('招待送信エラー: $invitationError');
            // 招待送信エラーは非致命的なのでログのみ
          }
        }
      }

      // 成功時の遷移処理
      if (mounted) {
        if (status == EventStatus.published) {
          // イベント公開時は成功ダイアログを表示して詳細画面に遷移
          await _showEventCreatedDialog(result.eventId);
        } else {
          // 下書き保存時は成功メッセージを表示して前の画面に戻る
          ErrorHandlerService.showSuccessSnackBar(context, '下書きを保存しました');
          Navigator.of(context).pop(result.eventId);
        }
      }
    } catch (e) {
      print('Event creation error: $e');

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
  Future<EventInput> _createEventInputFromForm() async {
    // 選択されたゲームをshared_gamesコレクションに保存または使用回数増加
    String? gameId;
    if (_selectedGame != null) {
      print('🎮 EventCreationScreen: Caching selected game: ${_selectedGame!.name}');
      gameId = await GameService.instance.getOrCacheGame(_selectedGame!);
      print('🎮 EventCreationScreen: Game cached with ID: $gameId');
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
      visibility: _convertVisibilityToEnum(_visibility),
      eventTags: List<String>.from(_eventTags),
      language: _language,
      contactInfo: _contactController.text.trim().isEmpty
          ? null
          : _contactController.text.trim(),
      hasStreaming: _hasStreaming,
      streamingUrl: _hasStreaming && _streamingUrlController.text.isNotEmpty
          ? _streamingUrlController.text.trim()
          : null,
      policy: _policyController.text.trim().isEmpty
          ? null
          : _policyController.text.trim(),
      eventPassword: _visibility == '招待制' && _eventPasswordController.text.isNotEmpty
          ? _eventPasswordController.text.trim()
          : null,
      status: _publicationStatus,
      scheduledPublishAt: _publicationStatus == EventStatus.scheduled
          ? _scheduledPublishDate
          : null,
    );
  }

  /// 公開設定に応じた作成ボタンのテキストを取得
  String _getCreateButtonText() {
    switch (_publicationStatus) {
      case EventStatus.published:
        return 'イベントを公開する';
      case EventStatus.scheduled:
        return 'イベントを予約公開する';
      default:
        return AppStrings.createEventButton;
    }
  }

  /// 文字列の可視性をEnumに変換
  EventVisibility _convertVisibilityToEnum(String visibility) {
    switch (visibility) {
      case 'プライベート':
        return EventVisibility.private;
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

    // ※公開設定セクションの必須項目
    if (_visibility == 'パブリック') {
      // パブリックイベントでは追加バリデーションなし（デフォルト値があるため）
    } else if (_visibility == 'プライベート') {
      // プライベートイベント時の条件付き必須項目
      if (_eventPasswordController.text.trim().isEmpty) {
        errors.add('イベントパスワードを設定してください');
      }
    } else if (_visibility == '招待制') {
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

    if (_hasStreaming && _streamingUrlController.text.trim().isEmpty) {
      errors.add('配信URLを入力してください');
    }

    // 公開設定のバリデーション
    if (_publicationStatus == EventStatus.scheduled) {
      if (_scheduledPublishDate == null) {
        errors.add('予約公開日時を設定してください');
      } else if (_scheduledPublishDate!.isBefore(DateTime.now())) {
        errors.add('予約公開日時は現在時刻より後に設定してください');
      } else if (_eventDate != null && _scheduledPublishDate!.isAfter(_eventDate!)) {
        errors.add('予約公開日時はイベント開催日時より前に設定してください');
      }
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
                          color: AppColors.textSecondary,
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
                foregroundColor: AppColors.textSecondary,
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
                    color: AppColors.textSecondary,
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
        () => ValidationService.validateUrl(_streamingUrlController.text, _hasStreaming, '配信URL'),
        () => ValidationService.validateImageFile(_selectedImage, false),
      ],
    );
  }
}