import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../state/transaction_refresh_controller.dart';

class AddBalanceScreen extends StatefulWidget {
  final bool preselectSalary;
  final TransactionRefreshController refreshController;

  const AddBalanceScreen({
    super.key,
    this.preselectSalary = false,
    required this.refreshController,
  });

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedSource;
  DateTime _selectedDate = DateTime.now();

  final List<String> _incomeSources = ['Salary', 'Bonus', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.preselectSalary) {
      _selectedSource = 'Salary';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleBackNavigation() {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null && currentFocus.hasFocus) {
      currentFocus.unfocus();
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _saveBalance() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid number')),
      );
      return;
    }

    if (_selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an income source')),
      );
      return;
    }

    // If user typed notes, use that as title; else use the selected source string
    final title = _notesController.text.isEmpty ? _selectedSource! : _notesController.text;

    final categoryId = 'inc_${_selectedSource!.toLowerCase()}';
    CategoryModel incomeCategory = CategoryModel(
      id: categoryId,
      name: _selectedSource!,
      icon: Icons.attach_money,
      color: AppColors.success,
    );

    final existingCategory =
        await DatabaseHelper.instance.getCategoryById(categoryId);
    if (existingCategory == null) {
      await DatabaseHelper.instance.insertCategory(
        incomeCategory.toMap(),
      );
    } else {
      incomeCategory = CategoryModel.fromMap(existingCategory);
    }

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: _selectedDate,
      amount: amount,
      category: incomeCategory,
      isIncome: true, // Marked as income explicitly
    );

    await DatabaseHelper.instance.insertTransaction(transaction.toMap());
    widget.refreshController.refresh();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance / Income Added Successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Add Balance', style: AppTextStyles.titleMedium),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Center(
                child: Column(
                  children: [
                    Text('Income Amount', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.balanceLarge.copyWith(color: AppColors.success), // Green text for income
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'LKR 0.00',
                          hintStyle: AppTextStyles.balanceLarge.copyWith(color: AppColors.textSecondary.withOpacity(0.3)),
                          border: InputBorder.none,
                          prefixText: '+LKR ',
                          prefixStyle: AppTextStyles.balanceLarge.copyWith(color: AppColors.success),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Text('Income Source', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSource,
                    hint: Text('Select source', style: TextStyle(color: AppColors.textSecondary)),
                    items: _incomeSources.map((String source) {
                      return DropdownMenuItem<String>(
                        value: source,
                        child: Text(source, style: AppTextStyles.titleSmall),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSource = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Date Received', style: AppTextStyles.titleSmall),
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
                      Text(Formatters.dateDay.format(_selectedDate), style: AppTextStyles.titleSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('Notes (Optional)', style: AppTextStyles.titleSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add an internal note...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveBalance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success, // Use green color for income
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text('Save Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
