import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'features/game_profile/views/game_profile_view_wrapper.dart';
import 'data/models/game_profile_model.dart';
import 'data/models/user_model.dart';
import 'features/event_management/views/event_operations_dashboard_screen.dart';
import 'features/event_management/views/group_room_management_screen.dart';
import 'features/event_management/views/result_management_screen.dart';
import 'features/event_management/views/violation_management_screen.dart';
import 'features/event_management/views/user_detail_management_screen.dart';
import 'features/event_management/views/payment_management_screen.dart';
import 'features/game_profile/views/favorite_games_screen.dart';
import 'features/game_event_management/models/game_event.dart';
import 'features/calendar/views/event_calendar_screen.dart';
import 'features/event_participant/views/participant_group_view_screen.dart';
import 'features/event_participant/views/participant_list_view_screen.dart';
import 'features/event_participant/views/violation_report_screen.dart';
import 'shared/services/participation_service.dart';
import 'shared/constants/app_strings.dart';
import 'shared/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面方向を縦画面のみに固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 日本語ロケールデータの初期化
  try {
    await initializeDateFormatting('ja_JP', null);
  } catch (e) {
    // エラーは無視して続行
  }

  // Firebase初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // アプリ初期化処理（ゲストユーザーキャッシュクリア等）
    await AppInitializationService.initialize();

  } catch (e, stackTrace) {
    // Firebase初期化に失敗してもアプリを続行
  }

  runApp(const ProviderScope(child: MyApp()));
}

// Google Services設定チェックメソッドを削除

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
      // TODO: 多言語化は見送り、日本語固定で実装
      locale: const Locale('ja', 'JP'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
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
          final event = ModalRoute.of(context)?.settings.arguments as GameEvent;
          return ParticipantManagementScreen(
            eventId: event.id,
            eventName: event.name,
          );
        },
        '/operations_dashboard': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return EventOperationsDashboardScreen(
            eventId: args['eventId']! as String,
            eventName: args['eventName']! as String,
            fromParticipantManagement: args['fromParticipantManagement'] as bool? ?? false,
          );
        },
        '/event_participants_management': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return ParticipantManagementScreen(
            eventId: args['eventId']! as String,
            eventName: args['eventName']! as String,
            fromNotification: args['fromNotification'] as bool? ?? false,
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
          );
        },
        '/game_profile_view': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          // 既存のGameProfileオブジェクトがある場合は直接表示
          if (args.containsKey('profile')) {
            return GameProfileViewScreen(
              profile: args['profile'] as GameProfile,
              userData: args['userData'] as UserData?,
              gameName: args['gameName'] as String?,
              gameIconUrl: args['gameIconUrl'] as String?,
            );
          }
          // userIdとgameIdがある場合はラッパーを使用
          else if (args.containsKey('userId') && args.containsKey('gameId')) {
            return GameProfileViewWrapper(
              userId: args['userId'] as String,
              gameId: args['gameId'] as String,
            );
          }
          // パラメータが不正な場合はエラー画面へ戻る
          else {
            Navigator.of(context).pop();
            return const SizedBox.shrink();
          }
        },
        '/favorite-games': (context) => const FavoriteGamesScreen(),
        '/event_calendar': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return EventCalendarScreen(
            applications: args['applications'] as List<ParticipationApplication>,
          );
        },
        '/participant_group_view': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return ParticipantGroupViewScreen(
            eventId: args['eventId']! as String,
            eventName: args['eventName']! as String,
          );
        },
        '/participant_list_view': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return ParticipantListViewScreen(
            eventId: args['eventId']! as String,
            eventName: args['eventName']! as String,
          );
        },
        '/violation_report': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return ViolationReportScreen(
            eventId: args['eventId']! as String,
            eventName: args['eventName']! as String,
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}