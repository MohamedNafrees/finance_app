import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/database_helper.dart';

class BudgetController extends ChangeNotifier {
  BudgetController({required DatabaseHelper databaseHelper})
      : _databaseHelper = databaseHelper;

  final DatabaseHelper _databaseHelper;

  bool _isLoading = true;
  bool _hasLoaded = false;
  bool _isDisposed = false;
  bool _notificationQueued = false;
  List<BudgetModel> _budgets = const [];

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);

  IconData iconForCategoryName(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('food') || normalized.contains('restaurant')) {
      return Icons.restaurant;
    }
    if (normalized.contains('shop') || normalized.contains('store')) {
      return Icons.shopping_bag;
    }
    if (normalized.contains('car') ||
        normalized.contains('travel') ||
        normalized.contains('transport')) {
      return Icons.directions_car;
    }
    if (normalized.contains('home') ||
        normalized.contains('rent') ||
        normalized.contains('house')) {
      return Icons.home;
    }
    if (normalized.contains('movie') ||
        normalized.contains('game') ||
        normalized.contains('fun')) {
      return Icons.movie;
    }
    if (normalized.contains('health') || normalized.contains('medical')) {
      return Icons.medical_services;
    }
    if (normalized.contains('pet')) {
      return Icons.pets;
    }
    if (normalized.contains('gym') ||
        normalized.contains('fitness') ||
        normalized.contains('sport')) {
      return Icons.fitness_center;
    }
    if (normalized.contains('school') ||
        normalized.contains('study') ||
        normalized.contains('book')) {
      return Icons.school;
    }
    if (normalized.contains('work') || normalized.contains('office')) {
      return Icons.work;
    }

    return Icons.category;
  }

  Future<CategoryModel> createCategory({
    required String name,
    required double budgetLimit,
    required Color color,
    IconData? icon,
  }) async {
    final category = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon ?? iconForCategoryName(name),
      color: color,
      budgetLimit: budgetLimit,
    );

    await _databaseHelper.insertCategory(category.toMap());
    return category;
  }

  Future<void> loadBudgets() async {
    _setLoading(true);

    final results = await Future.wait([
      _databaseHelper.getAllTransactions(),
      _databaseHelper.getAllCategories(),
    ]);

    final transactions = results[0];
    final categories = results[1];

    final expensesByCategory = <String, double>{};
    for (final transaction in transactions) {
      if (transaction['isIncome'] == 0) {
        final categoryId = transaction['categoryId'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        expensesByCategory[categoryId] =
            (expensesByCategory[categoryId] ?? 0.0) + amount;
      }
    }

    _budgets = categories
        .map((map) => CategoryModel.fromMap(map))
        .where((category) => category.id != 'inc_salary')
        .map(
          (category) => BudgetModel(
            category: category,
            limit: category.budgetLimit,
            spent: expensesByCategory[category.id] ?? 0.0,
          ),
        )
        .toList();

    _hasLoaded = true;
    _setLoading(false);
  }

  Future<void> saveBudgetLimits(List<BudgetModel> budgets) async {
    for (final budget in budgets) {
      await _databaseHelper.updateCategoryBudget(
        budget.category.id,
        budget.limit,
      );
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifySafely();
  }

  void _notifySafely() {
    if (_isDisposed || _notificationQueued) {
      return;
    }

    _notificationQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationQueued = false;
      if (_isDisposed) {
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
