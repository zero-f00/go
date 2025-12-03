import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/constants/app_dimensions.dart';
import '../../../shared/widgets/app_gradient_background.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../shared/models/game.dart';
import '../providers/game_profile_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/game_service.dart';
import '../../../data/repositories/user_repository.dart';
import 'game_profile_view_screen.dart';

/// ゲームプロフィール表示ラッパー画面
/// userIdとgameIdからGameProfileを取得して表示画面に渡す
class GameProfileViewWrapper extends ConsumerStatefulWidget {
  final String userId;
  final String gameId;

  const GameProfileViewWrapper({
    super.key,
    required this.userId,
    required this.gameId,
  });

  @override
  ConsumerState<GameProfileViewWrapper> createState() => _GameProfileViewWrapperState();
}

class _GameProfileViewWrapperState extends ConsumerState<GameProfileViewWrapper> {
  GameProfile? _gameProfile;
  UserData? _userData;
  Game? _gameData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 並列でデータを取得
      final futures = await Future.wait([
        _loadGameProfile(),
        _loadUserData(),
        _loadGameData(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGameProfile() async {
    try {
      final gameProfileService = ref.read(gameProfileServiceProvider);
      final profile = await gameProfileService.getGameProfile(widget.userId, widget.gameId);
      if (mounted) {
        setState(() {
          _gameProfile = profile;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ゲームプロフィールの取得に失敗しました: $e';
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userRepository = ref.read(userRepositoryProvider);

      // まずカスタムユーザーIDで検索
      UserData? userData = await userRepository.getUserByCustomId(widget.userId);

      // 見つからない場合はFirebase UIDで検索
      if (userData == null) {
        userData = await userRepository.getUserById(widget.userId);
      }

      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ユーザーデータの取得に失敗しました: $e';
        });
      }
    }
  }

  Future<void> _loadGameData() async {
    try {
      final game = await GameService.instance.getGameById(widget.gameId);
      if (mounted) {
        setState(() {
          _gameData = game;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ゲームデータの取得に失敗しました: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'ゲームプロフィール',
                showBackButton: true,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _gameProfile != null
                            ? _buildContent()
                            : _buildNoProfileState(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingXL),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: AppDimensions.spacingM),
            Text(
              'ゲームプロフィールを取得中...',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingL),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProfileState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingL),
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videogame_asset_off,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              'このゲームのプロフィールが見つかりません',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            Text(
              'ユーザーがこのゲームのプロフィールを作成していないか、\n公開設定になっていない可能性があります。',
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeS,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return GameProfileViewScreen(
      profile: _gameProfile!,
      userData: _userData,
      gameName: _gameData?.name,
      gameIconUrl: _gameData?.iconUrl,
    );
  }
}