import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../accounts/accounts_screen.dart';
import '../budgets/budgets_screen.dart';
import '../categories/categories_screen.dart';
import '../debts/debts_screen.dart';
import '../goals/goals_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      _MoreItem(
        emoji: '💳',
        title: 'Akun',
        subtitle: 'Kelola dompet, bank, e-wallet',
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
        ),
        builder: () => const AccountsScreen(),
      ),
      _MoreItem(
        emoji: '🏷️',
        title: 'Kategori',
        subtitle: 'Atur kategori pemasukan & pengeluaran',
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7AC6), Color(0xFFEC4899)],
        ),
        builder: () => const CategoriesScreen(),
      ),
      _MoreItem(
        emoji: '📊',
        title: 'Budget',
        subtitle: 'Anggaran bulanan per kategori',
        gradient: const LinearGradient(
          colors: [Color(0xFF22D3B4), Color(0xFF14B8A6)],
        ),
        builder: () => const BudgetsScreen(),
      ),
      _MoreItem(
        emoji: '🎯',
        title: 'Goals',
        subtitle: 'Target tabungan & impianmu',
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB547), Color(0xFFF97316)],
        ),
        builder: () => const GoalsScreen(),
      ),
      _MoreItem(
        emoji: '🤝',
        title: 'Hutang & Piutang',
        subtitle: 'Catat siapa pinjam siapa',
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
        ),
        builder: () => const DebtsScreen(),
      ),
      _MoreItem(
        emoji: '⚙️',
        title: 'Pengaturan',
        subtitle: 'Reset data & info aplikasi',
        gradient: const LinearGradient(
          colors: [Color(0xFF6B6480), Color(0xFF1F1633)],
        ),
        builder: () => const SettingsScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Lainnya'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _MoreCard(item: items[i]),
      ),
    );
  }
}

class _MoreItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final Widget Function() builder;

  _MoreItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.builder,
  });
}

class _MoreCard extends StatelessWidget {
  final _MoreItem item;
  const _MoreCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.builder()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
