import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget.dart';
import '../../models/category.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;
  const BudgetFormScreen({super.key, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  String? _categoryId;
  double _amount = 0;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _categoryId = b?.categoryId;
    _amount = b?.amount ?? 0;
  }

  Future<void> _save() async {
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }
    final prov = context.read<BudgetProvider>();
    if (_isEdit) {
      await prov.update(widget.budget!.copyWith(
        categoryId: _categoryId,
        amount: _amount,
      ));
    } else {
      await prov.create(categoryId: _categoryId!, amount: _amount);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus budget?',
      message: 'Budget akan dihapus.',
    );
    if (!ok) return;
    await context.read<BudgetProvider>().delete(widget.budget!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        context.watch<CategoryProvider>().byType(CategoryType.expense);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Budget' : 'Budget Baru'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Kategori pengeluaran',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((c) {
              final selected = c.id == _categoryId;
              return GestureDetector(
                onTap: () => setState(() => _categoryId = c.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? c.color : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected ? c.color : AppColors.border,
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        c.name,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          CurrencyInput(
            initialValue: _amount,
            label: 'Jumlah budget',
            onChanged: (v) => _amount = v,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan budget'),
          ),
        ],
      ),
    );
  }
}
