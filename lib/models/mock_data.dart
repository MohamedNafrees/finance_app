import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'models.dart';

class MockData {
  static final List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat_food',
      name: 'Food',
      icon: Icons.restaurant,
      color: AppColors.catFood,
    ),
    CategoryModel(
      id: 'cat_transport',
      name: 'Transport',
      icon: Icons.directions_car,
      color: AppColors.catTransport,
    ),
    CategoryModel(
      id: 'cat_entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: AppColors.catEntertainment,
    ),
    CategoryModel(
      id: 'cat_bills',
      name: 'Bills',
      icon: Icons.receipt_long,
      color: AppColors.catHousing,
    ),
    CategoryModel(
      id: 'cat_shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: AppColors.catShopping,
    ),
  ];

  static CategoryModel getCategoryByName(String name) {
    return categories.firstWhere((c) => c.name == name);
  }

  static final List<TransactionModel> recentTransactions = [];

  static final List<BudgetModel> budgets = [
    BudgetModel(category: getCategoryByName('Food'), limit: 500.0, spent: 0.0),
    BudgetModel(category: getCategoryByName('Transport'), limit: 300.0, spent: 0.0),
    BudgetModel(category: getCategoryByName('Entertainment'), limit: 250.0, spent: 0.0),
    BudgetModel(category: getCategoryByName('Bills'), limit: 800.0, spent: 0.0),
    BudgetModel(category: getCategoryByName('Shopping'), limit: 400.0, spent: 0.0),
  ];
}
