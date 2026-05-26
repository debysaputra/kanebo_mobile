import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/debt.dart';
import '../../providers/debt_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';

class DebtFormScreen extends StatefulWidget {
  final Debt? debt;
  final DebtType? initialType;

  const DebtFormScreen({super.key, this.debt, this.initialType});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late DebtType _type;
  double _amount = 0;
  double _paid = 0;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;

  bool get _isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _type = d?.type ?? widget.initialType ?? DebtType.debt;
    _personCtrl.text = d?.personName ?? '';
    _descCtrl.text = d?.description ?? '';
    _notesCtrl.text = d?.notes ?? '';
    _amount = d?.amount ?? 0;
    _paid = d?.paidAmount ?? 0;
    _date = d?.date ?? DateTime.now();
    _dueDate = d?.dueDate;
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }
    final prov = context.read<DebtProvider>();
    if (_isEdit) {
      await prov.update(widget.debt!.copyWith(
        type: _type,
        personName: _personCtrl.text.trim(),
        amount: _amount,
        paidAmount: _paid.clamp(0.0, _amount),
        date: _date,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
        description: _descCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      ));
    } else {
      await prov.create(
        type: _type,
        personName: _personCtrl.text.trim(),
        amount: _amount,
        paidAmount: _paid.clamp(0.0, _amount),
        date: _date,
        dueDate: _dueDate,
        description: _descCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus catatan?',
      message: 'Catatan ${_type.label.toLowerCase()} akan dihapus.',
    );
    if (!ok) return;
    await context.read<DebtProvider>().delete(widget.debt!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate({required bool isDue}) async {
    final res = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? DateTime.now()) : _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (res != null) {
      setState(() {
        if (isDue) {
          _dueDate = res;
        } else {
          _date = res;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Catatan' : 'Catatan Baru'),
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: DebtType.values.map((t) {
                final selected = _type == t;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: t == DebtType.debt ? 6 : 0,
                      left: t == DebtType.receivable ? 6 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? (t == DebtType.debt
                                  ? AppColors.expense
                                  : AppColors.income)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : AppColors.border,
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${t.emoji}  ${t.label}',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _personCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText:
                    _type == DebtType.debt ? 'Hutang ke siapa?' : 'Pinjamkan ke siapa?',
                hintText: 'Nama orang',
                prefixIcon: const Icon(Icons.person_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            CurrencyInput(
              initialValue: _amount,
              label: 'Jumlah total',
              onChanged: (v) => _amount = v,
            ),
            const SizedBox(height: 14),
            CurrencyInput(
              initialValue: _paid,
              label: 'Sudah dibayar',
              onChanged: (v) => _paid = v,
            ),
            const SizedBox(height: 14),
            _DateField(
              label: 'Tanggal transaksi',
              value: _date,
              onTap: () => _pickDate(isDue: false),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Jatuh tempo (opsional)',
              value: _dueDate,
              onTap: () => _pickDate(isDue: true),
              onClear: _dueDate == null
                  ? null
                  : () => setState(() => _dueDate = null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Pinjam untuk apa?',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan tambahan',
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan catatan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? '—' : Fmt.dateLong(value!),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
