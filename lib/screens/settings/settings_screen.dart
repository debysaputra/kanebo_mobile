import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/database_helper.dart';
import '../../providers/account_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/debt_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset semua data?'),
        content: const Text(
          'Semua transaksi, akun, kategori, budget, goal, dan hutang akan dihapus permanen. '
          'Aplikasi akan kembali seperti pertama kali install (1 akun "Tunai" + kategori default).\n\n'
          'Aksi ini TIDAK BISA dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    await DB.instance.reset();
    if (!context.mounted) return;

    await Future.wait([
      context.read<AccountProvider>().load(),
      context.read<CategoryProvider>().load(),
      context.read<TransactionProvider>().load(),
      context.read<BudgetProvider>().load(),
      context.read<GoalProvider>().load(),
      context.read<DebtProvider>().load(),
    ]);

    if (!context.mounted) return;
    Navigator.pop(context); // tutup loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Data berhasil di-reset')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SectionLabel('Tentang'),
          _Tile(
            emoji: '💎',
            color: AppColors.primary,
            title: 'Kanebo Money',
            subtitle: 'Versi 1.0.0',
          ),
          _Tile(
            emoji: '💱',
            color: AppColors.tertiary,
            title: 'Mata uang',
            subtitle: 'Rupiah (IDR) — tetap',
          ),
          _Tile(
            emoji: '💾',
            color: AppColors.transfer,
            title: 'Penyimpanan',
            subtitle: 'Lokal di perangkat (SQLite)',
          ),
          const SizedBox(height: 16),
          _SectionLabel('Data'),
          _Tile(
            emoji: '🔄',
            color: AppColors.expense,
            title: 'Reset semua data',
            subtitle: 'Hapus semua transaksi & data, kembali ke kondisi awal',
            onTap: () => _confirmReset(context),
            destructive: true,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Dibuat dengan 💜 menggunakan Flutter',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  const _Tile({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: destructive
                              ? AppColors.expense
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
