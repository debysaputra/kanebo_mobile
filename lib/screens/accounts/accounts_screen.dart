import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'account_form_screen.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Akun baru',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountFormScreen()),
        ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Consumer<AccountProvider>(
        builder: (ctx, prov, _) {
          if (prov.loading && prov.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = prov.items;
          if (items.isEmpty) {
            return EmptyState(
              emoji: '💳',
              title: 'Belum ada akun',
              subtitle:
                  'Tambahkan akun tunai, bank, atau e-wallet untuk mulai mengatur keuangan.',
              actionLabel: 'Tambah akun',
              onAction: () => Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const AccountFormScreen()),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = items[i];
              return Slidable(
                key: ValueKey(a.id),
                endActionPane: ActionPane(
                  motion: const StretchMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        final ok = await showConfirmDialog(
                          ctx,
                          title: 'Hapus akun?',
                          message:
                              'Semua transaksi akun "${a.name}" juga akan terhapus.',
                        );
                        if (ok) await prov.delete(a.id);
                      },
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_rounded,
                      label: 'Hapus',
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ],
                ),
                child: _AccountTile(account: a),
              );
            },
          );
        },
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Account account;
  const _AccountTile({required this.account});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountFormScreen(account: account),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: account.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child:
                    Text(account.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.type.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.idr(account.balance),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: account.balance < 0
                      ? AppColors.expense
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
