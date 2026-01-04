import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../l10n/app_localizations.dart' show L10n;

import '../../../shared/constants/app_colors.dart';
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
  final _eventPasswordController = TextEditingController();

  // Form state variables
  bool _hasPrize = false;
  Game? _selectedGame;
  final List<String> _selectedPlatforms = [];
  String _visibility = 'public'; // 内部値: 'public' または 'invite_only'
  String _language = 'ja'; // 内部値
  bool _hasStreaming = false;
  bool _hasAgeRestriction = false;
  int _minAge = 0;
  String _approvalMethod = 'auto'; // 内部値

  List<String> _eventTags = [];
  List<String> _streamingUrls = [];
  List<UserData> _selectedManagers = [];
  List<UserData> _selectedSponsors = [];
  List<UserData> _blockedUsers = [];
  List<UserData> _invitedUsers = [];

  DateTime? _eventDate;
  DateTime? _registrationDeadline;
  bool _hasRegistrationDeadline = true; // 申込期限を設定するかどうか
  DateTime? _participationCancelDeadline; // ユーザーキャンセル期限
  File? _selectedImage;
  String? _existingImageUrl; // 編集モード時の既存画像URL


  final ImagePicker _imagePicker = ImagePicker();

  // Firebase operations loading states
  bool _isCreatingEvent = false;
  bool _isSavingDraft = false;
  double _uploadProgress = 0.0;

  // パスワード表示状態
  bool _isPasswordVisible = false;

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
      // GameEvent.visibilityは日本語表記なので内部値に変換
      _visibility = _convertVisibilityToInternalValue(event.visibility);
      // GameEvent.languageは日本語表記の場合があるので内部値に変換
      _language = _convertLanguageToInternalValue(event.language);
      _hasStreaming = event.hasStreaming;
      _eventTags = List.from(event.eventTags);
      _selectedPlatforms.clear();
      _selectedPlatforms.addAll(event.platforms);

      // 日時の初期値設定
      _eventDate = event.startDate;
      _registrationDeadline = event.registrationDeadline;
      _hasRegistrationDeadline = event.registrationDeadline != null;
      _participationCancelDeadline = event.participationCancelDeadline;

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
                title: widget.editingEvent != null ? L10n.of(context).eventEditTitle : L10n.of(context).createEventTitle,
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
                      if (_visibility == L10n.of(context).visibilityInviteOnly) const SizedBox(height: AppDimensions.spacingXL),
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

  /// パスワードフィールド（表示/非表示トグル付き）
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              L10n.of(context).eventPasswordLabel,
              style: const TextStyle(
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
        TextFormField(
          controller: _eventPasswordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: L10n.of(context).eventPasswordHint,
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
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              tooltip: _isPasswordVisible ? L10n.of(context).hidePassword : L10n.of(context).showPassword,
            ),
          ),
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textDark,
          ),
          validator: (value) => ValidationService.of(context).validateEventPassword(value, true),
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

  /// ローカライズされたドロップダウンフィールド
  /// [options] は内部値からローカライズされた表示値へのマップ
  Widget _buildLocalizedDropdownField({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    final l10n = L10n.of(context);
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
          value: value,
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
          items: options.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                ),
              ),
            );
          }).toList(),
          validator: isRequired
              ? (val) {
                  if (val == null || val.isEmpty) {
                    return l10n.requiredFieldError(label);
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
      title: L10n.of(context).basicInfoSection,
      icon: Icons.info,
      children: [
        _buildTextField(
          controller: _eventNameController,
          label: L10n.of(context).eventNameLabel,
          hint: L10n.of(context).eventNameHint,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _subtitleController,
          label: L10n.of(context).subtitleLabel,
          hint: L10n.of(context).subtitleHint,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _descriptionController,
          label: L10n.of(context).descriptionLabel,
          hint: L10n.of(context).descriptionHint,
          maxLines: 4,
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _rulesController,
          label: L10n.of(context).rulesLabel,
          hint: L10n.of(context).rulesHint,
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
        Text(
          L10n.of(context).imageLabel,
          style: const TextStyle(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: AppDimensions.iconXL,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          L10n.of(context).addImageButton,
                          style: const TextStyle(
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
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit,
                              size: AppDimensions.iconL,
                              color: Colors.white,
                            ),
                            const SizedBox(height: AppDimensions.spacingS),
                            Text(
                              L10n.of(context).changeImage,
                              style: const TextStyle(
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
            Text(
              L10n.of(context).selectImage,
              style: const TextStyle(
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
                      label: L10n.of(context).takePhoto,
                      onTap: () => Navigator.pop(context, 'camera'),
                    ),
                    _buildImageSourceOption(
                      icon: Icons.photo_library,
                      label: L10n.of(context).selectFromGallery,
                      onTap: () => Navigator.pop(context, 'gallery'),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildImageSourceOption(
                  icon: Icons.history,
                  label: L10n.of(context).selectFromPastEventImages,
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
        title: L10n.of(context).selectFromPastEventImagesTitle,
        emptyMessage: L10n.of(context).noAvailableImages,
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
          content: Text(L10n.of(context).pastImageLoadError(e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildScheduleSection() {
    return _buildSectionContainer(
      title: L10n.of(context).scheduleSection,
      icon: Icons.schedule,
      children: [
        _buildDateTimeField(
          label: L10n.of(context).eventDateLabel,
          value: _eventDate,
          onTap: () => _selectDateTime(isEventDate: true),
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildRegistrationDeadlineSection(),
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
                        : L10n.of(context).selectDateTime,
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

  /// 申込期限セクション（任意設定可能）
  Widget _buildRegistrationDeadlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              L10n.of(context).registrationDeadline,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Switch.adaptive(
              value: _hasRegistrationDeadline,
              onChanged: (value) {
                setState(() {
                  _hasRegistrationDeadline = value;
                  if (!value) {
                    // 申込期限を無効にする場合、関連する設定もリセット
                    _registrationDeadline = null;
                    _participationCancelDeadline = null;
                  }
                });
              },
              activeColor: AppColors.accent,
            ),
          ],
        ),
        if (!_hasRegistrationDeadline) ...[
          const SizedBox(height: AppDimensions.spacingS),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: AppDimensions.iconS,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppDimensions.spacingS),
                Expanded(
                  child: Text(
                    L10n.of(context).noRegistrationDeadline,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_hasRegistrationDeadline) ...[
          const SizedBox(height: AppDimensions.spacingS),
          _buildDateTimeField(
            label: L10n.of(context).registrationDeadlineSectionLabel,
            value: _registrationDeadline,
            onTap: () => _selectDateTime(isEventDate: false),
            isRequired: true,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildDateTimeField(
            label: L10n.of(context).participantCancelDeadline,
            value: _participationCancelDeadline,
            onTap: () => _selectDateTime(isEventDate: false, isParticipationCancelDeadline: true),
            isRequired: false,
          ),
        ],
      ],
    );
  }

  Widget _buildGameSettingsSection() {
    return _buildSectionContainer(
      title: L10n.of(context).gameSettingsSection,
      icon: Icons.videogame_asset,
      children: [
        _buildGameSelectionField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildPlatformSelectionField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _maxParticipantsController,
          label: L10n.of(context).maxParticipantsLabel,
          hint: L10n.of(context).exampleCount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildTextField(
          controller: _additionalInfoController,
          label: L10n.of(context).additionalInfoLabel,
          hint: L10n.of(context).additionalInfoHint,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildGameSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              L10n.of(context).gameSelectionLabel,
              style: const TextStyle(
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
        Material(
          color: AppColors.backgroundTransparent,
          child: InkWell(
            onTap: () {
              GameSelectionDialog.show(
                context,
                selectedGame: _selectedGame,
                title: L10n.of(context).gameSelectionLabel,
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
                    _selectedGame == null ? L10n.of(context).selectGame : _selectedGame!.name,
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
    final platforms = [L10n.of(context).iosLabel, L10n.of(context).androidLabel];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: L10n.of(context).platformLabel,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(
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
                L10n.of(context).prizeSection,
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
          label: L10n.of(context).hasPrizeLabel,
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
                color: AppColors.warning.withValues(alpha: 0.3),
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
                    L10n.of(context).prizeDisclaimer,
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
            label: L10n.of(context).prizeContentLabel,
            hint: L10n.of(context).prizeContentHint,
            maxLines: 3,
            isRequired: true,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          _buildUserManagementField(
            title: L10n.of(context).sponsorsLabel,
            users: _selectedSponsors,
            onAddUser: _addSponsor,
            onRemoveUser: _removeSponsor,
            emptyMessage: L10n.of(context).addSponsorPlaceholder,
            addButtonText: L10n.of(context).addSponsor,
            addButtonIcon: Icons.business,
          ),
        ],
        ],
      ),
    );
  }

  /// 賞品設定のヘルプダイアログを表示
  void _showPrizeInfoDialog() {
    final l10n = L10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.accent),
            const SizedBox(width: AppDimensions.spacingS),
            Text(l10n.prizeSettingsTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogBulletPoint(l10n.prizeInfoBullet1),
            _buildDialogBulletPoint(l10n.prizeInfoBullet2),
            _buildDialogBulletPoint(l10n.prizeInfoBullet3),
            _buildDialogBulletPoint(l10n.prizeInfoBullet4),
            const SizedBox(height: AppDimensions.spacingM),
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacingS),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                l10n.prizeRecommendation,
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
            child: Text(l10n.understood),
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
      title: L10n.of(context).managementSection,
      icon: Icons.admin_panel_settings,
      children: [
        _buildManagerField(),
        const SizedBox(height: AppDimensions.spacingL),
        _buildUserManagementField(
          title: L10n.of(context).blockedUsersTitle,
          users: _blockedUsers,
          onAddUser: _addBlockedUser,
          onRemoveUser: _removeBlockedUser,
          emptyMessage: L10n.of(context).addBlockedUserPlaceholder,
          addButtonText: L10n.of(context).addBlockedUserButton,
          addButtonIcon: Icons.block,
        ),
      ],
    );
  }

  /// 運営者管理フィールド（自分追加ボタン付き）
  Widget _buildManagerField() {
    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.eventOperatorsTitle,
              style: const TextStyle(
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
          emptyMessage: l10n.addOperatorPlaceholder,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1,
                        color: AppColors.primary,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        l10n.addMyselfButton,
                        style: const TextStyle(
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

            // 相互フォローから追加ボタン
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _addManagerFromFriends,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.people,
                        color: AppColors.secondary,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        l10n.fromMutualFollows,
                        style: const TextStyle(
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
            const SizedBox(height: AppDimensions.spacingM),

            // 他のユーザーを追加ボタン
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _addManager,
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
                      const Icon(
                        Icons.search,
                        color: AppColors.accent,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacingS),
                      Text(
                        l10n.userSearch,
                        style: const TextStyle(
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
    final l10n = L10n.of(context);
    await UserSearchDialog.show(
      context,
      title: l10n.searchOperatorTitle,
      description: l10n.searchOperatorDesc,
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
    final l10n = L10n.of(context);
    await FriendSelectionDialog.show(
      context,
      title: l10n.selectFromMutualFollowsOrganizer,
      description: l10n.selectFromMutualFollowsOrganizerDescription,
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
    final l10n = L10n.of(context);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addSponsorDialogTitle),
        content: Text(l10n.addSponsorDialogQuestion),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSelfAsSponsor();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_alt_1, size: 16),
                const SizedBox(width: 8),
                Text(l10n.addMyselfButton),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSponsorFromFriends();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 8),
                Text(l10n.selectFromMutualFollowsButton),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addSponsorFromSearch();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search, size: 16),
                const SizedBox(width: 8),
                Text(l10n.userSearch),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _addSponsorFromSearch() async {
    final l10n = L10n.of(context);
    await UserSearchDialog.show(
      context,
      title: l10n.searchSponsorTitle,
      description: l10n.searchSponsorDesc,
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
    final l10n = L10n.of(context);
    await FriendSelectionDialog.show(
      context,
      title: l10n.selectFromMutualFollowsSponsor,
      description: l10n.selectFromMutualFollowsSponsorDescription,
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
    final l10n = L10n.of(context);
    await UserSearchDialog.show(
      context,
      title: l10n.searchBlockedUserTitle,
      description: l10n.searchBlockedUserDesc,
      onUserSelected: (user) {
        // Validate that the user is not a manager or sponsor
        if (_selectedManagers.any((manager) => manager.id == user.id) ||
            _selectedSponsors.any((sponsor) => sponsor.id == user.id)) {
          ErrorHandlerService.showErrorDialog(context, l10n.cannotBlockOperatorOrSponsorError);
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
    final l10n = L10n.of(context);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userNotAuthenticated)),
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
          username: currentUser.displayName ?? currentUser.email?.split('@').first ?? l10n.defaultUsername,
          email: currentUser.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // この時点でselfUserDataは必ずnullでない
      final userData = selfUserData!;

      // 重複チェック
      if (!_selectedManagers.any((manager) => manager.id == userData.id)) {
        setState(() {
          _selectedManagers.add(userData);
          // 他のリストから除去
          _blockedUsers.removeWhere((blockedUser) => blockedUser.id == userData.id);
          _selectedSponsors.removeWhere((sponsor) => sponsor.id == userData.id);
          _invitedUsers.removeWhere((invitedUser) => invitedUser.id == userData.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedAsOperatorMessage(userData.username))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.alreadyAddedAsOperator)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurredWithDetails(e.toString()))),
      );
    }
  }

  Future<void> _addSelfAsSponsor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final l10n = L10n.of(context);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.userNotAuthenticated)),
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
          username: currentUser.displayName ?? L10n.of(context).guestUser,
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
        );
      }

      // この時点でselfUserDataは必ずnullでない
      final userData = selfUserData!;

      // 重複チェック
      if (!_selectedSponsors.any((sponsor) => sponsor.id == userData.id)) {
        setState(() {
          _selectedSponsors.add(userData);
          // スポンサーは自動的に運営者にも追加
          if (!_selectedManagers.any((manager) => manager.id == userData.id)) {
            _selectedManagers.add(userData);
          }
          // ブロックリストから除外
          _blockedUsers.removeWhere((blockedUser) => blockedUser.id == userData.id);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.of(context).alreadyAddedAsSponsor)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).errorOccurredWithDetails(e.toString()))),
        );
      }
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
      title: L10n.of(context).searchInviteMembers,
      description: L10n.of(context).addInviteMembersDescription,
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
    final l10n = L10n.of(context);
    // 内部値からローカライズ表示値へのマッピング
    final visibilityOptions = {
      'public': l10n.visibilityPublic,
      'invite_only': l10n.visibilityInviteOnly,
    };
    return _buildSectionContainer(
      title: l10n.categorySection,
      icon: Icons.category,
      children: [
        _buildLocalizedDropdownField(
          label: l10n.visibilityLabel,
          value: _visibility,
          options: visibilityOptions,
          onChanged: (value) {
            setState(() {
              final previousVisibility = _visibility;
              _visibility = value!;
              // 招待制からパブリックに変更した場合、招待制の設定をクリア
              if (previousVisibility == 'invite_only' && _visibility == 'public') {
                _eventPasswordController.clear();
                _invitedUsers.clear();
              }
            });
          },
          isRequired: true,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        TagInputField(
          label: L10n.of(context).eventTagsLabel,
          hint: L10n.of(context).eventTagsHint,
          initialTags: _eventTags,
          maxTags: 10,
          maxTagLength: 20,
          onChanged: (tags) {
            setState(() {
              _eventTags = tags;
            });
          },
          validator: (tags) => ValidationService.of(context).validateEventTags(tags),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildLocalizedDropdownField(
          label: l10n.languageSettingLabel,
          value: _language,
          options: {
            'ja': l10n.languageJapanese,
            'en': l10n.languageEnglish,
            'ko': l10n.languageKorean,
            'zh': l10n.languageChineseSimplified,
            'zh_TW': l10n.languageChineseTraditional,
            'other': l10n.languageOther,
          },
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
    if (_visibility != 'invite_only') {
      return const SizedBox.shrink();
    }

    return _buildSectionContainer(
      title: L10n.of(context).invitationSection,
      icon: Icons.person_add,
      children: [
        // パスワード入力フィールド（表示/非表示トグル付き）
        _buildPasswordField(),
        const SizedBox(height: AppDimensions.spacingL),

        // 招待メンバー管理（ユーザー検索形式）
        _buildUserManagementField(
          title: L10n.of(context).inviteMembersLabel,
          users: _invitedUsers,
          onAddUser: _addInvitedUser,
          onRemoveUser: _removeInvitedUser,
          emptyMessage: L10n.of(context).addInviteMembersEmptyMessage,
          addButtonText: L10n.of(context).addInviteMembersButton,
          addButtonIcon: Icons.person_add_outlined,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildExternalSection() {
    return _buildSectionContainer(
      title: L10n.of(context).externalSection,
      icon: Icons.link,
      children: [
        _buildTextField(
          controller: _contactController,
          label: L10n.of(context).contactLabel,
          hint: L10n.of(context).contactHint,
          maxLines: 4,
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildSwitchField(
          label: L10n.of(context).streamingLabel,
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
            label: L10n.of(context).streamingUrlLabel,
            hint: L10n.of(context).streamingUrlHint,
            initialUrls: _streamingUrls,
            maxUrls: 5,
            onChanged: (urls) {
              setState(() {
                _streamingUrls = urls;
              });
            },
            validator: (urls) {
              if (_hasStreaming && urls.isEmpty) {
                return L10n.of(context).atLeastOneStreamingUrlRequired;
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
      title: L10n.of(context).otherSection,
      icon: Icons.more_horiz,
      children: [
        _buildTextField(
          controller: _policyController,
          label: L10n.of(context).policyLabel,
          hint: L10n.of(context).policyHint,
          maxLines: 4,
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
              ? L10n.of(context).creatingEvent
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
          text: _isSavingDraft ? L10n.of(context).savingDraft : L10n.of(context).saveDraftButton,
          isFullWidth: true,
          isEnabled: !_isCreatingEvent && !_isSavingDraft,
          onPressed: _isCreatingEvent || _isSavingDraft ? null : _saveDraft,
        ),
      ],
    );
  }


  void _selectDateTime({required bool isEventDate, bool isParticipationCancelDeadline = false}) async {
    // 日付選択時の制限を設定
    DateTime initialDate = DateTime.now();
    DateTime firstDate = isEventDate
        ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) // 開催日時は当日から選択可能
        : DateTime.now(); // 申込期限とキャンセル期限は現在時刻から
    DateTime lastDate = DateTime.now().add(const Duration(days: 365));

    if (isParticipationCancelDeadline) {
      // キャンセル期限の場合
      if (!_hasRegistrationDeadline || _registrationDeadline == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).enableRegistrationDeadline),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_eventDate != null) {
        // キャンセル期限は申込期限以降、開催日時の前まで
        firstDate = _registrationDeadline!;
        lastDate = _eventDate!.subtract(const Duration(hours: 1));

        // 申込期限と開催日時の間隔が短すぎる場合の警告
        if (!_registrationDeadline!.isBefore(lastDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).cancelDeadlineTooShort),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        // 初期日付は申込期限と開催日時の間で適切に設定
        initialDate = _registrationDeadline!;
      } else {
        // 開催日時が未設定の場合はエラー
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).setEventDateFirst),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else if (!isEventDate) {
      // 申込期限の場合は開催日時より前でなければならない
      if (_eventDate != null) {
        // 開催日時が設定されている場合、申込期限は開催日時の3時間前まで
        lastDate = _eventDate!.subtract(const Duration(hours: 3));

        // lastDateが現在時刻より前の場合の処理
        if (lastDate.isBefore(DateTime.now())) {
          // 開催日時が3時間以内の場合はエラー
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).eventDateTooCloseForDeadline),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }

        // 初期日付は現在時刻と開催日時の3時間前の間で適切に設定
        if (DateTime.now().isBefore(lastDate)) {
          initialDate = DateTime.now();
        } else {
          initialDate = lastDate;
        }
      } else {
        // 開催日時が未設定の場合はエラー
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.of(context).setEventDateFirst),
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

        // 同日の場合は開催時刻の3時間前を初期値に設定
        final eventTimeOfDay = TimeOfDay.fromDateTime(_eventDate!);
        final eventMinutes = eventTimeOfDay.hour * 60 + eventTimeOfDay.minute;
        final threeHoursBeforeMinutes = eventMinutes - 180; // 3時間 = 180分

        if (threeHoursBeforeMinutes > 0) {
          initialTime = TimeOfDay(
            hour: threeHoursBeforeMinutes ~/ 60,
            minute: threeHoursBeforeMinutes % 60,
          );
        } else {
          // 開催時刻が早い場合は前日を推奨
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).deadlineMustBe3HoursBefore),
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

        // 期限の妥当性を最終チェック
        if (isParticipationCancelDeadline) {
          // キャンセル期限のチェック
          if (_registrationDeadline != null && selectedDateTime.isBefore(_registrationDeadline!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.of(context).cancelDeadlineAfterRegistration),
                backgroundColor: AppColors.error,
              ),
            );
            FocusScope.of(context).unfocus();
            return;
          }
          if (_eventDate != null && (selectedDateTime.isAfter(_eventDate!) || selectedDateTime.isAtSameMomentAs(_eventDate!))) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.of(context).cancelDeadlineBeforeEvent),
                backgroundColor: AppColors.error,
              ),
            );
            FocusScope.of(context).unfocus();
            return;
          }
        } else if (!isEventDate && _eventDate != null) {
          // 申込期限のチェック
          final now = DateTime.now();
          final deadlineLimit = _eventDate!.subtract(const Duration(hours: 3));

          // 現在時刻より前かチェック
          if (selectedDateTime.isBefore(now)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.of(context).registrationDeadlineAfterNow),
                backgroundColor: AppColors.error,
              ),
            );
            FocusScope.of(context).unfocus();
            return;
          }

          // 開催日時の3時間前より後かチェック
          if (selectedDateTime.isAfter(deadlineLimit)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10n.of(context).deadlineMust3HoursBeforeEvent),
                backgroundColor: AppColors.error,
              ),
            );
            FocusScope.of(context).unfocus();
            return;
          }
        }

        // 開催日時が現在時刻より前でないかチェック
        if (isEventDate && selectedDateTime.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.of(context).eventDateAfterNow),
              backgroundColor: AppColors.error,
            ),
          );
          FocusScope.of(context).unfocus();
          return;
        }

        setState(() {
          if (isEventDate) {
            _eventDate = selectedDateTime;
            // 開催日時が変更された場合、申込期限とキャンセル期限をリセット
            if (_registrationDeadline != null &&
                (_registrationDeadline!.isAfter(selectedDateTime) ||
                 _registrationDeadline!.isAtSameMomentAs(selectedDateTime))) {
              _registrationDeadline = null;
            }
            if (_participationCancelDeadline != null &&
                (_participationCancelDeadline!.isAfter(selectedDateTime) ||
                 _participationCancelDeadline!.isAtSameMomentAs(selectedDateTime))) {
              _participationCancelDeadline = null;
            }
          } else if (isParticipationCancelDeadline) {
            _participationCancelDeadline = selectedDateTime;
          } else {
            _registrationDeadline = selectedDateTime;
            // 申込期限が変更された場合、キャンセル期限をリセット（申込期限より前の場合）
            if (_participationCancelDeadline != null &&
                _participationCancelDeadline!.isBefore(selectedDateTime)) {
              _participationCancelDeadline = null;
            }
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
          action: L10n.of(context).changeToRevertToDraft
        );
      } else {
        // 多数の参加者がいる場合は制限
        _showTooManyParticipantsForDraftError(participantCount);
        return false;
      }
    } catch (e) {
      // エラー時は安全のため制限
      if (mounted) {
        ErrorHandlerService.showErrorDialog(
          context,
          L10n.of(context).participantCheckFailedMessage,
        );
      }
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
              Text(
                L10n.of(context).impactOnParticipantsTitle,
                style: const TextStyle(
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
                        L10n.of(context).currentlyParticipantsApplied(participantCount),
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
                L10n.of(context).impactOnRevertToDraft,
                style: const TextStyle(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingS),
              _buildImpactItem(L10n.of(context).impactEventHidden),
              _buildImpactItem(L10n.of(context).impactParticipantsNotified),
              _buildImpactItem(L10n.of(context).impactRegistrationTemporarilyInvalid),
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
                child: Text(
                  L10n.of(context).registrationReactivatedOnRepublish,
                  style: const TextStyle(
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
              child: Text(
                L10n.of(context).cancel,
                style: const TextStyle(
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
              child: Text(
                L10n.of(context).revertToDraftButton,
                style: const TextStyle(fontWeight: FontWeight.w600),
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


  /// イベント下書き化時の参加者への通知送信
  Future<void> _sendDraftConversionNotifications() async {
    try {
      if (widget.editingEvent == null) return;

      final eventId = widget.editingEvent!.id;
      final eventName = _eventNameController.text.trim();

      // 現在のユーザー名を取得（主催者名として使用）
      final currentUser = FirebaseAuth.instance.currentUser;
      final organizerName = currentUser?.displayName ?? currentUser?.email?.split('@').first ?? L10n.of(context).organizerDefault;

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

    } catch (e) {
      // 通知の失敗は下書き保存を阻害しないようにエラーを無視
    }
  }

  /// イベントをFirebaseに保存する共通メソッド
  Future<void> _saveEventWithStatus(EventStatus status) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ErrorHandlerService.showErrorDialog(context, L10n.of(context).pleaseLoginFirst);
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

        // 編集前の招待ユーザーIDを保存（差分通知用）
        final previousInvitedUserIds = List<String>.from(widget.editingEvent!.invitedUserIds);

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

        // 編集モードで招待制イベントの場合、新規追加された招待ユーザーにのみ通知を送信
        if (_visibility == 'invite_only' && _invitedUsers.isNotEmpty && status == EventStatus.published) {
          // 新規追加されたユーザーのみ抽出（既存ユーザーには再送しない）
          final newInvitedUserIds = _invitedUsers
              .map((user) => user.id)
              .where((userId) => !previousInvitedUserIds.contains(userId))
              .toList();

          if (newInvitedUserIds.isNotEmpty) {
            try {
              await EventService.sendEventInvitations(
                eventId: eventId,
                eventName: _eventNameController.text.trim(),
                invitedUserIds: newInvitedUserIds,
                createdByUserId: currentUser.uid,
              );
            } catch (invitationError) {
              // 招待送信エラーは非致命的なので無視
            }
          }
        }
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
        if (_visibility == 'invite_only' && _invitedUsers.isNotEmpty && status == EventStatus.published) {
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
            ErrorHandlerService.showSuccessSnackBar(context, L10n.of(context).eventUpdatedSuccess);
            Navigator.of(context).pop(eventId);
          } else {
            // 新規作成モードの場合
            await _showEventCreatedDialog(eventId);
          }
        } else {
          // 下書き保存時は成功メッセージを表示して前の画面に戻る
          final message = widget.editingEvent != null ? L10n.of(context).changesSavedSuccess : L10n.of(context).draftSavedSuccess;
          ErrorHandlerService.showSuccessSnackBar(context, message);
          Navigator.of(context).pop(eventId);
        }
      }
    } catch (e) {
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
      registrationDeadline: _hasRegistrationDeadline ? _registrationDeadline : null,
      participationCancelDeadline: _participationCancelDeadline,
      maxParticipants: int.parse(_maxParticipantsController.text.trim()),
      additionalInfo: _additionalInfoController.text.trim().isEmpty
          ? null
          : _additionalInfoController.text.trim(),
      hasParticipationFee: false,
      participationFeeText: null,
      participationFeeSupplement: null,
      hasPrize: _hasPrize,
      prizeContent: _hasPrize && _prizeContentController.text.isNotEmpty
          ? _prizeContentController.text.trim()
          : null,
      sponsorIds: _selectedSponsors.map((sponsor) => sponsor.id).toList(),
      managerIds: _selectedManagers.map((manager) => manager.id).toList(),
      blockedUserIds: _blockedUsers.map((user) => user.id).toList(),
      // パブリックの場合は招待ユーザーIDをクリア
      invitedUserIds: _visibility == 'invite_only'
          ? _invitedUsers.map((user) => user.id).toList()
          : [],
      // 下書き保存時もユーザーが選択したvisibilityを保持する
      visibility: _convertVisibilityToEnum(_visibility),
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
      eventPassword: _visibility == 'invite_only' && _eventPasswordController.text.isNotEmpty
          ? _eventPasswordController.text.trim()
          : null,
      status: overrideStatus ?? EventStatus.published,
    );
  }

  /// 作成ボタンのテキストを取得
  String _getCreateButtonText() {
    final isEditing = widget.editingEvent != null;
    return isEditing ? L10n.of(context).updateAndPublishEvent : L10n.of(context).publishEvent;
  }

  /// 文字列の可視性をEnumに変換
  EventVisibility _convertVisibilityToEnum(String visibility) {
    switch (visibility) {
      case 'invite_only':
        return EventVisibility.inviteOnly;
      default:
        return EventVisibility.public;
    }
  }

  /// GameEventの日本語visibility表記を内部値に変換
  String _convertVisibilityToInternalValue(String visibility) {
    switch (visibility) {
      case '招待制':
      case 'inviteOnly':
      case 'invite_only':
        return 'invite_only';
      case 'プライベート':
      case 'private':
        return 'public'; // プライベートはサポートしないためpublicにフォールバック
      case 'パブリック':
      case 'public':
      default:
        return 'public';
    }
  }

  /// 言語表記を内部値に変換
  String _convertLanguageToInternalValue(String language) {
    switch (language) {
      case '日本語':
      case 'Japanese':
      case 'ja':
        return 'ja';
      case '英語':
      case 'English':
      case 'en':
        return 'en';
      case '韓国語':
      case 'Korean':
      case 'ko':
        return 'ko';
      case '中国語（簡体字）':
      case 'Chinese (Simplified)':
      case 'zh':
        return 'zh';
      case '中国語（繁体字）':
      case 'Chinese (Traditional)':
      case 'zh_TW':
        return 'zh_TW';
      case 'その他':
      case 'Other':
      case 'other':
        return 'other';
      default:
        return 'ja'; // デフォルトは日本語
    }
  }

  /// イベント公開時の完全なバリデーション（※アスタリスク付き必須項目のみ）
  List<String> _validateForPublish() {
    final errors = <String>[];

    // ※基本情報セクションの必須項目
    if (_eventNameController.text.trim().isEmpty) {
      errors.add(L10n.of(context).validationEventNameRequired);
    }

    if (_descriptionController.text.trim().isEmpty) {
      errors.add(L10n.of(context).validationEventDescriptionRequired);
    }

    if (_rulesController.text.trim().isEmpty) {
      errors.add(L10n.of(context).validationRulesRequired);
    }

    // ※ゲーム情報セクションの必須項目
    if (_selectedGame == null) {
      errors.add(L10n.of(context).validationGameRequired);
    }

    if (_selectedPlatforms.isEmpty) {
      errors.add(L10n.of(context).validationPlatformRequired);
    }

    // ※開催設定セクションの必須項目
    if (_eventDate == null) {
      errors.add(L10n.of(context).validationEventDateRequired);
    } else if (_eventDate!.isBefore(DateTime.now())) {
      errors.add(L10n.of(context).validationEventDateFuture);
    }

    if (_hasRegistrationDeadline) {
      if (_registrationDeadline == null) {
        errors.add(L10n.of(context).validationRegistrationDeadlineRequired);
      } else if (_eventDate != null &&
                 (_registrationDeadline!.isAfter(_eventDate!) || _registrationDeadline!.isAtSameMomentAs(_eventDate!))) {
        errors.add(L10n.of(context).validationRegistrationDeadlineBeforeEvent);
      }
    }

    if (_maxParticipantsController.text.trim().isEmpty) {
      errors.add(L10n.of(context).validationMaxParticipantsRequired);
    } else {
      final maxParticipants = int.tryParse(_maxParticipantsController.text.trim());
      if (maxParticipants == null || maxParticipants <= 0) {
        errors.add(L10n.of(context).validationMaxParticipantsPositive);
      }
    }

    if (_visibility == 'invite_only') {
      // 招待制イベント時の条件付き必須項目
      if (_invitedUsers.isEmpty) {
        errors.add(L10n.of(context).validationInviteMembersRequired);
      }
    }

    // ※賞品設定時の条件付き必須項目
    if (_hasPrize) {
      if (_prizeContentController.text.trim().isEmpty) {
        errors.add(L10n.of(context).validationPrizeContentRequired);
      }

      if (_selectedManagers.isEmpty) {
        errors.add(L10n.of(context).validationManagerRequiredForPrize);
      }
    }

    // その他の条件付き必須項目のチェック
    if (_hasStreaming && _streamingUrls.isEmpty) {
      errors.add(L10n.of(context).validationStreamingUrlRequired);
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
          SnackBar(
            content: Text(L10n.of(context).validationMaxParticipantsPositive),
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
          SnackBar(
            content: Text(L10n.of(context).validationRegistrationDeadlineBeforeEvent),
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
                    Text(
                      L10n.of(context).eventPublished,
                      style: const TextStyle(
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
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: AppDimensions.iconM,
                    ),
                    const SizedBox(width: AppDimensions.spacingS),
                    Expanded(
                      child: Text(
                        L10n.of(context).eventDetailDescription,
                        style: const TextStyle(
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
              child: Text(L10n.of(context).checkLater),
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
              child: Text(L10n.of(context).viewDetails),
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
              Text(
                L10n.of(context).checkInputContent,
                style: const TextStyle(
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
                Text(
                  L10n.of(context).fillRequiredFields,
                  style: const TextStyle(
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
              child: Text(L10n.of(context).confirm),
            ),
          ],
        );
      },
    );
  }

  /// フォームの基本検証（レガシー）


  /// 中程度の参加者がいる場合の警告ダイアログ（6-20人）
  Future<bool> _showManyParticipantsWarningDialog(
    int participantCount, {
    String? action,
  }) async {
    final actionText = action ?? L10n.of(context).changeToRevertToDraft;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          L10n.of(context).cautionRequired,
          style: const TextStyle(
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
              L10n.of(context).participantsRequireCarefulChange(participantCount),
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              L10n.of(context).enterChangeReason,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingS),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: L10n.of(context).changeReasonHint,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
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
            child: Text(L10n.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
            ),
            child: Text(actionText),
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
        title: Text(
          L10n.of(context).cannotRevertToDraftTitle,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          L10n.of(context).cannotRevertToDraftMessage(participantCount),
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
            child: Text(
              L10n.of(context).understood,
              style: const TextStyle(
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