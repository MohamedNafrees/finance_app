import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../widgets/transaction_item.dart';
import '../services/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'transaction_history_screen.dart';
import '../state/transaction_refresh_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.refreshController,
  });

  final TransactionRefreshController refreshController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: refreshController,
        builder: (context, child) => FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getAllTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final transactions = (snapshot.data ?? []).map((map) {
              final category = CategoryModel(
                id: map['categoryId'],
                name: map['categoryName'],
                icon: IconData(map['iconCode'], fontFamily: 'MaterialIcons'),
                color: Color(map['colorValue']),
              );
              return TransactionModel.fromMap(map, category);
            }).toList();

            double totalBalance = 0.0;
            for (var t in transactions) {
              totalBalance += t.isIncome ? t.amount : -t.amount;
            }

            // Compute chart data for the current month
            final now = DateTime.now();
            final currentMonthTransactions = transactions
                .where((t) => t.date.year == now.year && t.date.month == now.month)
                .toList();
            
            Map<int, double> incomeByDay = {};
            Map<int, double> expenseByDay = {};
            
            for (var t in currentMonthTransactions) {
              if (t.isIncome) {
                incomeByDay[t.date.day] = (incomeByDay[t.date.day] ?? 0) + t.amount;
              } else {
                expenseByDay[t.date.day] = (expenseByDay[t.date.day] ?? 0) + t.amount;
              }
            }

            List<FlSpot> incomeSpots = [];
            List<FlSpot> expenseSpots = [];
            
            double maxChartAmt = 1000.0; // minimum scale
            
            // Generate data points for each day up to today
            for (int i = 1; i <= now.day; i++) {
              double inc = incomeByDay[i] ?? 0;
              double exp = expenseByDay[i] ?? 0;
              incomeSpots.add(FlSpot(i.toDouble(), inc));
              expenseSpots.add(FlSpot(i.toDouble(), exp));
              if (inc > maxChartAmt) maxChartAmt = inc;
              if (exp > maxChartAmt) maxChartAmt = exp;
            }

            // Add minor padding to max chart amount
            maxChartAmt *= 1.2;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.iconBackground,
                  child: Icon(Icons.person, color: AppColors.textPrimary),
                ),
                Text(
                  'Finance',
                  style: AppTextStyles.titleLarge,
                ),
                Stack(
                  children: [
                    Icon(Icons.notifications_none, size: 28, color: AppColors.textPrimary),
                    Positioned(
                      right: 2,
                      top: 4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.currency.format(totalBalance),
                    style: AppTextStyles.balanceLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Updated Today',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),

            // Monthly Summary Curve (Mock Chart)
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Summary', style: AppTextStyles.titleMedium),
                      Text('October', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Live fl_chart
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: (incomeSpots.isEmpty && expenseSpots.isEmpty) 
                      ? Center(child: Text("No data for this month", style: TextStyle(color: AppColors.textSecondary)))
                      : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 1,
                        maxX: now.day.toDouble(),
                        minY: 0,
                        maxY: maxChartAmt,
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: AppColors.success,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.success.withValues(alpha: 0.1),
                            ),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: AppColors.error,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.error.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(color: AppColors.success, label: 'Income'),
                      const SizedBox(width: 24),
                      _buildLegendItem(color: AppColors.error, label: 'Expenses'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: AppTextStyles.titleMedium),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                    );
                  },
                  child: const Text('See All', style: TextStyle(color: AppColors.gradientStart)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: transactions.isEmpty 
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No recent transactions')),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length > 5 ? 5 : transactions.length, // Show up to 5
                    separatorBuilder: (context, index) => Divider(height: 24, color: AppColors.iconBackground),
                    itemBuilder: (context, index) {
                      return TransactionItem(transaction: transactions[index]);
                    },
                  ),
            ),
            const SizedBox(height: 80),
          ],
        ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
