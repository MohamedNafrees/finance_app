import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';
import '../state/budget_scope.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({
    super.key,
    required this.budgetController,
  });

  final BudgetController budgetController;

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  List<BudgetModel> _localBudgets = [];
  bool _isSaving = false;
  bool _didLoadInitialBudgets = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialBudgets) {
      return;
    }

    _localBudgets = widget.budgetController.budgets
        .map(
          (budget) => BudgetModel(
            category: budget.category,
            limit: budget.limit,
            spent: budget.spent,
          ),
        )
        .toList();
    _didLoadInitialBudgets = true;
  }

  void _saveChanges() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await widget.budgetController.saveBudgetLimits(_localBudgets);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Budget Allocation', style: AppTextStyles.titleMedium),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust your monthly spending limits for each category.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  if (_localBudgets.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _localBudgets.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _BudgetEditCard(
                          budget: _localBudgets[index],
                          onChanged: (newLimit) {
                            setState(() {
                              _localBudgets[index] = BudgetModel(
                                category: _localBudgets[index].category,
                                limit: newLimit,
                                spent: _localBudgets[index].spent,
                              );
                            });
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientStart,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetEditCard extends StatefulWidget {
  final BudgetModel budget;
  final ValueChanged<double> onChanged;

  const _BudgetEditCard({
    required this.budget,
    required this.onChanged,
  });

  @override
  State<_BudgetEditCard> createState() => _BudgetEditCardState();
}

class _BudgetEditCardState extends State<_BudgetEditCard> {
  late TextEditingController _controller;
  late double _currentLimit;
  
  @override
  void initState() {
    super.initState();
    _currentLimit = widget.budget.limit;
    _controller = TextEditingController(text: _currentLimit.toInt().toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChange(String value) {
    if (value.isEmpty) {
      return;
    }
    final parsed = double.tryParse(value);
    if (parsed != null) {
      setState(() {
        _currentLimit = parsed.clamp(0.0, 200000.0);
      });
      widget.onChanged(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.budget.category.color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.budget.category.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.budget.category.name,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              Container(
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('LKR ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.titleSmall,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _handleTextChange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: widget.budget.category.color,
              inactiveTrackColor: AppColors.background,
              thumbColor: widget.budget.category.color,
              overlayColor: widget.budget.category.color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _currentLimit.clamp(0.0, 200000.0),
              min: 0,
              max: 200000,
              divisions: 200,
              onChangeEnd: (val) {
                widget.onChanged(val);
              },
              onChanged: (val) {
                setState(() {
                  _currentLimit = val;
                  _controller.value = TextEditingValue(
                    text: val.toInt().toString(),
                    selection: TextSelection.collapsed(
                      offset: val.toInt().toString().length,
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
