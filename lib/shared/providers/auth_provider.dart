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
    } else {
      // ログアウト時に全てのローカルキャッシュをクリア
      await _clearAllLocalData();
    }
    return user;
  }).asyncMap((futureUser) async => await futureUser);
});

/// ログアウト時のローカルデータクリア
Future<void> _clearAllLocalData() async {
  try {

    // UserServiceのキャッシュクリア
    await UserService.instance.clearAllUserData();

    // TODO: 他のサービスのキャッシュクリアも追加
    // - SharedPreferences の他のキー
    // - Hive/SQLite等の他のローカルDB
    // - 画像キャッシュ等

  } catch (e) {
  }
}

/// サインイン状態プロバイダー
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      final isSignedIn = user != null;
      return isSignedIn;
    },
    loading: () {
      return false;
    },
    error: (error, _) {
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


  // サインインしていない場合はnullを返す
  if (currentUser == null) {
    return null;
  }

  try {
    final userData = await userRepository.getCurrentUser();
    if (userData != null) {
    } else {
    }
    return userData;
  } catch (e) {
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
        return userData.username; // Firestoreデータを優先
      }

      // Firestoreデータがない場合、Firebase Authの表示名を使用
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        return currentUser.displayName!;
      }

      return AppStrings.guestUser; // ゲストユーザー
    },
    loading: () {
      // ローディング中でもFirebase Authから表示名を取得
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        return currentUser.displayName!;
      }
      return AppStrings.guestUser;
    },
    error: (_, __) {
      // エラー時でもFirebase Authから表示名を取得
      if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
        return currentUser.displayName!;
      }
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
        return userData.photoUrl; // Firestoreデータを優先
      }

      // Firestoreにデータがない場合、Firebase Authの写真URLを使用
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        return currentUser.photoURL;
      }

      return null;
    },
    loading: () {
      // ローディング中でもFirebase Authから写真URLを取得
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        return currentUser.photoURL;
      }
      return null;
    },
    error: (_, __) {
      // エラー時でもFirebase Authから写真URLを取得
      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
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
    return true;
  }

  return delayedCheckAsync.when(
    data: (needsSetup) {
      final isCompleted = !needsSetup;
      return isCompleted; // 初回設定が必要でなければ設定完了
    },
    loading: () {
      return true; // ローディング中は設定完了として扱う（慎重なアプローチ）
    },
    error: (error, _) {
      return true; // エラー時も設定完了として扱う（安全側）
    },
  );
});

/// 遅延初回設定チェック用プロバイダー
final delayedInitialSetupCheckProvider = FutureProvider<bool>((ref) async {
  final isSignedIn = ref.watch(isSignedInProvider);
  final currentUser = ref.watch(currentFirebaseUserProvider);


  // サインインしていない場合は初回設定不要
  if (!isSignedIn || currentUser == null) {
    return false;
  }

  // 認証状態が安定するまで待機（時間を短縮）
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    final userRepository = ref.read(userRepositoryProvider);
    final userData = await userRepository.getCurrentUser();

    if (userData == null) {

      // さらに短時間待機してリトライ
      await Future.delayed(const Duration(milliseconds: 1000));
      final retryUserData = await userRepository.getCurrentUser();

      if (retryUserData == null) {
        return true;
      } else {
        final needsSetup = !retryUserData.isSetupCompleteBasedOnUserId;
        return needsSetup;
      }
    }

    final needsSetup = !userData.isSetupCompleteBasedOnUserId;
    return needsSetup;
  } catch (e) {
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
    return false;
  }

  return delayedCheckAsync.when(
    data: (needsSetup) {
      return needsSetup;
    },
    loading: () {
      return false; // ローディング中は初回設定を表示しない
    },
    error: (error, _) {
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

    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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

    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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

    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}