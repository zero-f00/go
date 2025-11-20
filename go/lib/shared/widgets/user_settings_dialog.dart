import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/game.dart';
import '../services/avatar_service.dart';
import '../services/avatar_storage_service.dart';
import '../services/game_service.dart';
import '../providers/auth_provider.dart';
import 'user_avatar.dart';
import '../../data/models/user_model.dart';
import 'game_selection_dialog.dart';

class UserSettingsDialog extends ConsumerStatefulWidget {
  final bool isInitialSetup;

  const UserSettingsDialog({super.key, this.isInitialSetup = false});

  static Future<bool?> show(
    BuildContext context, {
    bool isInitialSetup = false,
  }) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // 左から
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserSettingsDialog(isInitialSetup: isInitialSetup);
      },
    );
  }

  @override
  ConsumerState<UserSettingsDialog> createState() => _UserSettingsDialogState();
}

class _UserSettingsDialogState extends ConsumerState<UserSettingsDialog> with TickerProviderStateMixin {
  final _userNameController = TextEditingController();
  final _userIdController = TextEditingController();
  final _userBioController = TextEditingController();
  final _contactController = TextEditingController();

  List<Game> _favoriteGames = [];
  File? _avatarFile; // 一時的な加工後画像（保存前）
  String? _avatarUrl; // Firebase Storage URL
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _hasAvatarChanged = false; // アバターが変更されたかどうか
  String? _userIdError;
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();
    _loadAvatar();

    // マーキーアニメーションの初期化
    _marqueeController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // 初期化後に認証済みユーザーの情報を反映
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser != null) {
      // Firestoreから保存済みユーザーデータを取得
      final userDataAsync = ref.read(currentUserDataProvider);
      userDataAsync.when(
        data: (userData) {
          if (userData != null) {
            // 保存済みデータがある場合は、そのデータを表示
            setState(() {
              _userNameController.text = userData.username;
              _userIdController.text = userData.userId;
              if (userData.bio != null && userData.bio!.isNotEmpty) {
                _userBioController.text = userData.bio!;
              }
              if (userData.contact != null && userData.contact!.isNotEmpty) {
                _contactController.text = userData.contact!;
              }
              // お気に入りゲームを非同期で読み込み
              _loadFavoriteGames(userData.favoriteGameIds);
              // アバターURLを読み込み
              if (userData.photoUrl != null && userData.photoUrl!.isNotEmpty) {
                _avatarUrl = userData.photoUrl;
              }
              _hasAvatarChanged = false;
            });
          } else {
            // 保存済みデータがない場合は認証情報から初期値を設定
            setState(() {
              if (currentUser.displayName != null) {
                _userNameController.text = currentUser.displayName!;
              }
              // 初回設定時はユーザーIDを空にして、ユーザーに入力させる
              if (widget.isInitialSetup) {
                _userIdController.text = '';
              }
            });
          }
        },
        loading: () {
          // ローディング中は認証情報から初期値を設定
          setState(() {
            if (currentUser.displayName != null) {
              _userNameController.text = currentUser.displayName!;
            }
            if (widget.isInitialSetup) {
              _userIdController.text = '';
            }
          });
        },
        error: (_, __) {
          // エラー時は認証情報から初期値を設定
          setState(() {
            if (currentUser.displayName != null) {
              _userNameController.text = currentUser.displayName!;
            }
            if (widget.isInitialSetup) {
              _userIdController.text = '';
            }
          });
        },
      );
    } else if (!widget.isInitialSetup) {
      // ゲストユーザーのデフォルト値
      setState(() {
        _userNameController.text = 'ゲストユーザー';
        _userIdController.text = 'guest_001';
      });
    }
  }

  Future<void> _loadAvatar() async {
    final String? avatarPath = await AvatarService.instance.getAvatarPath();
    if (avatarPath != null && File(avatarPath).existsSync()) {
      setState(() {
        _avatarFile = File(avatarPath);
      });
    }
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userIdController.dispose();
    _userBioController.dispose();
    _contactController.dispose();
    _marqueeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
          minWidth: 350,
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
                    if (widget.isInitialSetup) ...[
                      _buildWelcomeMessage(),
                      const SizedBox(height: AppDimensions.spacingXL),
                    ],
                    _buildUserAvatar(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildUserInfoSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildFavoriteGamesSection(),
                    const SizedBox(height: AppDimensions.spacingL),
                    _buildContactSection(),
                    if (widget.isInitialSetup) ...[
                      const SizedBox(height: AppDimensions.spacingL),
                      _buildInitialSetupMessage(),
                    ],
                    const SizedBox(height: AppDimensions.spacingL),
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusL),
          topRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.settings,
            color: AppColors.accent,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              widget.isInitialSetup ? 'ようこそ！初回設定' : 'ユーザー設定',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (!widget.isInitialSetup) // 初回設定時は閉じるボタンを非表示
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.textDark),
            ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Center(
      child: Stack(
        children: [
          UserAvatar(
            size: 100,
            avatarFile: _avatarFile,
            avatarUrl: _avatarUrl,
            backgroundColor: AppColors.overlayLight,
            iconColor: AppColors.textSecondary,
            borderColor: AppColors.border,
            borderWidth: 2,
            overlayIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((_avatarFile != null || _avatarUrl != null) && !_isUploading)
                  GestureDetector(
                    onTap: _onRemoveAvatar,
                    child: Container(
                      margin: const EdgeInsets.only(
                        right: AppDimensions.spacingXS,
                      ),
                      padding: const EdgeInsets.all(AppDimensions.spacingS),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppColors.textOnPrimary,
                        size: AppDimensions.iconS,
                      ),
                    ),
                  ),
                if (!_isUploading)
                  GestureDetector(
                    onTap: _onChangeAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingS),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: AppColors.textOnPrimary,
                        size: AppDimensions.iconS,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // アップロード進捗表示
          if (_isUploading)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: _uploadProgress,
                      strokeWidth: 3.0,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ユーザー情報',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildTextField(
          label: 'ユーザー名',
          controller: _userNameController,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildUserIdField(),
        const SizedBox(height: AppDimensions.spacingM),
        _buildBioField(),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: (value) {
            if (validator != null && label == 'ユーザーID') {
              setState(() {
                _userIdError = validator(value);
              });
            }
          },
          decoration: InputDecoration(
            labelText: label,
            helperText: helperText,
            errorText: label == 'ユーザーID' ? _userIdError : null,
            helperStyle: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.textSecondary,
            ),
            errorStyle: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.error,
            ),
            prefixIcon: Icon(icon, color: AppColors.accent),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            filled: !enabled,
            fillColor: enabled ? null : AppColors.backgroundLight,
          ),
          style: TextStyle(
            color: enabled ? AppColors.textDark : AppColors.textSecondary,
            fontSize: AppDimensions.fontSizeM,
          ),
        ),
      ],
    );
  }

  Widget _buildUserIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _userIdController,
          enabled: true,
          onChanged: (value) {
            setState(() {
              _userIdError = _validateUserId(value);
            });
          },
          decoration: InputDecoration(
            labelText: 'ユーザーID',
            errorText: _userIdError,
            errorStyle: const TextStyle(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.error,
            ),
            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.accent),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppDimensions.fontSizeM,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        // 自動流れるヘルパーテキスト（マーキー）
        _buildMarqueeHelperText(),
      ],
    );
  }

  Widget _buildMarqueeHelperText() {
    const String helperText = '3-20文字、英字・数字・アンダーバー(_)で入力してください。例: my_game_id123';

    return SizedBox(
      height: 20,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _marqueeController,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const double iconWidth = 18.0; // アイコン + スペース
                const double textPadding = 50.0; // テキスト間の余白

                // テキストの幅を測定
                final TextPainter textPainter = TextPainter(
                  text: TextSpan(
                    text: helperText,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                )..layout();

                final double textWidth = textPainter.size.width;
                final double totalWidth = iconWidth + textWidth + textPadding;
                final double containerWidth = constraints.maxWidth;

                // テキストがコンテナより長い場合のみアニメーション
                if (totalWidth <= containerWidth) {
                  return Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        helperText,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSizeS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }

                // マーキーアニメーション
                final double animationDistance = totalWidth;
                final double currentOffset = -animationDistance * _marqueeController.value;

                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: currentOffset,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            helperText,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: currentOffset + animationDistance,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            helperText,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSizeS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自己紹介',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _userBioController,
          maxLines: 3,
          maxLength: 150,
          decoration: InputDecoration(
            hintText: '自分について簡単に紹介してください...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.description_outlined, color: AppColors.accent),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
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
          ),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppDimensions.fontSizeM,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteGamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'お気に入りゲーム',
                style: TextStyle(
                  fontSize: AppDimensions.fontSizeL,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addFavoriteGame,
              icon: const Icon(Icons.add, size: AppDimensions.iconS),
              label: const Text('追加'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        if (_favoriteGames.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.videogame_asset_off,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconL,
                ),
                SizedBox(height: AppDimensions.spacingS),
                Text(
                  'お気に入りゲームが登録されていません',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppDimensions.fontSizeM,
                  ),
                ),
              ],
            ),
          )
        else
          ..._favoriteGames.map((game) => _buildGameTile(game)).toList(),
      ],
    );
  }

  Widget _buildGameTile(Game game) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (game.iconUrl != null)
            Container(
              width: AppDimensions.iconXL,
              height: AppDimensions.iconXL,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                image: DecorationImage(
                  image: NetworkImage(game.iconUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: AppDimensions.iconXL,
              height: AppDimensions.iconXL,
              decoration: BoxDecoration(
                color: AppColors.overlayMedium,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(
                Icons.videogame_asset,
                color: AppColors.textSecondary,
                size: AppDimensions.iconM,
              ),
            ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (game.developer.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    game.developer,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSizeS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFavoriteGame(game),
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '連絡先・コミュニティ',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _buildContactTextArea(),
      ],
    );
  }

  Widget _buildContactTextArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '連絡先情報',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        TextField(
          controller: _contactController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                '例：Discord: @username, Twitter: @username, YouTube: @channel, Steam: steamname, LINE: lineid',
            hintStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppDimensions.fontSizeS,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.contact_page_outlined, color: AppColors.accent),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.spacingM),
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
          ),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: AppDimensions.fontSizeM,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          'ゲームイベントの連絡に使用したいプラットフォームやアカウント情報を自由な形式で入力してください。',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeS,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  void _addFavoriteGame() {
    GameSelectionDialog.show(
      context,
      title: 'お気に入りゲームを追加',
      onGameSelected: (game) async {
        if (game != null && !_favoriteGames.any((g) => g.id == game.id)) {
          // ゲームを共有キャッシュに保存してIDを取得
          print('🔄 UserSettingsDialog: Caching favorite game to shared repository: ${game.name}');
          final gameId = await GameService.instance.getOrCacheGame(game);
          if (gameId != null) {
            print('✅ UserSettingsDialog: Game cached successfully with ID: $gameId');
            setState(() {
              _favoriteGames.add(game);
            });
          } else {
            print('❌ UserSettingsDialog: Failed to cache game');
          }
        }
      },
    );
  }

  void _removeFavoriteGame(Game game) {
    setState(() {
      _favoriteGames.removeWhere((g) => g.id == game.id);
    });
  }

  /// お気に入りゲームのIDリストからゲーム情報を非同期で取得
  Future<void> _loadFavoriteGames(List<String> gameIds) async {
    if (gameIds.isEmpty) {
      setState(() {
        _favoriteGames.clear();
      });
      return;
    }

    try {
      print('🔍 UserSettingsDialog: Loading favorite games from IDs: ${gameIds.length} games');
      final games = await GameService.instance.getGamesByIds(gameIds);
      setState(() {
        _favoriteGames.clear();
        _favoriteGames.addAll(games);
      });
      print('✅ UserSettingsDialog: Loaded ${games.length} favorite games');
    } catch (e) {
      print('❌ UserSettingsDialog: Error loading favorite games: $e');
    }
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingL,
        AppDimensions.spacingL,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusL),
          bottomRight: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!widget.isInitialSetup) // 初回設定時はキャンセルボタンを非表示
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spacingM,
                    ),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                  ),
                  child: const Text(
                    'キャンセル',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: AppDimensions.fontSizeM,
                    ),
                  ),
                ),
              ),
            if (!widget.isInitialSetup)
              const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.isInitialSetup ? '設定を完了' : '保存',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: AppDimensions.fontSizeM,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onChangeAvatar() async {
    debugPrint('🚀 UserSettingsDialog: _onChangeAvatar called');
    try {
      debugPrint('🔄 UserSettingsDialog: Calling AvatarService.pickAndCropAvatar');
      final File? croppedImage = await AvatarService.instance.pickAndCropAvatar(context);
      debugPrint('✅ UserSettingsDialog: pickAndCropAvatar returned: ${croppedImage?.path}');

      if (croppedImage != null) {
        debugPrint('✅ UserSettingsDialog: Setting cropped image');
        setState(() {
          _avatarFile = croppedImage;
          _hasAvatarChanged = true;
          // 既存のFirebase URLをクリア（新しい画像が選択されたため）
          _avatarUrl = null;
        });
        debugPrint('✅ UserSettingsDialog: Avatar state updated successfully');
      } else {
        debugPrint('⚠️ UserSettingsDialog: No image was selected or cropping was cancelled');
      }
    } catch (e) {
      debugPrint('❌ UserSettingsDialog: Error in _onChangeAvatar: $e');
      if (mounted) {
        _showErrorDialog('画像の選択に失敗しました: $e');
      }
    }
  }

  void _onRemoveAvatar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アバターを削除'),
        content: const Text('アバター画像を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _avatarFile = null;
                _avatarUrl = null;
                _hasAvatarChanged = true;
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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

  Widget _buildWelcomeMessage() {
    final currentUser = ref.watch(currentFirebaseUserProvider);
    final userData = ref.watch(currentUserDataProvider);

    // アプリ側のユーザー名を優先、なければAuthのdisplayName
    String userName = currentUser?.displayName ?? 'ユーザー';
    userData.when(
      data: (data) {
        if (data?.username.isNotEmpty == true) {
          userName = data!.username;
        }
      },
      loading: () {},
      error: (_, __) {},
    );

    return Column(
      children: [
        Text(
          '$userName さん',
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        const Text(
          'ゲームイベントをより楽しむために、プロフィール情報を設定しましょう。',
          style: TextStyle(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    if (_isLoading) return;

    if (widget.isInitialSetup) {
      await _completeInitialSetup();
    } else {
      await _saveUserSettings();
    }
  }

  Future<void> _completeInitialSetup() async {
    final nickname = _userNameController.text.trim();
    final userId = _userIdController.text.trim();

    if (nickname.isEmpty) {
      _showErrorDialog('ユーザー名を入力してください');
      return;
    }

    if (nickname.length < 2) {
      _showErrorDialog('ユーザー名は2文字以上で入力してください');
      return;
    }

    // ユーザーIDのバリデーションチェック
    final userIdError = _validateUserId(userId);
    if (userIdError != null) {
      _showErrorDialog(userIdError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 UserSettingsDialog: Starting initial user setup...');
      print('   - Username: $nickname');
      print('   - UserID: $userId');
      print(
        '   - Bio: ${_userBioController.text.isNotEmpty ? _userBioController.text : '(empty)'}',
      );
      print(
        '   - Contact: ${_contactController.text.isNotEmpty ? _contactController.text : '(empty)'}',
      );

      // Firebase Authからユーザー情報を取得
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception('認証されたユーザーが見つかりません');
      }

      final userRepository = ref.read(userRepositoryProvider);

      // カスタムユーザーIDの重複チェック
      final isDuplicate = !(await userRepository.isUserIdAvailable(userId));
      if (isDuplicate) {
        setState(() {
          _userIdError = 'このユーザーIDは既に使用されています';
        });
        _showErrorDialog('このユーザーIDは既に使用されています');
        return;
      }


      // UserDataモデルを作成
      final userData = UserData.create(
        id: currentUser.uid,
        userId: userId,
        username: nickname,
        email: currentUser.email ?? '',
        bio: _userBioController.text.trim().isEmpty
            ? null
            : _userBioController.text.trim(),
        photoUrl: null, // Authのアイコンは使わず、ユーザー設定アイコンのみ使用
      ).copyWith(
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        favoriteGameIds: _favoriteGames.map((game) => game.id).toList(),
        // isSetupCompleted: true, // 廃止 - userIdの有無で判定するため
      );

      // Firestoreに保存（userIdが設定されているため、設定完了とみなされる）
      await userRepository.createUser(userData);

      print('✅ UserSettingsDialog: Initial user setup completed successfully');

      // ユーザーデータプロバイダーを無効化してリフレッシュ
      ref.invalidate(currentUserDataProvider);

      // 設定状態関連のプロバイダーも強制的に更新
      ref.invalidate(delayedInitialSetupCheckProvider);
      ref.invalidate(userSettingsCompletedProvider);

      // 短い遅延後にプロバイダーの状態を再確認
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        Navigator.of(context).pop(true); // 設定完了を通知
      }
    } catch (e) {
      print('❌ UserSettingsDialog: Error during initial setup: $e');
      _showErrorDialog('初期設定の保存に失敗しました\n\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveInitialUserSettings() async {
    // 保存のシミュレート（実際はFirestoreやSharedPreferencesに保存）
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: 実際のデータベース保存処理
    // 例：
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    //     'username': _userNameController.text,
    //     'bio': _userBioController.text,
    //     'contact': _contactController.text,
    //     'favoriteGames': _favoriteGames.map((g) => g.toJson()).toList(),
    //     'setupCompleted': true,
    //     'createdAt': FieldValue.serverTimestamp(),
    //   });
    // }
  }

  Future<void> _saveUserSettings() async {
    final nickname = _userNameController.text.trim();
    final userId = _userIdController.text.trim();

    if (nickname.isEmpty) {
      _showErrorDialog('ユーザー名を入力してください');
      return;
    }

    if (nickname.length < 2) {
      _showErrorDialog('ユーザー名は2文字以上で入力してください');
      return;
    }

    // ユーザーIDのバリデーションチェック
    if (userId.isNotEmpty) {
      final userIdError = _validateUserId(userId);
      if (userIdError != null) {
        _showErrorDialog(userIdError);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 UserSettingsDialog: Updating user settings...');

      // Firebase Authからユーザー情報を取得
      final currentUser = ref.read(currentFirebaseUserProvider);
      if (currentUser == null) {
        throw Exception('認証されたユーザーが見つかりません');
      }

      final userRepository = ref.read(userRepositoryProvider);

      // カスタムユーザーIDの重複チェック（変更時のみ）
      if (userId.isNotEmpty) {
        final isDuplicate = !(await userRepository.isUserIdAvailable(
          userId,
          excludeUserId: currentUser.uid,
        ));
        if (isDuplicate) {
          setState(() {
            _userIdError = 'このユーザーIDは既に使用されています';
          });
          _showErrorDialog('このユーザーIDは既に使用されています');
          return;
        }
      }

      // アバター画像をFirebase Storageにアップロード
      String? finalAvatarUrl = _avatarUrl;
      if (_hasAvatarChanged) {
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        try {
          if (_avatarFile != null) {
            // 新しい画像をアップロード
            finalAvatarUrl = await AvatarStorageService.instance.uploadAvatar(
              file: _avatarFile!,
              onProgress: (progress) {
                if (mounted) {
                  setState(() {
                    _uploadProgress = progress;
                  });
                }
              },
            );
          } else {
            // 画像が削除された場合
            if (_avatarUrl != null) {
              await AvatarStorageService.instance.deleteAvatar();
            }
            finalAvatarUrl = null;
          }

          setState(() {
            _isUploading = false;
            _avatarUrl = finalAvatarUrl;
            _hasAvatarChanged = false;
          });
        } catch (uploadError) {
          setState(() {
            _isUploading = false;
          });
          throw Exception('画像のアップロードに失敗しました: $uploadError');
        }
      }


      // 更新リクエストを作成
      final updateRequest = UpdateUserRequest(
        username: nickname,
        userId: userId.isEmpty ? null : userId,
        bio: _userBioController.text.trim().isEmpty
            ? null
            : _userBioController.text.trim(),
        contact: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        favoriteGameIds: _favoriteGames.map((game) => game.id).toList(),
        photoUrl: finalAvatarUrl,
      );

      // 新しいプロバイダーシステムを使用して更新
      final userDataNotifier = ref.read(userDataNotifierProvider.notifier);
      await userDataNotifier.updateUserData(updateRequest);

      print('✅ UserSettingsDialog: User settings updated successfully');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('設定保存'),
            content: const Text('設定が保存されました。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // AlertDialogを閉じる
                  Navigator.pop(context); // UserSettingsDialogを閉じる
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ UserSettingsDialog: Error saving user settings: $e');
      _showErrorDialog('設定の保存に失敗しました\n\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateUserId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ユーザーIDを入力してください';
    }

    // 長さチェック
    if (value.length < 3 || value.length > 20) {
      return 'ユーザーIDは3文字以上20文字以下で入力してください';
    }

    // 文字種チェック（英数字とアンダースコアのみ）
    final RegExp userIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!userIdRegex.hasMatch(value)) {
      return '英字・数字・アンダーバー(_)のみ入力できます';
    }

    // 最初の文字が数字でないかチェック
    if (RegExp(r'^[0-9]').hasMatch(value)) {
      return '英字から始めてください（例: game123）';
    }

    // 予約語チェック
    final List<String> reservedWords = [
      'admin', 'root', 'user', 'guest', 'null', 'undefined', 'system',
      'test', 'demo', 'api', 'www', 'ftp', 'mail', 'email', 'support'
    ];
    if (reservedWords.contains(value.toLowerCase())) {
      return '別のユーザーIDをお選びください';
    }

    return null;
  }

  /// ユーザーIDの重複チェック（シミュレーション）
  /// 実際のアプリではFirestoreやバックエンドAPIで重複チェックを行う
  Future<bool> _checkUserIdDuplicate(String userId) async {
    print('🔄 UserSettingsDialog: Checking UserID duplicate for: $userId');

    // 重複チェックのシミュレート
    await Future.delayed(const Duration(milliseconds: 500));

    // シミュレーションのため、特定のユーザーIDを既に使用済みとして扱う
    final List<String> existingUserIds = [
      'admin123', 'user001', 'test_user', 'sample_id', 'demo_user'
    ];

    final isDuplicate = existingUserIds.contains(userId.toLowerCase());
    print('✅ UserSettingsDialog: Duplicate check result: $isDuplicate');

    // TODO: 実際の実装では以下のようなコードになる
    // try {
    //   final result = await FirebaseFirestore.instance
    //       .collection('users')
    //       .where('userId', isEqualTo: userId)
    //       .limit(1)
    //       .get();
    //   return result.docs.isNotEmpty;
    // } catch (e) {
    //   print('Error checking duplicate: $e');
    //   throw Exception('重複チェックに失敗しました');
    // }

    return isDuplicate;
  }

  Widget _buildInitialSetupMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.accent,
            size: AppDimensions.iconM,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            'プロフィール設定を完了してゲームイベントを楽しみましょう',
            style: TextStyle(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
