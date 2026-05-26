enum TxnType { income, expense, transfer }

extension TxnTypeX on TxnType {
  String get label {
    switch (this) {
      case TxnType.income:
        return 'Pemasukan';
      case TxnType.expense:
        return 'Pengeluaran';
      case TxnType.transfer:
        return 'Transfer';
    }
  }

  String get emoji {
    switch (this) {
      case TxnType.income:
        return '⬇️';
      case TxnType.expense:
        return '⬆️';
      case TxnType.transfer:
        return '🔄';
    }
  }
}

TxnType txnTypeFromString(String value) {
  return TxnType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TxnType.expense,
  );
}

class Txn {
  final String id;
  final String accountId;
  final String? categoryId;
  final TxnType type;
  final double amount;
  final String description;
  final DateTime date;
  final String? transferToAccountId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Txn({
    required this.id,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description = '',
    required this.date,
    this.transferToAccountId,
    required this.createdAt,
    required this.updatedAt,
  });

  Txn copyWith({
    String? accountId,
    String? categoryId,
    TxnType? type,
    double? amount,
    String? description,
    DateTime? date,
    String? transferToAccountId,
    DateTime? updatedAt,
    bool clearCategory = false,
    bool clearTransferTo = false,
  }) =>
      Txn(
        id: id,
        accountId: accountId ?? this.accountId,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        type: type ?? this.type,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
        transferToAccountId: clearTransferTo
            ? null
            : (transferToAccountId ?? this.transferToAccountId),
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'accountId': accountId,
        'categoryId': categoryId,
        'type': type.name,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'transferToAccountId': transferToAccountId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Txn.fromMap(Map<String, dynamic> map) => Txn(
        id: map['id'] as String,
        accountId: map['accountId'] as String,
        categoryId: map['categoryId'] as String?,
        type: txnTypeFromString(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        description: (map['description'] as String?) ?? '',
        date: DateTime.parse(map['date'] as String),
        transferToAccountId: map['transferToAccountId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
