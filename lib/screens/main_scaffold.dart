import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/constants.dart';
import 'dashboard_screen.dart';
import 'categories_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'add_expense_screen.dart';
import '../state/budget_scope.dart';
import '../state/transaction_refresh_controller.dart';


class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, required this.budgetController});

  final BudgetController budgetController;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  late final TransactionRefreshController _transactionRefreshController;

  @override
  void initState() {
    super.initState();
    _transactionRefreshController = TransactionRefreshController();
  }

  @override
  void dispose() {
    _transactionRefreshController.dispose();
    super.dispose();
  }

  late final List<Widget> _pages = [
    DashboardScreen(refreshController: _transactionRefreshController),
    CategoriesScreen(budgetController: widget.budgetController),
    const ReportsScreen(),
    ProfileScreen(refreshController: _transactionRefreshController),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        heroTag: "add_expense_btn",
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                budgetController: widget.budgetController,
                refreshController: _transactionRefreshController,
              ),
            ),
          );
        },
        backgroundColor: AppColors.gradientStart,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.gradientStart,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
