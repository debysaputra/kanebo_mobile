import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/icon_color_picker.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final CategoryType? initialType;

  const CategoryFormScreen({super.key, this.category, this.initialType});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late CategoryType _type;
  late String _icon;
  late int _color;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl.text = c?.name ?? '';
    _type = c?.type ?? widget.initialType ?? CategoryType.expense;
    _icon = c?.icon ?? '✨';
    _color = c?.colorValue ?? AppColors.accountPalette.first.value;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<CategoryProvider>();
    if (_isEdit) {
      await prov.update(widget.category!.copyWith(
        name: _nameCtrl.text.trim(),
        type: _type,
        colorValue: _color,
        icon: _icon,
      ));
    } else {
      await prov.create(
        name: _nameCtrl.text.trim(),
        type: _type,
        colorValue: _color,
        icon: _icon,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus kategori?',
      message: 'Kategori akan dilepas dari transaksi terkait.',
    );
    if (!ok) return;
    await context.read<CategoryProvider>().delete(widget.category!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Kategori' : 'Kategori Baru'),
        actions: [
          if (_isEdit && widget.category!.isDefault == false)
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
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Color(_color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: Text(_icon, style: const TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipe',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: CategoryType.values.map((t) {
                return ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ikon',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            EmojiPicker(
              selected: _icon,
              onChanged: (e) => setState(() => _icon = e),
            ),
            const SizedBox(height: 20),
            const Text(
              'Warna',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ColorPickerRow(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan kategori'),
            ),
          ],
        ),
      ),
    );
  }
}
