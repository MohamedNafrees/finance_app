import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double budgetLimit;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budgetLimit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': icon.codePoint,
      'colorValue': color.value,
      'budgetLimit': budgetLimit,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
      color: Color(map['colorValue']),
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final String? notes;
  final DateTime date;
  final double amount;
  final CategoryModel category;
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.title,
    this.notes,
    required this.date,
    required this.amount,
    required this.category,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'date': date.toIso8601String(),
      'amount': amount,
      'categoryId': category.id,
      'isIncome': isIncome ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, CategoryModel category) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      notes: map['notes'] as String?,
      date: DateTime.parse(map['date']),
      amount: map['amount'],
      category: category,
      isIncome: (map['isIncome'] as int) == 1,
    );
  }
}

class BudgetModel {
  final CategoryModel category;
  final double limit;
  double spent;

  BudgetModel({
    required this.category,
    required this.limit,
    this.spent = 0.0,
  });

  double get remaining => limit - spent;
  double get percentageUsed => limit > 0 ? spent / limit : 0.0;
}
