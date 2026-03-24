import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../widgets/transaction_item.dart';
import '../services/database_helper.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({
    super.key,
    this.categoryId,
    this.title = 'All Transactions',
  });

  final String? categoryId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.titleMedium),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categoryId == null
            ? DatabaseHelper.instance.getAllTransactions()
            : DatabaseHelper.instance.getTransactionsByCategoryId(categoryId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading transactions'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                categoryId == null
                    ? 'No transactions yet'
                    : 'No transactions in this category yet',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          final transactions = snapshot.data!.map((map) {
            final category = CategoryModel(
              id: map['categoryId'],
              name: map['categoryName'],
              icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
              color: Color(map['colorValue']),
            );
            return TransactionModel.fromMap(map, category);
          }).toList();

          final expenses = transactions.where((t) => !t.isIncome).toList();
          final totalExpense = expenses.fold<double>(
            0,
            (sum, transaction) => sum + transaction.amount,
          );
          final averageExpense = expenses.isEmpty ? 0.0 : totalExpense / expenses.length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (categoryId != null) ...[
                _CategorySummaryCard(
                  transactions: transactions,
                  totalExpense: totalExpense,
                  averageExpense: averageExpense,
                ),
                const SizedBox(height: 24),
              ],
              ...List.generate(transactions.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: index == transactions.length - 1 ? 0 : 24),
                  child: Column(
                    children: [
                      TransactionItem(
                        transaction: transactions[index],
                        showNotes: true,
                      ),
                      if (index != transactions.length - 1)
                        Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: Divider(height: 1, color: AppColors.iconBackground),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  const _CategorySummaryCard({
    required this.transactions,
    required this.totalExpense,
    required this.averageExpense,
  });

  final List<TransactionModel> transactions;
  final double totalExpense;
  final double averageExpense;

  @override
  Widget build(BuildContext context) {
    final groupedExpenses = <String, double>{};
    final expenseTransactions = transactions.where((t) => !t.isIncome);
    for (final transaction in expenseTransactions) {
      groupedExpenses[transaction.title] =
          (groupedExpenses[transaction.title] ?? 0.0) + transaction.amount;
    }

    final expenseEntries = groupedExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = <Color>[
      AppColors.error,
      AppColors.gradientStart,
      AppColors.catFood,
      AppColors.catTransport,
      AppColors.catEntertainment,
      AppColors.catShopping,
      AppColors.success,
      AppColors.catHousing,
    ];

    final sections = expenseEntries.isEmpty
        ? [
            PieChartSectionData(
              value: 1,
              color: AppColors.iconBackground,
              radius: 42,
              title: '0%',
              titleStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ]
        : List.generate(expenseEntries.length, (index) {
            final entry = expenseEntries[index];
            final percentage = totalExpense == 0
                ? 0
                : ((entry.value / totalExpense) * 100).round();
            return PieChartSectionData(
              value: entry.value,
              color: chartColors[index % chartColors.length],
              radius: 42,
              title: '${percentage}%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            );
          });

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
          Text('Category Overview', style: AppTextStyles.titleMedium),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total spent', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency.format(totalExpense),
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Average expense',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency.format(averageExpense),
                      style: AppTextStyles.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (expenseEntries.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.iconBackground),
            const SizedBox(height: 16),
            ...List.generate(expenseEntries.length, (index) {
              final entry = expenseEntries[index];
              final color = chartColors[index % chartColors.length];
              final percentage = totalExpense == 0
                  ? 0.0
                  : (entry.value / totalExpense) * 100;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == expenseEntries.length - 1 ? 0 : 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Formatters.currency.format(entry.value),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
