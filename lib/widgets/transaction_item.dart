import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/models.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final bool showNotes;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.showNotes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: transaction.category.color.withOpacity(0.15),
          child: Icon(
            transaction.category.icon,
            color: transaction.category.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.title, style: AppTextStyles.titleSmall),
              const SizedBox(height: 4),
              Text(
                Formatters.dateDay.format(transaction.date),
                style: AppTextStyles.bodySmall,
              ),
              if (showNotes &&
                  transaction.notes != null &&
                  transaction.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.notes!,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Text(
          '${transaction.isIncome ? '+' : '-'}${Formatters.currency.format(transaction.amount)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: transaction.isIncome ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
