import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const AppGradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? [
            AppColors.primaryGradientStart,
            AppColors.primaryGradientMiddle,
            AppColors.primaryGradientEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}