import 'package:flutter/material.dart';

class AppSettingsController extends ChangeNotifier {
  static final AppSettingsController instance = AppSettingsController._();

  AppSettingsController._();

  bool _isDarkMode = false;
  String _currencyCode = 'LKR';
  String _currencySymbol = 'LKR ';
  String _currencyLabel = 'LKR (Rs.)';

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get currencyLabel => _currencyLabel;

  void setDarkMode(bool value) {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    notifyListeners();
  }

  void setCurrency({
    required String code,
    required String symbol,
    required String label,
  }) {
    if (_currencyCode == code &&
        _currencySymbol == symbol &&
        _currencyLabel == label) {
      return;
    }
    _currencyCode = code;
    _currencySymbol = symbol;
    _currencyLabel = label;
    notifyListeners();
  }
}
