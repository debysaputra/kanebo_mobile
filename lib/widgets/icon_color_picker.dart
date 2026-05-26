import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const List<String> kEmojiOptions = [
  '💰', '💵', '🏦', '💳', '📱', '🪙', '💎', '🎁',
  '🍔', '🍕', '🍣', '☕', '🛒', '🛍️', '👕', '👟',
  '🚗', '🛵', '⛽', '🚌', '✈️', '🏠', '💡', '🔌',
  '💊', '🏥', '📚', '🎬', '🎮', '🎵', '🏋️', '🐶',
  '👶', '🎓', '💼', '📈', '🧾', '🎯', '✨', '🌱',
];

class EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String>? options;

  const EmojiPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final list = options ?? kEmojiOptions;
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final e = list[i];
          final isSelected = e == selected;
          return GestureDetector(
            onTap: () => onChanged(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 0 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 26)),
            ),
          );
        },
      ),
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppColors.accountPalette.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final c = AppColors.accountPalette[i];
          final isSelected = c.value == selected;
          return GestureDetector(
            onTap: () => onChanged(c.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.textPrimary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: c.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
