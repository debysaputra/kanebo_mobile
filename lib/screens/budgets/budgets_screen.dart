import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'budget_form_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Budget baru',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Consumer<BudgetProvider>(
        builder: (ctx, prov, _) {
          return Column(
            children: [
              _MonthSelector(provider: prov),
              const _OverallProgress(),
              Expanded(child: _BudgetList(provider: prov)),
            ],
          );
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final BudgetProvider provider;
  const _MonthSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              var m = provider.month - 1;
              var y = provider.year;
              if (m < 1) {
                m = 12;
                y -= 1;
              }
              provider.setMonth(m, y);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                Fmt.monthYear(provider.monthRef),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              var m = provider.month + 1;
              var y = provider.year;
              if (m > 12) {
                m = 1;
                y += 1;
              }
              provider.setMonth(m, y);
            },
          ),
        ],
      ),
    );
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BudgetProvider>();
    final total = prov.items.fold<double>(0, (sum, b) => sum + b.amount);
    final spent = prov.items.fold<double>(
        0, (sum, b) => sum + prov.spentOf(b.categoryId).clamp(0, b.amount));
    final progress = total <= 0 ? 0.0 : (spent / total).clamp(0.0, 1.0);
    if (prov.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BUDGET BULAN INI',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Fmt.idr(spent)} / ${Fmt.idr(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetList extends StatelessWidget {
  final BudgetProvider provider;
  const _BudgetList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final categoryProv = context.watch<CategoryProvider>();
    final items = provider.items;
    if (items.isEmpty) {
      return EmptyState(
        emoji: '📊',
        title: 'Belum ada budget',
        subtitle: 'Buat anggaran bulanan agar pengeluaranmu terkendali.',
        actionLabel: 'Tambah budget',
        onAction: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = items[i];
        final c = categoryProv.byId(b.categoryId);
        return Slidable(
          key: ValueKey(b.id),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) async {
                  final ok = await showConfirmDialog(
                    context,
                    title: 'Hapus budget?',
                    message: 'Budget kategori ${c?.name ?? '-'} akan dihapus.',
                  );
                  if (ok) await provider.delete(b.id);
                },
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                icon: Icons.delete_rounded,
                label: 'Hapus',
                borderRadius: BorderRadius.circular(18),
              ),
            ],
          ),
          child: _BudgetTile(
            budget: b,
            category: c,
            spent: provider.spentOf(b.categoryId),
          ),
        );
      },
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final Budget budget;
  final Category? category;
  final double spent;

  const _BudgetTile({
    required this.budget,
    required this.category,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.amount <= 0 ? 0.0 : (spent / budget.amount).clamp(0.0, 1.5);
    final isOver = spent > budget.amount;
    final remaining = (budget.amount - spent).clamp(0.0, double.infinity);
    final c = category?.color ?? AppColors.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetFormScreen(budget: budget),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(category?.icon ?? '🏷️',
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.name ?? 'Kategori dihapus',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOver
                              ? 'Lebih ${Fmt.idr(spent - budget.amount)}'
                              : 'Sisa ${Fmt.idr(remaining)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOver
                                ? AppColors.expense
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.idrCompact(spent),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '/ ${Fmt.idrCompact(budget.amount)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                    isOver ? AppColors.expense : c,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
