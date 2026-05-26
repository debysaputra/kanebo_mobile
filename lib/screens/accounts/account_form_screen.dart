import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account.dart';
import '../../providers/account_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';
import '../../widgets/icon_color_picker.dart';

class AccountFormScreen extends StatefulWidget {
  final Account? account;
  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late AccountType _type;
  late String _icon;
  late int _color;
  double _balance = 0;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _nameCtrl.text = a?.name ?? '';
    _type = a?.type ?? AccountType.cash;
    _icon = a?.icon ?? _type.emoji;
    _color = a?.colorValue ?? AppColors.accountPalette.first.value;
    _balance = a?.balance ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AccountProvider>();
    if (_isEdit) {
      await prov.update(widget.account!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _type,
        balance: _balance,
        colorValue: _color,
        icon: _icon,
      ));
    } else {
      await prov.create(
        name: _nameCtrl.text.trim(),
        type: _type,
        balance: _balance,
        colorValue: _color,
        icon: _icon,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus akun?',
      message: 'Semua transaksi akun ini juga akan terhapus.',
    );
    if (!ok) return;
    await context.read<AccountProvider>().delete(widget.account!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Akun' : 'Akun Baru'),
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
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: Color(_color),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Color(_color).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(_icon, style: const TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama akun',
                hintText: 'Contoh: BCA, GoPay, Dompet',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            const _Label('Jenis akun'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AccountType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text('${t.emoji}  ${t.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _type = t;
                    if (!_isEdit) _icon = t.emoji;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            CurrencyInput(
              initialValue: _balance,
              label: _isEdit ? 'Saldo saat ini' : 'Saldo awal',
              onChanged: (v) => _balance = v,
            ),
            const SizedBox(height: 20),
            const _Label('Pilih ikon'),
            const SizedBox(height: 8),
            EmojiPicker(
              selected: _icon,
              onChanged: (e) => setState(() => _icon = e),
            ),
            const SizedBox(height: 20),
            const _Label('Pilih warna'),
            const SizedBox(height: 8),
            ColorPickerRow(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan akun'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}
