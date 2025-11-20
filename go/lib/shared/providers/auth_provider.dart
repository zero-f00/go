import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../constants/app_strings.dart';

/// AuthService プロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// UserRepository プロバイダー
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// 明示的なユーザー作成プロバイダー（初回設定画面で使用）
final createUserProvider = FutureProvider.family<UserData?, void>((ref, _) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.createUserFromAuth();
});

/// 認証状態変更を監視するプロバイダー（公式ドキュメント通り）
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((user) async {
    // 認証状態の変更をログ出力
    if (user != null) {
      print('🔄 Auth State Changed: User signed in - ${user.email} (UID: ${user.uid})');
      print('   - Display Name: ${user.displayName}');
      print('   - Email Verified: ${user.emailVerified}');
    } else {
      print('🔄 Auth State Changed: User signed out (null)');
      // ログアウト時に全てのローカルキャッシュをクリア
      await _clearAllLocalData();
    }
    return user;
  }).asyncMap((futureUser) async => await futureUser);
});

/// ログアウト時のローカルデータクリア
Future<void> _clearAllLocalData() async {
  try {
    print('🧹 Clearing all local data after logout...');

    // UserServiceのキャッシュクリア
    await UserService.instance.clearAllUserData();

    // TODO: 他のサービスのキャッシュクリアも追加
    // - SharedPreferences の他のキー
    // - Hive/SQLite等の他のローカルDB
    // - 画像キャッシュ等

    print('✅ Local data cleared successfully');
  } catch (e) {
    print('❌ Error clearing local data: $e');
  }
}

/// サインイン状態プロバイダー
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      final isSignedIn = user != null;
      print('📊 IsSignedIn Provider: $isSignedIn (User: ${user?.email ?? "null"})');
      return isSignedIn;
    },
    loading: () {
      print('📊 IsSignedIn Provider: Loading - returning false');
      return false;
    },
    error: (error, _) {
      print('❌ IsSignedIn Provider: Error - returning false: $error');
      return false;
    },
  );
});

/// 現在のFirebase Userプロバイダー
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 現在のユーザーデータプロバイダー (Firestore優先)
/// FirestoreのUserDataを取得、存在しない場合はnullを返す（自動作成なし）
final currentUserDataProvider = FutureProvider<UserData?>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final currentUser = ref.watch(currentFirebaseUserProvider); // 認証状態変化を監視

  print('🔄 CurrentUserData Provider: Fetching data for user: ${currentUser?.email ?? "null"}');

  // サインインしていない場合はnullを返す
  if (currentUser == null) {
    print('📊 CurrentUserData Provider: No authenticated user - returning null');
    return null;
  }

  try {
    final userData = await userRepository.getCurrentUser();
    if (userData != null) {
      print('✅ CurrentUserData Provider: User data loaded for ${currentUser.email}: ${userData.username}');
    } else {
      print('ℹ️ CurrentUserData Provider: No Firestore data for authenticated user ${currentUser.email}');
    }
    return userData;
  } catch (e) {
    print('❌ CurrentUserData Provider: Error loading user data for ${currentUser.email}: $e');
    return null;
  }
});

/// ユーザーの初期設定状態を判定するプロバイダー
final userSetupStatusProvider = Provider<UserSetupStatus>((ref) {
  final currentUser = ref.watch(currentFirebaseUserProvider);
  final userDataAsync = ref.watch(currentUserDataProvider);

  if (currentUser == null) {
    return UserSetupStatus.notAuthenticated;
  }

  return userDataAsync.when(
    data: (userData) {
      if (userData != null && userData.isSetupCompleteBasedOnUserId) {
        return UserSetupStatus.setupCompleted;
      } else {
        return UserSetupStatus.needsSetup;
      }
    },
    loading: () => UserSetupStatus.loading,
    error: (error, stack) => UserSetupStatus.error,
  );
});

/// ユーザー設定状態の列挙型
enum UserSetupStatus {
  notAuthenticated, // 未認証
  needsSetup,      // 認証済みだが初期設定が必要
  setupCompleted,  // 設定完了
  loading,         // 読み込み中
  error,           // エラー
}

/// 表示名プロバイダー (Firestore優先)
final displayNameProvider = Provider<String>((ref) {
  final userDataAsync = ref.watch(currentUserDataProvider);
  final currentUser = ref.watch(currentFirebaseUserProvider);

  return userDataAsync.when(
    data: (userData) {
      if (userData != null && userData.username.isNotEmpty) {
        print('📊 DisplayName Provider: Using Firestore username: ${userData.username}');
        return userData.username; // Firestoreデータを優先
      }

      // Firestoreデータがない場合、Firebase Authの表示名を使用
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        print('📊 DisplayName Provider: Using Firebase Auth displayName: ${currentUser.displayName}');
        return currentUser.displayName!;
      }

      print('📊 DisplayName Provider: No user data available - returning guest user');
      return AppStrings.guestUser; // ゲストユーザー
    },
    loading: () {
      // ローディング中でもFirebase Authから表示名を取得
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        print('📊 DisplayName Provider: Loading - using Firebase Auth displayName: ${currentUser.displayName}');
        return currentUser.displayName!;
      }
      print('📊 DisplayName Provider: Loading - no auth data available');
      return AppStrings.guestUser;
    },
    error: (_, __) {
      // エラー時でもFirebase Authから表示名を取得
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        print('📊 DisplayName Provider: Error - using Firebase Auth displayName: ${currentUser.displayName}');
        return currentUser.displayName!;
      }
      print('📊 DisplayName Provider: Error - no auth data available');
      return AppStrings.guestUser;
    },
  );
});

/// プロフィール画像URLプロバイダー (Firestore優先)
final userPhotoUrlProvider = Provider<String?>((ref) {
  final userDataAsync = ref.watch(currentUserDataProvider);
  final currentUser = ref.watch(currentFirebaseUserProvider);

  return userDataAsync.when(
    data: (userData) {
      if (userData?.photoUrl != null && userData!.photoUrl!.isNotEmpty) {
        print('📊 PhotoUrl Provider: Using Firestore photo URL');
        return userData.photoUrl; // Firestoreデータを優先
      }

      // Firestoreにデータがない場合、Firebase Authの写真URLを使用
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        print('📊 PhotoUrl Provider: Using Firebase Auth photo URL');
        return currentUser.photoURL;
      }

      print('📊 PhotoUrl Provider: No photo URL available');
      return null;
    },
    loading: () {
      // ローディング中でもFirebase Authから写真URLを取得
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        print('📊 PhotoUrl Provider: Loading - using Firebase Auth photo URL');
        return currentUser.photoURL;
      }
      return null;
    },
    error: (_, __) {
      // エラー時でもFirebase Authから写真URLを取得
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        print('📊 PhotoUrl Provider: Error - using Firebase Auth photo URL');
        return currentUser.photoURL;
      }
      return null;
    },
  );
});

/// ユーザーバイオプロバイダー (Firestore優先)
final userBioProvider = Provider<String>((ref) {
  final userDataAsync = ref.watch(currentUserDataProvider);

  return userDataAsync.when(
    data: (userData) => userData?.bio ?? '',
    loading: () => '',
    error: (_, __) => '',
  );
});

/// ユーザー連絡先プロバイダー (Firestore優先)
final userContactProvider = Provider<String>((ref) {
  final userDataAsync = ref.watch(currentUserDataProvider);

  return userDataAsync.when(
    data: (userData) => userData?.contact ?? '',
    loading: () => '',
    error: (_, __) => '',
  );
});

/// カスタムユーザーIDプロバイダー (Firestore優先)
final customUserIdProvider = Provider<String>((ref) {
  final userDataAsync = ref.watch(currentUserDataProvider);

  return userDataAsync.when(
    data: (userData) => userData?.userId ?? '',
    loading: () => '',
    error: (_, __) => '',
  );
});

/// 初回設定完了状態プロバイダー (遅延チェック対応)
final userSettingsCompletedProvider = Provider<bool>((ref) {
  final isSignedIn = ref.watch(isSignedInProvider);
  final delayedCheckAsync = ref.watch(delayedInitialSetupCheckProvider);

  // サインインしていない場合は設定完了として扱う
  if (!isSignedIn) {
    print('🔍 UserSettingsCompleted: Not signed in - setup completed');
    return true;
  }

  return delayedCheckAsync.when(
    data: (needsSetup) {
      final isCompleted = !needsSetup;
      print('🔍 UserSettingsCompleted: Delayed check - needs setup: $needsSetup, is completed: $isCompleted');
      return isCompleted; // 初回設定が必要でなければ設定完了
    },
    loading: () {
      print('🔍 UserSettingsCompleted: Loading - assuming completed for safety');
      return true; // ローディング中は設定完了として扱う（慎重なアプローチ）
    },
    error: (error, _) {
      print('❌ UserSettingsCompleted: Error - assuming completed for safety: $error');
      return true; // エラー時も設定完了として扱う（安全側）
    },
  );
});

/// 遅延初回設定チェック用プロバイダー
final delayedInitialSetupCheckProvider = FutureProvider<bool>((ref) async {
  final isSignedIn = ref.watch(isSignedInProvider);
  final currentUser = ref.watch(currentFirebaseUserProvider);

  print('🔍 DelayedSetupCheck: Starting check - isSignedIn: $isSignedIn, user: ${currentUser?.email}');

  // サインインしていない場合は初回設定不要
  if (!isSignedIn || currentUser == null) {
    print('🔍 DelayedSetupCheck: Not signed in or no user - no setup needed');
    return false;
  }

  // 認証状態が安定するまで待機（時間を短縮）
  print('🔍 DelayedSetupCheck: Waiting for Firebase data to stabilize...');
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    final userRepository = ref.read(userRepositoryProvider);
    print('🔍 DelayedSetupCheck: Fetching user data for UID: ${currentUser.uid}');
    final userData = await userRepository.getCurrentUser();

    if (userData == null) {
      print('🔍 DelayedSetupCheck: No user data found after delay - this could be a new user or loading issue');
      print('   - User ID: ${currentUser.uid}');
      print('   - Email: ${currentUser.email}');
      print('   - Attempting retry after additional delay...');

      // さらに短時間待機してリトライ
      await Future.delayed(const Duration(milliseconds: 1000));
      final retryUserData = await userRepository.getCurrentUser();

      if (retryUserData == null) {
        print('🔍 DelayedSetupCheck: Retry also failed - treating as new user needing initial setup');
        print('   - This is likely a genuinely new user or persistent data access issue');
        return true;
      } else {
        print('🔍 DelayedSetupCheck: Retry succeeded - existing user data found');
        final needsSetup = !retryUserData.isSetupCompleteBasedOnUserId;
        print('🔍 DelayedSetupCheck: After retry - user: ${retryUserData.username}, needs setup: $needsSetup');
        return needsSetup;
      }
    }

    final needsSetup = !userData.isSetupCompleteBasedOnUserId;
    print('🔍 DelayedSetupCheck: User data found, isSetupCompleteBasedOnUserId: ${userData.isSetupCompleteBasedOnUserId}, needs setup: $needsSetup');
    print('   - User ID: ${userData.userId}, Username: ${userData.username}');
    return needsSetup;
  } catch (e) {
    print('❌ DelayedSetupCheck: Error checking user data: $e');
    // エラー時は安全のため初回設定不要として扱う
    return false;
  }
});

/// 初回ユーザー設定の必要性をチェックするProvider（遅延チェック対応）
final needsInitialSetupProvider = Provider<bool>((ref) {
  final isSignedIn = ref.watch(isSignedInProvider);
  final delayedCheckAsync = ref.watch(delayedInitialSetupCheckProvider);

  // サインインしていない場合は初回設定不要
  if (!isSignedIn) {
    print('🔍 NeedsInitialSetup: Not signed in - no setup needed');
    return false;
  }

  return delayedCheckAsync.when(
    data: (needsSetup) {
      print('🔍 NeedsInitialSetup: Delayed check completed - needs setup: $needsSetup');
      return needsSetup;
    },
    loading: () {
      print('🔍 NeedsInitialSetup: Delayed check loading - no setup for now');
      return false; // ローディング中は初回設定を表示しない
    },
    error: (error, _) {
      print('❌ NeedsInitialSetup: Delayed check error: $error - no setup for safety');
      return false; // エラー時も初回設定を表示しない
    },
  );
});

/// ユーザーデータの取得状態を監視するProvider
final userDataLoadingStateProvider = Provider<AsyncValue<UserData?>>((ref) {
  return ref.watch(currentUserDataProvider);
});

/// ユーザーデータ更新用NotifierProvider
final userDataNotifierProvider = NotifierProvider<UserDataNotifier, AsyncValue<UserData?>>(() {
  return UserDataNotifier();
});

/// ユーザーデータ更新を管理するNotifier
class UserDataNotifier extends Notifier<AsyncValue<UserData?>> {
  UserRepository? _userRepository;

  @override
  AsyncValue<UserData?> build() {
    _userRepository = ref.read(userRepositoryProvider);
    // 初期状態では currentUserDataProvider の値を使用
    final userDataAsync = ref.watch(currentUserDataProvider);
    return userDataAsync;
  }

  /// ユーザーデータを更新
  Future<void> updateUserData(UpdateUserRequest request) async {
    if (_userRepository == null) return;

    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final updatedUserData = await _userRepository!.updateUser(currentUser.uid, request);
      state = AsyncValue.data(updatedUserData);

      // 他のプロバイダーも更新されるよう、currentUserDataProviderを無効化
      ref.invalidate(currentUserDataProvider);

      print('✅ UserDataNotifier: User data updated successfully');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print('❌ UserDataNotifier: Error updating user data: $e');
    }
  }

  /// 初回セットアップ完了
  Future<void> completeInitialSetup() async {
    if (_userRepository == null) return;

    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) {
      state = AsyncValue.error('ユーザーが認証されていません', StackTrace.current);
      return;
    }

    try {
      final updatedUserData = await _userRepository!.completeInitialSetup(currentUser.uid);
      state = AsyncValue.data(updatedUserData);

      // 他のプロバイダーも更新されるよう、currentUserDataProviderを無効化
      ref.invalidate(currentUserDataProvider);

      print('✅ UserDataNotifier: Initial setup completed');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print('❌ UserDataNotifier: Error completing initial setup: $e');
    }
  }

  /// ユーザーデータを強制リフレッシュ
  Future<void> refresh() async {
    if (_userRepository == null) return;

    state = const AsyncValue.loading();

    try {
      final userData = await _userRepository!.getCurrentUser();
      state = AsyncValue.data(userData);

      // 他のプロバイダーも更新
      ref.invalidate(currentUserDataProvider);

      print('✅ UserDataNotifier: User data refreshed');
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      print('❌ UserDataNotifier: Error refreshing user data: $e');
    }
  }
}