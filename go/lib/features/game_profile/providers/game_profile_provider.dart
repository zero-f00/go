import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/game_profile_model.dart';
import '../../../shared/services/game_profile_service.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/services/game_service.dart';
import '../../../shared/models/game.dart';

/// ゲームプロフィールサービス プロバイダー
final gameProfileServiceProvider = Provider<GameProfileService>((ref) {
  return GameProfileService.instance;
});

/// ゲームサービス プロバイダー
final gameServiceProvider = Provider<GameService>((ref) {
  return GameService.instance;
});

/// ゲームIDからゲーム情報を取得するプロバイダー
final gameByIdProvider = FutureProvider.family<Game?, String>((ref, gameId) async {
  if (gameId.isEmpty) return null;

  final gameService = ref.read(gameServiceProvider);
  return await gameService.getGameById(gameId);
});

/// GameProfileWithGame: プロフィールとゲーム情報を組み合わせたデータクラス
class GameProfileWithGame {
  final GameProfile profile;
  final Game? game;

  const GameProfileWithGame({
    required this.profile,
    this.game,
  });

  String get displayGameName => game?.name ?? profile.gameId;
}

/// GameProfileのリストとそれに対応するゲーム情報を組み合わせたプロバイダー
final gameProfilesWithGamesProvider = FutureProvider<List<GameProfileWithGame>>((ref) async {
  final profiles = await ref.watch(gameProfileListProvider.future);
  final gameService = ref.read(gameServiceProvider);

  final profilesWithGames = <GameProfileWithGame>[];

  for (final profile in profiles) {
    final game = await gameService.getGameById(profile.gameId);
    profilesWithGames.add(GameProfileWithGame(
      profile: profile,
      game: game,
    ));
  }

  return profilesWithGames;
});

/// ゲームプロフィールリスト プロバイダー
final gameProfileListProvider = AsyncNotifierProvider<GameProfileListNotifier, List<GameProfile>>(() {
  return GameProfileListNotifier();
});

class GameProfileListNotifier extends AsyncNotifier<List<GameProfile>> {
  @override
  Future<List<GameProfile>> build() async {
    print('🔄 GameProfileListNotifier: build() called');

    final currentUser = await ref.watch(currentUserDataProvider.future);
    if (currentUser == null) {
      print('❌ GameProfileListNotifier: No current user found');
      return [];
    }

    print('🔄 GameProfileListNotifier: Current user found');
    print('   FirebaseUID (id): ${currentUser.id}');
    print('   CustomUserID (userId): ${currentUser.userId}');

    try {
      final service = ref.read(gameProfileServiceProvider);
      print('🔄 GameProfileListNotifier: Calling getUserGameProfiles for user: ${currentUser.id}');
      final profiles = await service.getUserGameProfiles(currentUser.id);
      print('✅ GameProfileListNotifier: Retrieved ${profiles.length} profiles');
      for (final profile in profiles) {
        print('   - Profile: gameId=${profile.gameId}, username=${profile.gameUsername}, id=${profile.id}');
      }
      return profiles;
    } catch (e) {
      print('❌ GameProfileListNotifier: Error loading profiles: $e');
      return [];
    }
  }

  /// リストを更新
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final currentUser = await ref.read(currentUserDataProvider.future);
      if (currentUser == null) {
        return [];
      }

      final service = ref.read(gameProfileServiceProvider);
      final profiles = await service.getUserGameProfiles(currentUser.id);
      return profiles;
    });
  }

  /// プロフィールを追加
  Future<void> addProfile(GameProfile profile) async {
    final currentProfiles = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentProfiles, profile]);
  }

  /// プロフィールを更新
  Future<void> updateProfile(GameProfile updatedProfile) async {
    final currentProfiles = state.valueOrNull ?? [];
    final newProfiles = currentProfiles.map((profile) {
      return profile.id == updatedProfile.id ? updatedProfile : profile;
    }).toList();
    state = AsyncValue.data(newProfiles);
  }

  /// プロフィールを削除
  Future<void> removeProfile(String userId, String gameId) async {
    final currentProfiles = state.valueOrNull ?? [];
    final newProfiles = currentProfiles.where((profile) =>
      !(profile.userId == userId && profile.gameId == gameId)
    ).toList();
    state = AsyncValue.data(newProfiles);
  }
}

/// お気に入りゲームプロフィールリスト プロバイダー
final favoriteGameProfilesProvider = Provider<List<GameProfile>>((ref) {
  final allProfiles = ref.watch(gameProfileListProvider).valueOrNull ?? [];
  return allProfiles.where((profile) => profile.isFavorite).toList();
});

/// お気に入りゲームプロフィールリスト（ゲーム情報付き） プロバイダー
final favoriteGameProfilesWithGamesProvider = FutureProvider<List<GameProfileWithGame>>((ref) async {
  final allProfilesWithGames = await ref.watch(gameProfilesWithGamesProvider.future);
  return allProfilesWithGames.where((profileWithGame) => profileWithGame.profile.isFavorite).toList();
});

/// 特定のゲームプロフィール プロバイダー（userId + gameId）
final gameProfileProvider = FutureProvider.family<GameProfile?, GameProfileKey>((ref, key) async {
  final service = ref.read(gameProfileServiceProvider);
  try {
    return await service.getGameProfile(key.userId, key.gameId);
  } catch (e) {
    print('❌ gameProfileProvider: Error loading profile ${key.userId}/${key.gameId}: $e');
    return null;
  }
});

/// ゲームプロフィールキー
class GameProfileKey {
  final String userId;
  final String gameId;

  const GameProfileKey({
    required this.userId,
    required this.gameId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameProfileKey &&
        other.userId == userId &&
        other.gameId == gameId;
  }

  @override
  int get hashCode => userId.hashCode ^ gameId.hashCode;
}

/// ゲームID別プロフィールリスト プロバイダー
final gameProfilesByGameProvider = Provider.family<List<GameProfile>, String>((ref, gameId) {
  final allProfiles = ref.watch(gameProfileListProvider).valueOrNull ?? [];
  return allProfiles.where((profile) =>
    profile.gameId == gameId
  ).toList();
});

/// プロフィール統計 プロバイダー
final gameProfileStatsProvider = Provider<GameProfileStats>((ref) {
  final allProfiles = ref.watch(gameProfileListProvider).valueOrNull ?? [];

  return GameProfileStats(
    totalProfiles: allProfiles.length,
    favoriteProfiles: allProfiles.where((p) => p.isFavorite).length,
    experienceDistribution: _getExperienceDistribution(allProfiles),
    topGames: _getTopGames(allProfiles),
  );
});

Map<GameExperience, int> _getExperienceDistribution(List<GameProfile> profiles) {
  final distribution = <GameExperience, int>{};

  for (final experience in GameExperience.values) {
    distribution[experience] = profiles.where((p) => p.experience == experience).length;
  }

  return distribution;
}

List<String> _getTopGames(List<GameProfile> profiles) {
  // gameIdベースでの統計（名前はUIレイヤーで解決）
  final gameCount = <String, int>{};

  for (final profile in profiles) {
    gameCount[profile.gameId] = (gameCount[profile.gameId] ?? 0) + 1;
  }

  final sortedGames = gameCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedGames.take(5).map((e) => e.key).toList();
}

/// トップゲーム（ゲーム情報付き）プロバイダー
final topGamesWithNamesProvider = FutureProvider<List<TopGameEntry>>((ref) async {
  final stats = ref.watch(gameProfileStatsProvider);
  final gameService = ref.read(gameServiceProvider);

  final topGameEntries = <TopGameEntry>[];

  for (final gameId in stats.topGames) {
    final game = await gameService.getGameById(gameId);
    topGameEntries.add(TopGameEntry(
      gameId: gameId,
      gameName: game?.name ?? gameId,
      count: stats.experienceDistribution.values.fold(0, (sum, count) => sum + count), // 簡易計算
    ));
  }

  return topGameEntries;
});

/// トップゲームエントリー
class TopGameEntry {
  final String gameId;
  final String gameName;
  final int count;

  const TopGameEntry({
    required this.gameId,
    required this.gameName,
    required this.count,
  });
}

/// ゲームプロフィール統計データクラス
class GameProfileStats {
  final int totalProfiles;
  final int favoriteProfiles;
  final Map<GameExperience, int> experienceDistribution;
  final List<String> topGames;

  const GameProfileStats({
    required this.totalProfiles,
    required this.favoriteProfiles,
    required this.experienceDistribution,
    required this.topGames,
  });
}