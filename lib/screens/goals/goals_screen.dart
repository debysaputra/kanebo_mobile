import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';
import '../../widgets/empty_state.dart';
import 'goal_form_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Goal baru',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalFormScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Consumer<GoalProvider>(
        builder: (ctx, prov, _) {
          if (prov.loading && prov.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.items.isEmpty) {
            return EmptyState(
              emoji: '🎯',
              title: 'Belum ada goal',
              subtitle:
                  'Tetapkan target impianmu dan lacak perkembangan tabungan.',
              actionLabel: 'Buat goal',
              onAction: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const GoalFormScreen()),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: prov.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final g = prov.items[i];
              return Slidable(
                key: ValueKey(g.id),
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        final ok = await showConfirmDialog(
                          ctx,
                          title: 'Hapus goal?',
                          message: '"${g.name}" akan dihapus.',
                        );
                        if (ok) await prov.delete(g.id);
                      },
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_rounded,
                      label: 'Hapus',
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                child: _GoalCard(goal: g),
              );
            },
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  Future<void> _showContributeSheet(BuildContext context) async {
    double amount = 0;
    var isAdd = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update tabungan untuk "${goal.name}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ToggleButton(
                        label: '➕ Tambah',
                        selected: isAdd,
                        color: AppColors.income,
                        onTap: () => setSt(() => isAdd = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ToggleButton(
                        label: '➖ Kurangi',
                        selected: !isAdd,
                        color: AppColors.expense,
                        onTap: () => setSt(() => isAdd = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CurrencyInput(
                  label: 'Jumlah',
                  onChanged: (v) => amount = v,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (amount <= 0) return;
                    await context
                        .read<GoalProvider>()
                        .contribute(goal, isAdd ? amount : -amount);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = goal.color;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoalFormScreen(goal: goal),
          ),
        ),
        onLongPress: () => _showContributeSheet(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                c.withOpacity(0.08),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child:
                        Text(goal.icon, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.deadline == null
                              ? 'Tanpa deadline'
                              : '🗓️ ${Fmt.date(goal.deadline!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.savings_rounded,
                        color: AppColors.primary),
                    onPressed: () => _showContributeSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(c),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${Fmt.idrCompact(goal.currentAmount)} / ${Fmt.idrCompact(goal.targetAmount)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
