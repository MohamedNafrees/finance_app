import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import 'edit_budget_screen.dart';
import '../state/budget_scope.dart';
import 'transaction_history_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.budgetController,
  });

  final BudgetController budgetController;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    String? validationMessage;
    final colorOptions = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    final iconOptions = [
      Icons.category,
      Icons.restaurant,
      Icons.shopping_bag,
      Icons.directions_car,
      Icons.home,
      Icons.movie,
      Icons.medical_services,
      Icons.pets,
      Icons.fitness_center,
      Icons.school,
      Icons.work,
      Icons.attach_money,
      Icons.star,
      Icons.favorite,
    ];

    final draftCategory = await showDialog<_CategoryDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Budget Limit',
                    hintText: 'e.g. 5000',
                  ),
                ),
                if (validationMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    validationMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Choose Icon:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: iconOptions.map((icon) {
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedColor.withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? selectedColor : Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('Choose Color:'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.textPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(backgroundColor: color, radius: 15),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final budgetLimit = double.tryParse(budgetController.text.trim());

                if (name.isEmpty || budgetLimit == null) {
                  setDialogState(() {
                    validationMessage =
                        'Enter a category name and valid budget limit';
                  });
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  _CategoryDraft(
                    name: name,
                    budgetLimit: budgetLimit,
                    color: selectedColor,
                    icon: selectedIcon,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    budgetController.dispose();

    if (!mounted || draftCategory == null) {
      return;
    }

    final newCategory = await widget.budgetController.createCategory(
      name: draftCategory.name,
      budgetLimit: draftCategory.budgetLimit,
      color: draftCategory.color,
      icon: draftCategory.icon,
    );
    if (!mounted) {
      return;
    }

    await widget.budgetController.loadBudgets();
    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newCategory.name} added to budgets')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgetController = widget.budgetController;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Category Spending Summary', style: AppTextStyles.titleMedium),
        centerTitle: true,
        leading: const SizedBox(), // Hidden on root
        actions: [
          IconButton(
            onPressed: _addCategory,
            icon: const Icon(Icons.add, color: AppColors.gradientStart),
            tooltip: 'Add Category',
          ),
          TextButton(
            onPressed: () async {
              final didUpdate = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => EditBudgetScreen(
                    budgetController: budgetController,
                  ),
                ),
              );
              if (!mounted) {
                return;
              }
              if (didUpdate == true) {
                await budgetController.loadBudgets();
                if (!mounted) {
                  return;
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Budget allocations updated in database!'),
                    ),
                  );
                });
              }
            },
            child: const Text('Edit', style: TextStyle(color: AppColors.gradientStart, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: budgetController,
        builder: (context, child) {
          if (budgetController.isLoading && !budgetController.hasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = budgetController.budgets;
          if (budgets.isEmpty) {
            return Center(
              child: Text(
                "No budget items found.\nAdd an expense or set a limit.",
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: budgets.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildCategoryCard(budgets[index]),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BudgetModel budget) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TransactionHistoryScreen(
              categoryId: budget.category.id,
              title: '${budget.category.name} Transactions',
            ),
          ),
        );
      },
      child: Container(
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
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: budget.category.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(budget.category.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.category.name, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.currency.format(budget.spent)} spent',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: budget.percentageUsed,
                minHeight: 12,
                backgroundColor: AppColors.background,
                color: budget.category.color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(budget.percentageUsed * 100).clamp(0, 100).toInt()}% used',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '${Formatters.currency.format(budget.remaining < 0 ? 0 : budget.remaining)} remaining of ${Formatters.currency.format(budget.limit)}',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.name,
    required this.budgetLimit,
    required this.color,
    required this.icon,
  });

  final String name;
  final double budgetLimit;
  final Color color;
  final IconData icon;
}
