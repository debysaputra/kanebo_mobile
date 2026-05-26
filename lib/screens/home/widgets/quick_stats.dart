import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/transaction_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/format.dart';

class QuickStats extends StatelessWidget {
  const QuickStats({super.key});

  @override
  Widget build(BuildContext context) {
    final txn = context.watch<TransactionProvider>();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            gradient: AppColors.incomeGradient,
            emoji: '⬇️',
            label: 'Pemasukan',
            value: Fmt.idrCompact(txn.monthIncome),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            gradient: AppColors.expenseGradient,
            emoji: '⬆️',
            label: 'Pengeluaran',
            value: Fmt.idrCompact(txn.monthExpense),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Gradient gradient;
  final String emoji;
  final String label;
  final String value;

  const _StatCard({
    required this.gradient,
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
