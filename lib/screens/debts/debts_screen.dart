import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/debt.dart';
import '../../providers/debt_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';
import '../../widgets/empty_state.dart';
import 'debt_form_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hutang & Piutang'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'Hutang'),
              Tab(text: 'Piutang'),
            ],
          ),
        ),
        floatingActionButton: Builder(builder: (ctx) {
          return FloatingActionButton(
            tooltip: 'Tambah catatan',
            onPressed: () {
              final tabIdx = DefaultTabController.of(ctx).index;
              final type = tabIdx == 0 ? DebtType.debt : DebtType.receivable;
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => DebtFormScreen(initialType: type),
                ),
              );
            },
            child: const Icon(Icons.add_rounded, size: 28),
          );
        }),
        body: const TabBarView(
          children: [
            _DebtList(type: DebtType.debt),
            _DebtList(type: DebtType.receivable),
          ],
        ),
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final DebtType type;
  const _DebtList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<DebtProvider>(
      builder: (ctx, prov, _) {
        if (prov.loading && prov.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = prov.byType(type);
        final remaining = prov.totalRemaining(type);
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: type == DebtType.debt
                    ? AppColors.expenseGradient
                    : AppColors.incomeGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type == DebtType.debt
                        ? 'TOTAL HUTANG BELUM LUNAS'
                        : 'TOTAL PIUTANG BELUM LUNAS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Fmt.idr(remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(
                      emoji: type == DebtType.debt ? '💸' : '💰',
                      title: type == DebtType.debt
                          ? 'Tidak ada hutang'
                          : 'Tidak ada piutang',
                      subtitle: 'Tekan + untuk mencatat baru.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final d = items[i];
                        return Slidable(
                          key: ValueKey(d.id),
                          endActionPane: ActionPane(
                            motion: const StretchMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (_) async {
                                  final ok = await showConfirmDialog(
                                    ctx,
                                    title: 'Hapus catatan?',
                                    message: 'Catatan akan dihapus.',
                                  );
                                  if (ok) await prov.delete(d.id);
                                },
                                backgroundColor: AppColors.expense,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_rounded,
                                label: 'Hapus',
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ],
                          ),
                          child: _DebtTile(debt: d),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  const _DebtTile({required this.debt});

  Color _statusColor() {
    switch (debt.status) {
      case DebtStatus.paid:
        return AppColors.income;
      case DebtStatus.partial:
        return AppColors.warning;
      case DebtStatus.unpaid:
        return AppColors.expense;
    }
  }

  Future<void> _showPaymentSheet(BuildContext context) async {
    if (debt.status == DebtStatus.paid) return;
    double amount = 0;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debt.type == DebtType.debt
                    ? 'Catat pembayaran ke ${debt.personName}'
                    : 'Catat pengembalian dari ${debt.personName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sisa: ${Fmt.idr(debt.remaining)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              CurrencyInput(
                label: 'Jumlah dibayar',
                onChanged: (v) => amount = v,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (amount <= 0) return;
                  await context.read<DebtProvider>().recordPayment(debt, amount);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DebtFormScreen(debt: debt)),
        ),
        onLongPress: () => _showPaymentSheet(context),
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
                      color: _statusColor().withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      debt.type.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.personName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          debt.description.isNotEmpty
                              ? debt.description
                              : Fmt.date(debt.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Fmt.idrCompact(debt.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor().withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          debt.status.label,
                          style: TextStyle(
                            color: _statusColor(),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (debt.status != DebtStatus.unpaid) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: debt.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation(_statusColor()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terbayar ${Fmt.idr(debt.paidAmount)} • Sisa ${Fmt.idr(debt.remaining)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (debt.dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_rounded,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Jatuh tempo ${Fmt.date(debt.dueDate!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
