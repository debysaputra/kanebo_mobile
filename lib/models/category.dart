import 'package:flutter/material.dart';

enum CategoryType { income, expense }

extension CategoryTypeX on CategoryType {
  String get label => this == CategoryType.income ? 'Pemasukan' : 'Pengeluaran';
}

CategoryType categoryTypeFromString(String value) {
  return CategoryType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => CategoryType.expense,
  );
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final int colorValue;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.icon,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);

  Category copyWith({
    String? name,
    CategoryType? type,
    int? colorValue,
    String? icon,
    DateTime? updatedAt,
  }) =>
      Category(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        colorValue: colorValue ?? this.colorValue,
        icon: icon ?? this.icon,
        isDefault: isDefault,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'colorValue': colorValue,
        'icon': icon,
        'isDefault': isDefault ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        type: categoryTypeFromString(map['type'] as String),
        colorValue: map['colorValue'] as int,
        icon: map['icon'] as String,
        isDefault: (map['isDefault'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
