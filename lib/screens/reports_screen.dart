import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTabIndex = 0; // 0: Week, 1: Month, 2: Year

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Financial Analytics Reports',
          style: AppTextStyles.titleMedium,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DatabaseHelper.instance.getAllTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reports',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          final transactions = (snapshot.data ?? []).map((map) {
            final category = CategoryModel(
              id: map['categoryId'],
              name: map['categoryName'],
              icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
              color: Color(map['colorValue']),
              budgetLimit: (map['budgetLimit'] as num?)?.toDouble() ?? 0.0,
            );
            return TransactionModel.fromMap(map, category);
          }).toList();

          final filteredExpenses = _filterTransactions(transactions)
              .where((transaction) => !transaction.isIncome)
              .toList();

          final groupedByCategory = <String, _CategorySpend>{};
          for (final transaction in filteredExpenses) {
            final categoryId = transaction.category.id;
            final existing = groupedByCategory[categoryId];
            if (existing == null) {
              groupedByCategory[categoryId] = _CategorySpend(
                category: transaction.category,
                amount: transaction.amount,
              );
            } else {
              groupedByCategory[categoryId] = existing.copyWith(
                amount: existing.amount + transaction.amount,
              );
            }
          }

          final categorySpends = groupedByCategory.values.toList()
            ..sort((a, b) => b.amount.compareTo(a.amount));

          final totalSpent = categorySpends.fold<double>(
            0,
            (sum, spend) => sum + spend.amount,
          );

          final trendValues = _buildTrendValues(filteredExpenses);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTab(0, 'Week'),
                      _buildTab(1, 'Month'),
                      _buildTab(2, 'Year'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSpendingCard(
                  categorySpends: categorySpends,
                  totalSpent: totalSpent,
                ),
                const SizedBox(height: 24),
                _buildTrendCard(trendValues: trendValues),
              ],
            ),
          );
        },
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    final now = DateTime.now();

    bool inRange(DateTime date) {
      switch (_selectedTabIndex) {
        case 0:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final weekStart = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          final weekEnd = weekStart.add(const Duration(days: 7));
          return !date.isBefore(weekStart) && date.isBefore(weekEnd);
        case 1:
          return date.year == now.year && date.month == now.month;
        case 2:
          return date.year == now.year;
        default:
          return true;
      }
    }

    return transactions.where((transaction) => inRange(transaction.date)).toList();
  }

  List<double> _buildTrendValues(List<TransactionModel> expenses) {
    switch (_selectedTabIndex) {
      case 0:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return List.generate(7, (index) {
          final day = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day + index,
          );
          return expenses
              .where((expense) =>
                  expense.date.year == day.year &&
                  expense.date.month == day.month &&
                  expense.date.day == day.day)
              .fold<double>(0, (sum, expense) => sum + expense.amount);
        });
      case 1:
        final now = DateTime.now();
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        return List.generate(daysInMonth, (index) {
          final day = index + 1;
          return expenses
              .where((expense) =>
                  expense.date.year == now.year &&
                  expense.date.month == now.month &&
                  expense.date.day == day)
              .fold<double>(0, (sum, expense) => sum + expense.amount);
        });
      case 2:
        final now = DateTime.now();
        return List.generate(12, (index) {
          final month = index + 1;
          return expenses
              .where((expense) =>
                  expense.date.year == now.year && expense.date.month == month)
              .fold<double>(0, (sum, expense) => sum + expense.amount);
        });
      default:
        return const [];
    }
  }

  Widget _buildTab(int index, String text) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingCard({
    required List<_CategorySpend> categorySpends,
    required double totalSpent,
  }) {
    final sections = categorySpends.isEmpty
        ? [
            PieChartSectionData(
              value: 1,
              color: AppColors.iconBackground,
              radius: 46,
              title: '0%',
              titleStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ]
        : categorySpends.map((spend) {
            final percentage = totalSpent == 0
                ? 0
                : ((spend.amount / totalSpent) * 100).round();
            return PieChartSectionData(
              value: spend.amount,
              color: spend.category.color,
              radius: 46,
              title: '$percentage%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            );
          }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending by Category', style: AppTextStyles.titleMedium),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 190,
              width: 190,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 46,
                  sections: sections,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text('Total Spent', style: AppTextStyles.bodySmall),
              const SizedBox(height: 4),
              Text(
                Formatters.currency.format(totalSpent),
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (categorySpends.isEmpty)
            Text(
              'No expense data for this period',
              style: AppTextStyles.bodyMedium,
            )
          else
            Column(
              children: categorySpends.map((spend) {
                final percentage = totalSpent == 0
                    ? 0.0
                    : (spend.amount / totalSpent) * 100;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: spend.category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spend.category.name,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Text(
                        Formatters.currency.format(spend.amount),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: AppTextStyles.titleSmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendCard({required List<double> trendValues}) {
    final spots = <FlSpot>[];
    var maxY = 1000.0;
    for (var i = 0; i < trendValues.length; i++) {
      final value = trendValues[i];
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) {
        maxY = value;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense Trend', style: AppTextStyles.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: spots.every((spot) => spot.y == 0)
                ? Center(
                    child: Text(
                      'No expense trend data for this period',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.isEmpty ? 0 : (spots.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY * 1.2,
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.gradientStart,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.gradientStart.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpend {
  const _CategorySpend({
    required this.category,
    required this.amount,
  });

  final CategoryModel category;
  final double amount;

  _CategorySpend copyWith({
    CategoryModel? category,
    double? amount,
  }) {
    return _CategorySpend(
      category: category ?? this.category,
      amount: amount ?? this.amount,
    );
  }
}
