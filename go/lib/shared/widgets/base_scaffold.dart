import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// ベースScaffoldウィジェット
/// アプリ全体で統一されたScaffoldレイアウトを提供
class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundWhite,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        actions: actions,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.border,
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }
}