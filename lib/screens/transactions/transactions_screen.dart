import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/empty_state.dart';
import '../home/widgets/recent_transactions.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  TxnType? _filter;

  @override
  Widget build(BuildContext context) {
    final txn = context.watch<TransactionProvider>();
    final all = txn.items;
    final filtered =
        _filter == null ? all : all.where((t) => t.type == _filter).toList();
    final grouped = _groupByDay(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pemasukan',
                    color: AppColors.income,
                    selected: _filter == TxnType.income,
                    onTap: () => setState(() => _filter = TxnType.income),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pengeluaran',
                    color: AppColors.expense,
                    selected: _filter == TxnType.expense,
                    onTap: () => setState(() => _filter = TxnType.expense),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Transfer',
                    color: AppColors.transfer,
                    selected: _filter == TxnType.transfer,
                    onTap: () => setState(() => _filter = TxnType.transfer),
                  ),
                ],
              ),
            ),
          ),
          if (filtered.isEmpty)
            const Expanded(
              child: EmptyState(
                emoji: '🧾',
                title: 'Belum ada transaksi',
                subtitle: 'Tekan tombol + untuk menambahkan transaksi pertama.',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: grouped.length,
                itemBuilder: (_, i) {
                  final day = grouped[i];
                  return _DaySection(day: day.day, items: day.items);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Txn> items) {
    final map = <String, List<Txn>>{};
    for (final t in items) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      map.putIfAbsent(key, () => []).add(t);
    }
    final groups = map.entries.map((e) {
      final any = e.value.first.date;
      return _DayGroup(
        day: DateTime(any.year, any.month, any.day),
        items: e.value,
      );
    }).toList();
    groups.sort((a, b) => b.day.compareTo(a.day));
    return groups;
  }
}

class _DayGroup {
  final DateTime day;
  final List<Txn> items;
  _DayGroup({required this.day, required this.items});
}

class _DaySection extends StatelessWidget {
  final DateTime day;
  final List<Txn> items;

  const _DaySection({required this.day, required this.items});

  @override
  Widget build(BuildContext context) {
    double income = 0, expense = 0;
    for (final t in items) {
      if (t.type == TxnType.income) income += t.amount;
      if (t.type == TxnType.expense) expense += t.amount;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                Fmt.relative(day),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Fmt.dateShort(day),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (income > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '+${Fmt.idrCompact(income)}',
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (expense > 0)
                Text(
                  '-${Fmt.idrCompact(expense)}',
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final t = items[i];
              final last = i == items.length - 1;
              return Column(
                children: [
                  TransactionTile(txn: t),
                  if (!last)
                    const Divider(height: 1, indent: 70, endIndent: 16),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? c : AppColors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
