import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/goal_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/currency_input.dart';
import '../../widgets/icon_color_picker.dart';

class GoalFormScreen extends StatefulWidget {
  final Goal? goal;
  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  double _target = 0;
  double _current = 0;
  DateTime? _deadline;
  late int _color;
  late String _icon;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameCtrl.text = g?.name ?? '';
    _target = g?.targetAmount ?? 0;
    _current = g?.currentAmount ?? 0;
    _deadline = g?.deadline;
    _color = g?.colorValue ?? AppColors.accent.value;
    _icon = g?.icon ?? '🎯';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target harus lebih dari 0')),
      );
      return;
    }
    final prov = context.read<GoalProvider>();
    if (_isEdit) {
      await prov.update(widget.goal!.copyWith(
        name: _nameCtrl.text.trim(),
        targetAmount: _target,
        currentAmount: _current,
        deadline: _deadline,
        clearDeadline: _deadline == null,
        colorValue: _color,
        icon: _icon,
      ));
    } else {
      await prov.create(
        name: _nameCtrl.text.trim(),
        targetAmount: _target,
        currentAmount: _current,
        deadline: _deadline,
        colorValue: _color,
        icon: _icon,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus goal?',
      message: 'Goal ini akan dihapus.',
    );
    if (!ok) return;
    await context.read<GoalProvider>().delete(widget.goal!.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDeadline() async {
    final res = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (res != null) setState(() => _deadline = res);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Goal' : 'Goal Baru'),
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama goal',
                hintText: 'Contoh: Liburan Bali',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            CurrencyInput(
              initialValue: _target,
              label: 'Target tabungan',
              onChanged: (v) => _target = v,
            ),
            const SizedBox(height: 16),
            CurrencyInput(
              initialValue: _current,
              label: 'Sudah terkumpul',
              onChanged: (v) => _current = v,
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDeadline,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      child: Text(
                        _deadline == null
                            ? 'Pilih deadline (opsional)'
                            : Fmt.dateLong(_deadline!),
                        style: TextStyle(
                          color: _deadline == null
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_deadline != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _deadline = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Ikon', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            EmojiPicker(
              selected: _icon,
              onChanged: (e) => setState(() => _icon = e),
            ),
            const SizedBox(height: 20),
            const Text('Warna', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ColorPickerRow(
              selected: _color,
              onChanged: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Simpan perubahan' : 'Simpan goal'),
            ),
          ],
        ),
      ),
    );
  }
}
