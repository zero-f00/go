import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game_event_management/views/game_event_management_screen.dart';
import '../../search/views/search_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../../management/views/management_screen.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/push_notification_service.dart';
import '../../../shared/services/navigation_service.dart';
import '../../../data/models/notification_model.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  // 前回の通知リストを保持（新着通知検出用）
  List<String> _previousNotificationIds = [];
  bool _isFirstLoad = true;

  // フラグはフィールドとして先に定義
  bool _shouldNavigateToEventCreation = false;
  bool _shouldFocusSearchField = false;

  // タブ画面のインスタンスを保持（IndexedStackで状態保持するため）
  // 注意: SearchScreenとManagementScreenのフラグは初期化時の値が渡されるため、
  // 動的な変更には対応していない。これらの画面は内部でフラグをチェックする必要がある場合は
  // コールバックやProviderを使用する。
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // NavigationServiceにタブ切り替えコールバックを設定
    NavigationService.instance.setTabChangeCallback(_onTabTapped);

    // 画面インスタンスを初期化時に一度だけ生成
    _screens = [
      GameEventManagementScreen(
        onNavigateToSearch: () => _navigateToSearch(),
        onNavigateToEventCreation: () => _navigateToEventCreation(),
      ),
      SearchScreen(
        shouldFocusSearchField: _shouldFocusSearchField,
      ),
      const NotificationScreen(),
      ManagementScreen(
        shouldNavigateToEventCreation: _shouldNavigateToEventCreation,
        onEventCreationNavigated: () => _shouldNavigateToEventCreation = false,
      ),
    ];
  }

  void _navigateToEventCreation() {
    setState(() {
      _shouldNavigateToEventCreation = true;
      _currentIndex = 3; // 管理タブ (index: 3) に移動
    });
  }

  void _navigateToSearch() {
    setState(() {
      _shouldFocusSearchField = true;
      _currentIndex = 1; // 検索タブ (index: 1) に移動
    });
    // フォーカスフラグをリセットするための遅延処理
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _shouldFocusSearchField = false;
        });
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    // NavigationServiceのコールバックをクリア
    NavigationService.instance.clearTabChangeCallback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 通知の変更を監視して、新しい通知が来たらローカル通知を表示
    ref.listen<AsyncValue<List<NotificationData>>>(
      userNotificationsProvider,
      (previous, next) {
        next.whenData((notifications) {
          _handleNewNotifications(notifications);
        });
      },
    );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  /// 新しい通知を検出してローカル通知を表示
  void _handleNewNotifications(List<NotificationData> notifications) {
    if (notifications.isEmpty) {
      _previousNotificationIds = [];
      _isFirstLoad = false;
      return;
    }

    final currentIds = notifications.map((n) => n.id).whereType<String>().toList();

    // 初回ロード時は通知リストを初期化するだけ
    if (_isFirstLoad) {
      _previousNotificationIds = currentIds;
      _isFirstLoad = false;
      return;
    }

    // 新しい通知を検出（現在のリストにあるが、前回のリストにないもの）
    final newNotifications = notifications.where((n) {
      final id = n.id;
      return id != null && !_previousNotificationIds.contains(id);
    }).toList();

    // 未読の新しい通知のみバナーで表示
    for (final notification in newNotifications) {
      if (!notification.isRead) {
        _showLocalNotificationBanner(notification);
      }
    }

    // 通知リストを更新
    _previousNotificationIds = currentIds;
  }

  /// ローカル通知バナーを表示
  Future<void> _showLocalNotificationBanner(NotificationData notification) async {
    try {
      final pushService = PushNotificationService.instance;
      if (pushService.isInitialized) {
        await pushService.showTestLocalNotification(
          title: notification.title,
          body: notification.message,
          data: {
            'type': notification.type.name,
            'notificationId': notification.id,
            ...?notification.data,
          },
        );
      }
    } catch (e) {
      // ローカル通知表示エラー
    }
  }
}