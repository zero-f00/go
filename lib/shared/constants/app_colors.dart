import 'package:flutter/material.dart';

/// アプリ全体で使用する色の定数クラス
/// ハードコーディングを避けるため、すべての色はここで一元管理
class AppColors {
  // プライマリカラー
  static const Color primary = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // セカンダリカラー
  static const Color secondary = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFFB45309);

  // 背景色
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFFF3F4F6);

  // テキストカラー
  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);

  // サポートカラー
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF5722);
  static const Color info = Color(0xFF4A90E2);

  // ボーダー・ディバイダー
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // シャドウカラー
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);

  // ボタン関連
  static const Color buttonDisabled = Color(0xFFD1D5DB);
  static const Color buttonHover = Color(0xFF1D4ED8);

  // カード・サーフェス
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF9FAFB);

  // グラデーション用色
  static const Color gradientStart = Color(0xFF1E40AF);
  static const Color gradientEnd = Color(0xFF6B7280);

  // Primary gradient colors
  static const Color primaryGradientStart = Color(0xFF4A90E2);
  static const Color primaryGradientMiddle = Color(0xFF357ABD);
  static const Color primaryGradientEnd = Color(0xFF2E5984);

  // Accent colors
  static const Color accent = Color(0xFFD2691E);
  static const Color accentLight = Color(0xFFE67E22);

  // Status colors
  static const Color statusUpcoming = Color(0xFF4A90E2);
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusCompleted = Color(0xFF9C27B0);
  static const Color statusExpired = Color(0xFF757575);

  // Text colors
  static const Color textOnPrimary = textWhite;
  static const Color textDark = Color(0xFF2D4A22);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Background colors
  static const Color backgroundWhite = background;
  static const Color backgroundTransparent = Colors.transparent;

  // Overlay colors
  static const Color overlayLight = Color(0x33FFFFFF);
  static const Color overlayMedium = Color(0x66FFFFFF);
  static const Color overlayDark = shadow;

  // Component specific colors
  static const Color cardShadow = shadow;
  static const Color surface = Color(0xFFFFFFFF);

  // コンストラクタを private にして、インスタンス化を防ぐ
  AppColors._();
}
