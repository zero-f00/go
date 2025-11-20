import '../../data/models/game_profile_model.dart';
import '../../data/repositories/game_profile_repository.dart';
import 'error_handler_service.dart';

/// ゲームプロフィール管理サービス
class GameProfileService {
  static final GameProfileService _instance = GameProfileService._internal();
  factory GameProfileService() => _instance;
  GameProfileService._internal();

  static GameProfileService get instance => _instance;

  final GameProfileRepository _repository = FirestoreGameProfileRepository();

  /// ゲームプロフィールを作成
  Future<bool> createGameProfile(GameProfile profile) async {
    try {
      print('🔄 GameProfileService: Creating game profile for gameId: ${profile.gameId}');

      // 同じゲームのプロフィールが既に存在するかチェック
      final existing = await _repository.getGameProfile(profile.userId, profile.gameId);
      if (existing != null) {
        throw Exception('このゲームのプロフィールは既に存在します');
      }

      await _repository.createGameProfile(profile);

      print('✅ GameProfileService: Game profile created successfully');
      return true;
    } catch (e) {
      print('❌ GameProfileService: Error creating game profile: $e');
      ErrorHandlerService.logError('ゲームプロフィールの作成', e);
      return false;
    }
  }

  /// ゲームプロフィールを更新
  Future<bool> updateGameProfile(GameProfile profile) async {
    try {
      if (profile.gameId.isEmpty) {
        throw Exception('ゲームIDが設定されていません');
      }

      print('🔄 GameProfileService: Updating game profile ${profile.gameId}');

      await _repository.updateGameProfile(profile);

      print('✅ GameProfileService: Game profile updated successfully');
      return true;
    } catch (e) {
      print('❌ GameProfileService: Error updating game profile: $e');
      ErrorHandlerService.logError('ゲームプロフィールの更新', e);
      return false;
    }
  }

  /// ゲームプロフィールを削除
  Future<bool> deleteGameProfile(String userId, String gameId) async {
    try {
      print('🔄 GameProfileService: Deleting game profile $gameId for user $userId');

      await _repository.deleteGameProfile(userId, gameId);

      print('✅ GameProfileService: Game profile deleted successfully');
      return true;
    } catch (e) {
      print('❌ GameProfileService: Error deleting game profile: $e');
      ErrorHandlerService.logError('ゲームプロフィールの削除', e);
      return false;
    }
  }

  /// ゲームプロフィールを取得
  Future<GameProfile?> getGameProfile(String userId, String gameId) async {
    try {
      print('🔄 GameProfileService: Getting game profile $gameId for user $userId');

      final profile = await _repository.getGameProfile(userId, gameId);

      if (profile != null) {
        print('✅ GameProfileService: Game profile retrieved: gameId ${profile.gameId}');
      } else {
        print('ℹ️ GameProfileService: Game profile not found');
      }

      return profile;
    } catch (e) {
      print('❌ GameProfileService: Error getting game profile: $e');
      ErrorHandlerService.logError('ゲームプロフィールの取得', e);
      return null;
    }
  }

  /// ユーザーのゲームプロフィール一覧を取得
  Future<List<GameProfile>> getUserGameProfiles(String userId) async {
    try {
      print('🔄 GameProfileService: Getting game profiles for user $userId');

      final profiles = await _repository.getUserGameProfiles(userId);

      print('✅ GameProfileService: Retrieved ${profiles.length} game profiles');
      for (final profile in profiles) {
        print('   - Service Profile: gameId=${profile.gameId}, username=${profile.gameUsername}, id=${profile.id}');
      }
      return profiles;
    } catch (e) {
      print('❌ GameProfileService: Error getting user game profiles: $e');
      ErrorHandlerService.logError('ユーザーゲームプロフィールの取得', e);
      return [];
    }
  }

  /// ユーザーのお気に入りゲームプロフィールを取得（UserDataから）
  Future<List<GameProfile>> getFavoriteGameProfiles(String userId, List<String> favoriteGameIds) async {
    try {
      print('🔄 GameProfileService: Getting favorite game profiles for user $userId');

      if (favoriteGameIds.isEmpty) {
        print('ℹ️ GameProfileService: No favorite games specified');
        return [];
      }

      final profiles = await _repository.getFavoriteGameProfiles(userId, favoriteGameIds);

      print('✅ GameProfileService: Retrieved ${profiles.length} favorite game profiles');
      return profiles;
    } catch (e) {
      print('❌ GameProfileService: Error getting favorite game profiles: $e');
      ErrorHandlerService.logError('お気に入りゲームプロフィールの取得', e);
      return [];
    }
  }


  /// プロフィールのお気に入り状態を切り替え
  Future<bool> toggleFavoriteStatus(String userId, String gameId) async {
    try {
      print('🔄 GameProfileService: Toggling favorite status for $gameId');

      final profile = await _repository.getGameProfile(userId, gameId);
      if (profile == null) {
        throw Exception('プロフィールが見つかりません');
      }

      final updatedProfile = profile.copyWith(isFavorite: !profile.isFavorite);
      await _repository.updateGameProfile(updatedProfile);

      print('✅ GameProfileService: Favorite status toggled to ${updatedProfile.isFavorite}');
      return true;
    } catch (e) {
      print('❌ GameProfileService: Error toggling favorite status: $e');
      ErrorHandlerService.logError('お気に入り状態の切り替え', e);
      return false;
    }
  }

  /// プロフィールの公開状態を切り替え
  Future<bool> togglePublicStatus(String userId, String gameId) async {
    try {
      print('🔄 GameProfileService: Toggling public status for $gameId');

      final profile = await _repository.getGameProfile(userId, gameId);
      if (profile == null) {
        throw Exception('プロフィールが見つかりません');
      }

      final updatedProfile = profile.copyWith(isPublic: !profile.isPublic);
      await _repository.updateGameProfile(updatedProfile);

      print('✅ GameProfileService: Public status toggled to ${updatedProfile.isPublic}');
      return true;
    } catch (e) {
      print('❌ GameProfileService: Error toggling public status: $e');
      ErrorHandlerService.logError('公開状態の切り替え', e);
      return false;
    }
  }



}