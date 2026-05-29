import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../models/category.dart';
import '../../models/transaction.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';

class TransactionFormScreen extends StatefulWidget {
  final Txn? initial;
  const TransactionFormScreen({super.key, this.initial});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  late TxnType _type;
  double _amount = 0;
  DateTime _date = DateTime.now();
  String? _accountId;
  String? _toAccountId;
  String? _categoryId;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _type = t?.type ?? TxnType.expense;
    _amount = t?.amount ?? 0;
    _date = t?.date ?? DateTime.now();
    _accountId = t?.accountId;
    _toAccountId = t?.transferToAccountId;
    _categoryId = t?.categoryId;
    _descCtrl.text = t?.description ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-pilih akun pertama jika belum diisi.
    if (_accountId == null) {
      final accounts = context.read<AccountProvider>().activeItems;
      if (accounts.isNotEmpty) _accountId = accounts.first.id;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Color _typeColor() {
    switch (_type) {
      case TxnType.income:
        return AppColors.income;
      case TxnType.expense:
        return AppColors.expense;
      case TxnType.transfer:
        return AppColors.transfer;
    }
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih akun terlebih dahulu')),
      );
      return;
    }
    if (_type == TxnType.transfer) {
      if (_toAccountId == null || _toAccountId == _accountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih akun tujuan yang berbeda')),
        );
        return;
      }
    }

    final prov = context.read<TransactionProvider>();
    if (_isEdit) {
      await prov.update(widget.initial!.copyWith(
        accountId: _accountId,
        categoryId: _type == TxnType.transfer ? null : _categoryId,
        clearCategory: _type == TxnType.transfer,
        type: _type,
        amount: _amount,
        description: _descCtrl.text.trim(),
        date: _date,
        transferToAccountId:
            _type == TxnType.transfer ? _toAccountId : null,
        clearTransferTo: _type != TxnType.transfer,
      ));
    } else {
      await prov.create(
        accountId: _accountId!,
        categoryId: _categoryId,
        type: _type,
        amount: _amount,
        description: _descCtrl.text.trim(),
        date: _date,
        transferToAccountId: _toAccountId,
      );
    }
    if (mounted) Navigator.pop(context);
    // Sesekali tampilkan interstitial (default tiap 5x simpan). Dipanggil
    // setelah pop agar tidak mengganggu alur input.
    AdService.instance.registerSaveAndMaybeShowInterstitial();
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus transaksi?',
      message:
          'Saldo akun terkait akan dikembalikan seperti sebelum transaksi.',
    );
    if (!ok) return;
    await context.read<TransactionProvider>().delete(widget.initial!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final res = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (res != null) {
      setState(() => _date = DateTime(
            res.year,
            res.month,
            res.day,
            _date.hour,
            _date.minute,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().activeItems;
    final categories = context
        .watch<CategoryProvider>()
        .byType(_type == TxnType.income
            ? CategoryType.income
            : CategoryType.expense);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Transaksi Baru'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.expense),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _TypeSelector(
              selected: _type,
              onChanged: (t) => setState(() {
                _type = t;
                if (t == TxnType.transfer) _categoryId = null;
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _typeColor(),
                    Color.lerp(_typeColor(), Colors.black, 0.2) ?? _typeColor(),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CurrencyInputDark(
                initialValue: _amount,
                onChanged: (v) => _amount = v,
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.account_balance_wallet_rounded,
              label: _type == TxnType.transfer ? 'Dari akun' : 'Akun',
              child: _AccountSelector(
                accounts: accounts,
                selectedId: _accountId,
                onChanged: (id) => setState(() => _accountId = id),
              ),
            ),
            if (_type == TxnType.transfer) ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.south_east_rounded,
                label: 'Ke akun',
                child: _AccountSelector(
                  accounts: accounts.where((a) => a.id != _accountId).toList(),
                  selectedId: _toAccountId,
                  onChanged: (id) => setState(() => _toAccountId = id),
                ),
              ),
            ] else ...[
              const SizedBox(height: 14),
              _Section(
                icon: Icons.label_rounded,
                label: 'Kategori',
                child: _CategorySelector(
                  categories: categories,
                  selectedId: _categoryId,
                  onChanged: (id) => setState(() => _categoryId = id),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _Section(
              icon: Icons.event_rounded,
              label: 'Tanggal',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text(
                        Fmt.dateLong(_date),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              icon: Icons.notes_rounded,
              label: 'Catatan (opsional)',
              child: TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Tulis catatan singkat...',
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: _typeColor(),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TxnType selected;
  final ValueChanged<TxnType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: TxnType.values.map((t) {
          final isSelected = t == selected;
          Color c;
          switch (t) {
            case TxnType.income:
              c = AppColors.income;
              break;
            case TxnType.expense:
              c = AppColors.expense;
              break;
            case TxnType.transfer:
              c = AppColors.transfer;
              break;
          }
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? c : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _Section({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _AccountSelector({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Belum ada akun. Tambah akun dulu di menu Lainnya.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final a = accounts[i];
          final isSelected = a.id == selectedId;
          return GestureDetector(
            onTap: () => onChanged(a.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 140,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? a.color : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? a.color : AppColors.border,
                  width: 1.4,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(a.icon, style: const TextStyle(fontSize: 18)),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Fmt.idrCompact(a.balance),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.85)
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategorySelector({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Belum ada kategori untuk tipe ini.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final isSelected = c.id == selectedId;
        return GestureDetector(
          onTap: () => onChanged(c.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? c.color : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? c.color : AppColors.border,
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
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Currency input gaya dark / di atas gradient.
class CurrencyInputDark extends StatefulWidget {
  final double? initialValue;
  final ValueChanged<double> onChanged;
  const CurrencyInputDark({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<CurrencyInputDark> createState() => _CurrencyInputDarkState();
}

class _CurrencyInputDarkState extends State<CurrencyInputDark> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue ?? 0;
    _ctrl = TextEditingController(
      text: initial == 0 ? '' : Fmt.plain(initial),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return 0;
    return double.tryParse(d) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUMLAH',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Rp ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                cursorColor: Colors.white,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  // Penting: override theme global yg pakai fillColor putih
                  filled: false,
                  fillColor: Colors.transparent,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                onChanged: (s) {
                  final value = _parse(s);
                  final formatted = value == 0 ? '' : Fmt.plain(value);
                  if (formatted != s) {
                    _ctrl.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  widget.onChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
