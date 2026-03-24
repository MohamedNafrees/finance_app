import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../state/budget_scope.dart';
import '../state/transaction_refresh_controller.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.budgetController,
    required this.refreshController,
  });

  final BudgetController budgetController;
  final TransactionRefreshController refreshController;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _notesController = TextEditingController();
  final List<_ExpenseDraft> _expenseDrafts = [];
  
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _expenseDrafts.add(_ExpenseDraft());
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final catMaps = await DatabaseHelper.instance.getAllCategories();
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = catMaps.map((m) => CategoryModel.fromMap(m)).where((c) => c.id != 'inc_salary').toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (final draft in _expenseDrafts) {
      draft.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _addExpenseDraft() {
    setState(() {
      _expenseDrafts.add(_ExpenseDraft());
    });
  }

  void _removeExpenseDraft(int index) {
    if (_expenseDrafts.length == 1) {
      return;
    }

    setState(() {
      final draft = _expenseDrafts.removeAt(index);
      draft.dispose();
    });
  }

  void _saveExpense() async {
    final budgetState = widget.budgetController;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final transactions = <TransactionModel>[];
    for (var i = 0; i < _expenseDrafts.length; i++) {
      final draft = _expenseDrafts[i];
      final titleText = draft.titleController.text.trim();
      final amountText = draft.amountController.text.trim();
      final amount = double.tryParse(amountText);

      if (titleText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter title for expense ${i + 1}')),
        );
        return;
      }

      if (amountText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter amount for expense ${i + 1}')),
        );
        return;
      }

      if (amount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid amount for expense ${i + 1}')),
        );
        return;
      }

      transactions.add(
        TransactionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          title: titleText,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          date: _selectedDate,
          amount: amount,
          category: _selectedCategory!,
          isIncome: false,
        ),
      );
    }

    for (final transaction in transactions) {
      await DatabaseHelper.instance.insertTransaction(transaction.toMap());
    }
    await budgetState.loadBudgets();
    widget.refreshController.refresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${transactions.length} expense(s) stored successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Add Expense', style: AppTextStyles.titleMedium),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: AppTextStyles.titleSmall),
              const SizedBox(height: 16),
              
              // Category Grid
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory?.id == category.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? category.color.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? category.color : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category.icon, color: category.color, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? category.color : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Date Picker
              Text('Date', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.gradientStart),
                      const SizedBox(width: 16),
                      Text(
                        Formatters.dateDay.format(_selectedDate),
                        style: AppTextStyles.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Expenses', style: AppTextStyles.titleSmall),
                  TextButton.icon(
                    onPressed: _addExpenseDraft,
                    icon: const Icon(Icons.add, color: AppColors.gradientStart),
                    label: const Text(
                      'Add More',
                      style: TextStyle(color: AppColors.gradientStart),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_expenseDrafts.length, (index) {
                final draft = _expenseDrafts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == _expenseDrafts.length - 1 ? 0 : 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Expense ${index + 1}', style: AppTextStyles.titleSmall),
                            if (_expenseDrafts.length > 1)
                              IconButton(
                                onPressed: () => _removeExpenseDraft(index),
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: draft.titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Starbucks Coffee, Grocery...',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: draft.amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Amount',
                            prefixText: 'LKR ',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Notes
              Text('Notes (Optional)', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gradientStart,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
      ),
    );
  }
}

class _ExpenseDraft {
  _ExpenseDraft()
      : titleController = TextEditingController(),
        amountController = TextEditingController();

  final TextEditingController titleController;
  final TextEditingController amountController;

  void dispose() {
    titleController.dispose();
    amountController.dispose();
  }
}
