import 'package:flutter/material.dart';

enum AccountType { cash, bank, ewallet, credit }

extension AccountTypeX on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Tunai';
      case AccountType.bank:
        return 'Bank';
      case AccountType.ewallet:
        return 'E-Wallet';
      case AccountType.credit:
        return 'Kartu Kredit';
    }
  }

  String get emoji {
    switch (this) {
      case AccountType.cash:
        return '💵';
      case AccountType.bank:
        return '🏦';
      case AccountType.ewallet:
        return '📱';
      case AccountType.credit:
        return '💳';
    }
  }
}

AccountType accountTypeFromString(String value) {
  return AccountType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => AccountType.cash,
  );
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final int colorValue;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.colorValue,
    required this.icon,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    int? colorValue,
    String? icon,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'balance': balance,
        'colorValue': colorValue,
        'icon': icon,
        'isActive': isActive ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Account.fromMap(Map<String, dynamic> map) => Account(
        id: map['id'] as String,
        name: map['name'] as String,
        type: accountTypeFromString(map['type'] as String),
        balance: (map['balance'] as num).toDouble(),
        colorValue: map['colorValue'] as int,
        icon: map['icon'] as String,
        isActive: (map['isActive'] as int) == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
