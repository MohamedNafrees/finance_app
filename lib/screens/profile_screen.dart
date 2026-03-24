import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'add_balance_screen.dart';
import '../state/transaction_refresh_controller.dart';
import '../state/app_settings_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.refreshController,
  });

  final TransactionRefreshController refreshController;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsController.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(24),
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
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.gradientStart.withOpacity(0.1),
                        child: Icon(Icons.person, size: 50, color: AppColors.gradientStart),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.gradientStart,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Alex Johnson', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text('alex.johnson@example.com', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Settings List
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.currency_exchange,
                    title: 'Currency',
                    subtitle: settings.currencyLabel,
                    onTap: () => _showCurrencyPicker(context),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: settings.isDarkMode,
                      onChanged: settings.setDarkMode,
                      activeColor: AppColors.gradientStart,
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Add Balance / Income',
                    subtitle: 'Add custom income to account',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBalanceScreen(
                            refreshController: refreshController,
                          ),
                        ),
                      );
                      // In a real app we might use Provider to notify listeners,
                      // but here we can just depend on main scaffold rebuilding via tab changes
                      // However, tapping this implies we are on profile tab.
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.payments_outlined,
                    title: 'Add Monthly Salary',
                    subtitle: 'Quickly log salary',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBalanceScreen(
                            preselectSalary: true,
                            refreshController: refreshController,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.pie_chart_outline,
                    title: 'Budget Limits',
                  ),
                  _buildDivider(),
                  _buildListTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Financial Reports',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.iconBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textPrimary),
      ),
      title: Text(title, style: AppTextStyles.titleSmall),
      subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.bodyMedium) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 64, color: AppColors.iconBackground);
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final settings = AppSettingsController.instance;
    const currencies = [
      ('LKR', 'LKR ', 'LKR (Rs.)'),
      ('USD', '\$ ', 'USD (\$)'),
      ('EUR', 'EUR ', 'EUR (€)'),
      ('GBP', 'GBP ', 'GBP (£)'),
      ('INR', 'INR ', 'INR (₹)'),
    ];

    final selection = await showModalBottomSheet<(String, String, String)>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Currency', style: AppTextStyles.titleMedium),
                const SizedBox(height: 16),
                ...currencies.map((currency) {
                  final isSelected = settings.currencyCode == currency.$1;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(currency.$3, style: AppTextStyles.titleSmall),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.gradientStart)
                        : null,
                    onTap: () => Navigator.of(context).pop(currency),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selection == null) {
      return;
    }

    settings.setCurrency(
      code: selection.$1,
      symbol: selection.$2,
      label: selection.$3,
    );
  }
}
