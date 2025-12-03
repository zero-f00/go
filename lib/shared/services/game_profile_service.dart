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

      // 同じゲームのプロフィールが既に存在するかチェック
      final existing = await _repository.getGameProfile(profile.userId, profile.gameId);
      if (existing != null) {
        throw Exception('このゲームのプロフィールは既に存在します');
      }

      await _repository.createGameProfile(profile);

      return true;
    } catch (e) {
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


      await _repository.updateGameProfile(profile);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('ゲームプロフィールの更新', e);
      return false;
    }
  }

  /// ゲームプロフィールを削除
  Future<bool> deleteGameProfile(String userId, String gameId) async {
    try {

      await _repository.deleteGameProfile(userId, gameId);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('ゲームプロフィールの削除', e);
      return false;
    }
  }

  /// ゲームプロフィールを取得
  Future<GameProfile?> getGameProfile(String userId, String gameId) async {
    try {

      final profile = await _repository.getGameProfile(userId, gameId);

      if (profile != null) {
      } else {
      }

      return profile;
    } catch (e) {
      ErrorHandlerService.logError('ゲームプロフィールの取得', e);
      return null;
    }
  }

  /// ユーザーのゲームプロフィール一覧を取得
  Future<List<GameProfile>> getUserGameProfiles(String userId) async {
    try {

      final profiles = await _repository.getUserGameProfiles(userId);

      for (final profile in profiles) {
      }
      return profiles;
    } catch (e) {
      ErrorHandlerService.logError('ユーザーゲームプロフィールの取得', e);
      return [];
    }
  }

  /// ユーザーのお気に入りゲームプロフィールを取得（UserDataから）
  Future<List<GameProfile>> getFavoriteGameProfiles(String userId, List<String> favoriteGameIds) async {
    try {

      if (favoriteGameIds.isEmpty) {
        return [];
      }

      final profiles = await _repository.getFavoriteGameProfiles(userId, favoriteGameIds);

      return profiles;
    } catch (e) {
      ErrorHandlerService.logError('お気に入りゲームプロフィールの取得', e);
      return [];
    }
  }


  /// プロフィールのお気に入り状態を切り替え
  Future<bool> toggleFavoriteStatus(String userId, String gameId) async {
    try {

      final profile = await _repository.getGameProfile(userId, gameId);
      if (profile == null) {
        throw Exception('プロフィールが見つかりません');
      }

      final updatedProfile = profile.copyWith(isFavorite: !profile.isFavorite);
      await _repository.updateGameProfile(updatedProfile);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('お気に入り状態の切り替え', e);
      return false;
    }
  }

  /// プロフィールの公開状態を切り替え
  Future<bool> togglePublicStatus(String userId, String gameId) async {
    try {

      final profile = await _repository.getGameProfile(userId, gameId);
      if (profile == null) {
        throw Exception('プロフィールが見つかりません');
      }

      final updatedProfile = profile.copyWith(isPublic: !profile.isPublic);
      await _repository.updateGameProfile(updatedProfile);

      return true;
    } catch (e) {
      ErrorHandlerService.logError('公開状態の切り替え', e);
      return false;
    }
  }



}