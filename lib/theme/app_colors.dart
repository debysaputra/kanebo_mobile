import 'package:flutter/material.dart';

/// Palet warna playful — terang, ceria, ramah.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF7C5CFF); // ungu vibrant
  static const Color primaryDark = Color(0xFF5A3FE0);
  static const Color secondary = Color(0xFFFF7AC6); // pink
  static const Color tertiary = Color(0xFF22D3B4); // teal mint
  static const Color accent = Color(0xFFFFB547); // orange honey

  // Semantic
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color transfer = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFFFB547);

  // Surfaces
  static const Color bgLight = Color(0xFFFDF7FF); // pastel lavender bg
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF4EEFF);
  static const Color textPrimary = Color(0xFF1F1633);
  static const Color textSecondary = Color(0xFF6B6480);
  static const Color textMuted = Color(0xFFA7A0BD);
  static const Color border = Color(0xFFEEE7FB);

  // Account category presets
  static const List<Color> accountPalette = [
    Color(0xFF7C5CFF),
    Color(0xFFFF7AC6),
    Color(0xFF22D3B4),
    Color(0xFFFFB547),
    Color(0xFFEF4444),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFFEC4899),
  ];

  // Gradients (untuk balance card & header)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5CFF), Color(0xFFFF7AC6)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3B4), Color(0xFF22C55E)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7AC6), Color(0xFFEF4444)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB547), Color(0xFFFF7AC6)],
  );
}
