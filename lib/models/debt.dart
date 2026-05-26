enum DebtType { debt, receivable }

extension DebtTypeX on DebtType {
  String get label => this == DebtType.debt ? 'Hutang' : 'Piutang';
  String get emoji => this == DebtType.debt ? '💸' : '💰';
}

enum DebtStatus { unpaid, partial, paid }

extension DebtStatusX on DebtStatus {
  String get label {
    switch (this) {
      case DebtStatus.unpaid:
        return 'Belum dibayar';
      case DebtStatus.partial:
        return 'Sebagian';
      case DebtStatus.paid:
        return 'Lunas';
    }
  }
}

DebtType debtTypeFromString(String v) =>
    DebtType.values.firstWhere((e) => e.name == v, orElse: () => DebtType.debt);

DebtStatus debtStatusFromString(String v) => DebtStatus.values
    .firstWhere((e) => e.name == v, orElse: () => DebtStatus.unpaid);

class Debt {
  final String id;
  final DebtType type;
  final String personName;
  final double amount;
  final double paidAmount;
  final DateTime date;
  final DateTime? dueDate;
  final DebtStatus status;
  final String description;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Debt({
    required this.id,
    required this.type,
    required this.personName,
    required this.amount,
    this.paidAmount = 0,
    required this.date,
    this.dueDate,
    this.status = DebtStatus.unpaid,
    this.description = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  double get remaining => (amount - paidAmount).clamp(0.0, double.infinity);
  double get progress =>
      amount <= 0 ? 0 : (paidAmount / amount).clamp(0.0, 1.0);

  static DebtStatus computeStatus(double amount, double paid) {
    if (paid <= 0) return DebtStatus.unpaid;
    if (paid >= amount) return DebtStatus.paid;
    return DebtStatus.partial;
  }

  Debt copyWith({
    DebtType? type,
    String? personName,
    double? amount,
    double? paidAmount,
    DateTime? date,
    DateTime? dueDate,
    bool clearDueDate = false,
    DebtStatus? status,
    String? description,
    String? notes,
    DateTime? updatedAt,
  }) =>
      Debt(
        id: id,
        type: type ?? this.type,
        personName: personName ?? this.personName,
        amount: amount ?? this.amount,
        paidAmount: paidAmount ?? this.paidAmount,
        date: date ?? this.date,
        dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
        status: status ?? this.status,
        description: description ?? this.description,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'personName': personName,
        'amount': amount,
        'paidAmount': paidAmount,
        'date': date.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'description': description,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Debt.fromMap(Map<String, dynamic> map) => Debt(
        id: map['id'] as String,
        type: debtTypeFromString(map['type'] as String),
        personName: map['personName'] as String,
        amount: (map['amount'] as num).toDouble(),
        paidAmount: (map['paidAmount'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
        dueDate: map['dueDate'] == null
            ? null
            : DateTime.parse(map['dueDate'] as String),
        status: debtStatusFromString(map['status'] as String),
        description: (map['description'] as String?) ?? '',
        notes: (map['notes'] as String?) ?? '',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
