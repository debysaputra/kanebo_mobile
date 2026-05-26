import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import 'category_form_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kategori'),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'Pengeluaran'),
              Tab(text: 'Pemasukan'),
            ],
          ),
        ),
        floatingActionButton: Builder(builder: (ctx) {
          return FloatingActionButton(
            tooltip: 'Kategori baru',
            onPressed: () {
              final tabIdx = DefaultTabController.of(ctx).index;
              final type = tabIdx == 0
                  ? CategoryType.expense
                  : CategoryType.income;
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => CategoryFormScreen(initialType: type),
                ),
              );
            },
            child: const Icon(Icons.add_rounded, size: 28),
          );
        }),
        body: const TabBarView(
          children: [
            _CategoryList(type: CategoryType.expense),
            _CategoryList(type: CategoryType.income),
          ],
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final CategoryType type;
  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (ctx, prov, _) {
        if (prov.loading && prov.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = prov.byType(type);
        if (items.isEmpty) {
          return EmptyState(
            emoji: '🏷️',
            title: 'Belum ada kategori',
            subtitle: 'Tambah kategori ${type.label.toLowerCase()}.',
            actionLabel: 'Tambah',
            onAction: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => CategoryFormScreen(initialType: type),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final c = items[i];
            return Slidable(
              key: ValueKey(c.id),
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                extentRatio: 0.25,
                children: [
                  SlidableAction(
                    onPressed: (_) async {
                      final ok = await showConfirmDialog(
                        ctx,
                        title: 'Hapus kategori?',
                        message:
                            'Transaksi yang memakai kategori ini akan kehilangan kategorinya.',
                      );
                      if (ok) await prov.delete(c.id);
                    },
                    backgroundColor: AppColors.expense,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_rounded,
                    label: 'Hapus',
                    borderRadius: BorderRadius.circular(18),
                  ),
                ],
              ),
              child: _CategoryTile(category: c),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

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
            builder: (_) => CategoryFormScreen(category: category),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(category.icon, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (category.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
