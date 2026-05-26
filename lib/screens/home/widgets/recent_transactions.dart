import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/transaction.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/format.dart';
import '../../transactions/transaction_form_screen.dart';

class RecentTransactions extends StatelessWidget {
  final List<Txn> transactions;

  const RecentTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Text('🌱', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tekan tombol + untuk menambahkan',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(transactions.length, (i) {
          final t = transactions[i];
          final last = i == transactions.length - 1;
          return Column(
            children: [
              TransactionTile(txn: t),
              if (!last)
                const Divider(height: 1, indent: 70, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Txn txn;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.txn, this.onTap});

  Color _signColor() {
    switch (txn.type) {
      case TxnType.income:
        return AppColors.income;
      case TxnType.expense:
        return AppColors.expense;
      case TxnType.transfer:
        return AppColors.transfer;
    }
  }

  String _signedAmount() {
    final prefix = txn.type == TxnType.income
        ? '+'
        : txn.type == TxnType.expense
            ? '-'
            : '';
    return '$prefix${Fmt.idr(txn.amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final categoryProv = context.read<CategoryProvider>();
    final accountProv = context.read<AccountProvider>();
    final category = categoryProv.byId(txn.categoryId);
    final account = accountProv.byId(txn.accountId);
    final toAccount = txn.transferToAccountId == null
        ? null
        : accountProv.byId(txn.transferToAccountId!);

    final icon = txn.type == TxnType.transfer
        ? '🔄'
        : category?.icon ?? (txn.type == TxnType.income ? '💵' : '🧾');
    final iconBg = txn.type == TxnType.transfer
        ? AppColors.transfer
        : (category?.color ?? _signColor());

    final title = txn.description.isNotEmpty
        ? txn.description
        : (txn.type == TxnType.transfer
            ? 'Transfer'
            : (category?.name ?? txn.type.label));

    final subtitle = txn.type == TxnType.transfer
        ? '${account?.name ?? '-'} → ${toAccount?.name ?? '-'}'
        : (account?.name ?? '-');

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransactionFormScreen(initial: txn),
                ),
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitle • ${Fmt.relative(txn.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _signedAmount(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _signColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
