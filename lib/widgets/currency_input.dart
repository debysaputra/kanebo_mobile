import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInput extends StatefulWidget {
  final double? initialValue;
  final String label;
  final String? hint;
  final ValueChanged<double> onChanged;
  final String? Function(double value)? validator;

  const CurrencyInput({
    super.key,
    this.initialValue,
    this.label = 'Jumlah',
    this.hint,
    required this.onChanged,
    this.validator,
  });

  @override
  State<CurrencyInput> createState() => _CurrencyInputState();
}

class _CurrencyInputState extends State<CurrencyInput> {
  late final TextEditingController _controller;
  final _fmt = NumberFormat.decimalPattern('id_ID');

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue ?? 0;
    _controller = TextEditingController(
      text: initial == 0 ? '' : _fmt.format(initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _parse(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return double.tryParse(digits) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        TextInputFormatter.withFunction((oldValue, newValue) {
          final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isEmpty) {
            return const TextEditingValue(text: '');
          }
          final value = int.parse(digits);
          final formatted = _fmt.format(value);
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint ?? '0',
        prefixText: 'Rp  ',
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      validator: (s) {
        final value = _parse(s ?? '');
        if (widget.validator != null) return widget.validator!(value);
        return null;
      },
      onChanged: (s) => widget.onChanged(_parse(s)),
    );
  }
}
