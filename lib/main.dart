import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'screens/main_scaffold.dart';

import 'services/database_helper.dart';
import 'state/budget_scope.dart';
import 'state/app_settings_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const FinanceApp());
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key});

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  late final BudgetController _budgetController;
  final AppSettingsController _settingsController =
      AppSettingsController.instance;

  @override
  void initState() {
    super.initState();
    _budgetController = BudgetController(
      databaseHelper: DatabaseHelper.instance,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _budgetController.loadBudgets();
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, child) => MaterialApp(
        title: 'Finance App',
        debugShowCheckedModeBanner: false,
        themeMode: _settingsController.themeMode,
        theme: ThemeData(
          fontFamily: 'Inter',
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.gradientStart,
            brightness: Brightness.light,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        darkTheme: ThemeData(
          fontFamily: 'Inter',
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.gradientStart,
            brightness: Brightness.dark,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: MainScaffold(budgetController: _budgetController),
      ),
    );
  }
}
