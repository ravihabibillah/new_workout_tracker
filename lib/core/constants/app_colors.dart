import 'package:flutter/material.dart';

/// App color constants following the minimalist sports dark theme
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFE8FF00); // Electric yellow
  static const Color primaryDark = Color(0xFFB8CC00);
  static const Color primaryLight = Color(0xFFF4FF66);

  // Background Colors
  static const Color background = Color(0xFF0F0F0F); // Near black
  static const Color surface = Color(0xFF1A1A1A); // Card background
  static const Color surfaceSecondary = Color(0xFF242424);
  static const Color surfaceTertiary = Color(0xFF2E2E2E);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textTertiary = Color(0xFF666666);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Functional Colors
  static const Color divider = Color(0xFF333333);
  static const Color disabled = Color(0xFF555555);
  static const Color overlay = Color(0x80000000);

  // Chart Colors
  static const Color chartPrimary = primary;
  static const Color chartSecondary = Color(0xFF00E5FF);
  static const Color chartTertiary = Color(0xFFFF6B6B);
  static const Color chartBackground = Color(0x1AE8FF00);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceSecondary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
