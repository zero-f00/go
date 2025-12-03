import 'package:flutter/material.dart';
import '../../game_event_management/views/game_event_management_screen.dart';
import '../../search/views/search_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../../management/views/management_screen.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
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

  bool _shouldNavigateToEventCreation = false;
  bool _shouldFocusSearchField = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}