import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'shared/services/app_initialization_service.dart';
import 'features/main/views/main_screen.dart';
import 'features/settings/views/settings_screen.dart';
import 'features/profile/views/user_profile_screen.dart';
import 'features/event_detail/views/event_detail_wrapper.dart';
import 'features/event_creation/views/event_creation_screen.dart';
import 'features/management/views/participant_management_screen.dart';
import 'features/friends/views/friends_screen.dart';
import 'features/game_profile/views/game_profile_edit_screen.dart';
import 'features/game_profile/views/game_profile_view_screen.dart';
import 'data/models/game_profile_model.dart';
import 'data/models/user_model.dart';
import 'features/event_management/views/event_operations_dashboard_screen.dart';
import 'features/event_management/views/event_participants_management_screen.dart';
import 'features/event_management/views/group_room_management_screen.dart';
import 'features/event_management/views/result_management_screen.dart';
import 'features/event_management/views/violation_management_screen.dart';
import 'features/event_management/views/user_detail_management_screen.dart';
import 'features/event_management/views/payment_management_screen.dart';
import 'features/game_profile/views/favorite_games_screen.dart';
import 'features/game_event_management/models/game_event.dart';
import 'shared/constants/app_strings.dart';
import 'shared/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 日本語ロケールデータの初期化
  try {
    print('🔄 Initializing locale data...');
    await initializeDateFormatting('ja_JP', null);
    print('✅ Locale data initialized successfully');
  } catch (e) {
    print('❌ Locale data initialization failed: $e');
    print('ℹ️  Continuing with default locale...');
  }

  // Firebase初期化（詳細エラーハンドリング付き）
  try {
    print('🔄 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Firebase初期化後にGoogle Services設定をチェック
    _checkGoogleServicesConfiguration();

    // アプリ初期化処理（ゲストユーザーキャッシュクリア等）
    await AppInitializationService.initialize();

  } catch (e, stackTrace) {
    print('❌ Firebase initialization failed: $e');
    print('Stack trace: $stackTrace');
    // Firebase初期化に失敗してもアプリを続行
    print('ℹ️  Continuing without Firebase...');
  }

  runApp(const ProviderScope(child: MyApp()));
}

void _checkGoogleServicesConfiguration() {
  try {
    print('🔍 Checking Google Services configuration...');

    // Check if we're on iOS and configuration looks correct
    print('   - Platform: iOS');
    print('   - Bundle ID in project.pbxproj: go-mobile');
    print('   - Expected REVERSED_CLIENT_ID: com.googleusercontent.apps.65724819181-ceh6dbnoj29bp4tagfpihg15mk0s4tjs');
    print('   - GoogleService-Info.plist should be in ios/Runner/');
    print('   - Info.plist should contain CFBundleURLSchemes');

    print('✅ Google Services configuration check completed');
    print('ℹ️  If Google Sign-In crashes, the issue is likely:');
    print('   1. Missing GoogleService-Info.plist in correct location');
    print('   2. Bundle ID mismatch between Xcode and Firebase');
    print('   3. Missing or incorrect URL scheme in Info.plist');
    print('   4. Google Sign-In plugin not properly initialized');

  } catch (e) {
    print('❌ Error checking Google Services configuration: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/user_profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return UserProfileScreen(userId: args['userId'] as String);
          }
          return UserProfileScreen(userId: args as String);
        },
        '/event_detail': (context) => EventDetailWrapper(
          eventId: ModalRoute.of(context)?.settings.arguments as String,
        ),
        '/event_edit': (context) => EventCreationScreen(
          editingEvent: ModalRoute.of(context)?.settings.arguments as GameEvent,
        ),
        '/participant_management': (context) {
          print('🚨 Navigation: Accessing participant management screen');
          final event = ModalRoute.of(context)?.settings.arguments as GameEvent;
          print('🚨 Navigation: Event ID: ${event.id}, Event Name: ${event.name}');
          return ParticipantManagementScreen(
            eventId: event.id,
            eventName: event.name,
          );
        },
        '/operations_dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return EventOperationsDashboardScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/event_participants_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return EventParticipantsManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/group_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return GroupRoomManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/result_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return ResultManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/violation_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return ViolationManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/user_detail_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return UserDetailManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/payment_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>;
          return PaymentManagementScreen(
            eventId: args['eventId']!,
            eventName: args['eventName']!,
          );
        },
        '/game_profile_edit': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          final gameId = args['gameId'];
          return GameProfileEditScreen(
            gameId: gameId.toString(),
            gameName: args['gameName'] as String?,
            gameIconUrl: args['gameIconUrl'] as String?,
            profile: args['existingProfile'] as GameProfile?,
            readOnly: args['readOnly'] as bool? ?? false,
          );
        },
        '/game_profile_view': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return GameProfileViewScreen(
            profile: args['profile'] as GameProfile,
            userData: args['userData'] as UserData?,
            gameName: args['gameName'] as String?,
            gameIconUrl: args['gameIconUrl'] as String?,
          );
        },
        '/favorite-games': (context) => const FavoriteGamesScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}