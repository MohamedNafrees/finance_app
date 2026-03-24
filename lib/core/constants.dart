import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_settings_controller.dart';

class AppColors {
  // Gradients
  static const Color gradientStart = Color(0xFF6A9DF0);
  static const Color gradientEnd = Color(0xFF7CD2A4);

  // Base
  static bool get _isDarkMode => AppSettingsController.instance.isDarkMode;
  static Color get background =>
      _isDarkMode ? const Color(0xFF11161D) : const Color(0xFFF3F7FA);
  static Color get cardBackground =>
      _isDarkMode ? const Color(0xFF1B2430) : Colors.white;
  static Color get textPrimary =>
      _isDarkMode ? const Color(0xFFF3F7FA) : const Color(0xFF2B3A4A);
  static Color get textSecondary =>
      _isDarkMode ? const Color(0xFF9FB0C2) : const Color(0xFF8C9BAA);

  // Elements
  static const Color success = Color(0xFF7CD2A4);
  static const Color error = Color(0xFFF28B82);
  static Color get iconBackground =>
      _isDarkMode ? const Color(0xFF253244) : const Color(0xFFE8F1F8);

  // Categories
  static const Color catFood = Color(0xFFF6A055);
  static const Color catTransport = Color(0xFF5A8DF4);
  static const Color catHousing = Color(0xFFAD52D3);
  static const Color catShopping = Color(0xFFF35F92);
  static const Color catEntertainment = Color(0xFF5AC68B);
}

class AppTextStyles {
  static TextStyle get titleLarge => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleMedium => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get titleSmall => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyMedium => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static TextStyle get bodySmall => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle balanceLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}

class Formatters {
  static NumberFormat get currency => NumberFormat.currency(
        symbol: AppSettingsController.instance.currencySymbol,
        decimalDigits: 2,
      );
  static final DateFormat dateDay = DateFormat('MMM dd');
  static final DateFormat dateMonth = DateFormat('MMMM');
}
