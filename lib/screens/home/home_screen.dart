import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../accounts/account_form_screen.dart';
import '../transactions/transactions_screen.dart';
import 'widgets/account_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/quick_stats.dart';
import 'widgets/recent_transactions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await Future.wait([
                    context.read<AccountProvider>().load(),
                    context.read<TransactionProvider>().load(),
                    context.read<CategoryProvider>().load(),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    _Greeting(),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: BalanceCard(),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: QuickStats(),
                    ),
                    SizedBox(height: 4),
                    _AccountsSection(),
                    SizedBox(height: 4),
                    _RecentSection(),
                  ],
                ),
              ),
            ),
            // Banner kecil di bawah; tidak menutupi konten & hilang sendiri
            // bila iklan gagal dimuat.
            if (adsSupported) const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  String _salam() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _salam() + ' 👋',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Fmt.dateLong(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text('💰', style: TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );
  }
}

class _AccountsSection extends StatelessWidget {
  const _AccountsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (ctx, prov, _) {
        final accounts = prov.activeItems;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Akun saya',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const AccountFormScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
            if (accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Belum ada akun. Tambah akun untuk mulai mencatat.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => AccountCard(account: accounts[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentSection extends StatelessWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (ctx, prov, _) {
        final recent = prov.items.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Transaksi terbaru',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => const TransactionsScreen(),
                      ),
                    ),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
            ),
            RecentTransactions(transactions: recent),
          ],
        );
      },
    );
  }
}
