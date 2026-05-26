class Budget {
  final String id;
  final String categoryId;
  final double amount;
  final int month; // 1-12
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget copyWith({
    String? categoryId,
    double? amount,
    int? month,
    int? year,
    DateTime? updatedAt,
  }) =>
      Budget(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        month: month ?? this.month,
        year: year ?? this.year,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'amount': amount,
        'month': month,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        amount: (map['amount'] as num).toDouble(),
        month: map['month'] as int,
        year: map['year'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
