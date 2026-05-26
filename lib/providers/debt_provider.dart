import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/debt.dart';
import '../repositories/debt_repository.dart';

class DebtProvider extends ChangeNotifier {
  final DebtRepository _repo = DebtRepository();
  final _uuid = const Uuid();

  List<Debt> _items = [];
  bool _loading = false;

  List<Debt> get items => _items;
  bool get loading => _loading;

  List<Debt> byType(DebtType type) =>
      _items.where((d) => d.type == type).toList(growable: false);

  double totalRemaining(DebtType type) => byType(type)
      .where((d) => d.status != DebtStatus.paid)
      .fold(0.0, (sum, d) => sum + d.remaining);

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll();
    _loading = false;
    notifyListeners();
  }

  Future<Debt> create({
    required DebtType type,
    required String personName,
    required double amount,
    double paidAmount = 0,
    required DateTime date,
    DateTime? dueDate,
    String description = '',
    String notes = '',
  }) async {
    final now = DateTime.now();
    final debt = Debt(
      id: _uuid.v4(),
      type: type,
      personName: personName,
      amount: amount,
      paidAmount: paidAmount,
      date: date,
      dueDate: dueDate,
      status: Debt.computeStatus(amount, paidAmount),
      description: description,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(debt);
    await load();
    return debt;
  }

  Future<void> update(Debt debt) async {
    final next = debt.copyWith(
      status: Debt.computeStatus(debt.amount, debt.paidAmount),
    );
    await _repo.update(next);
    await load();
  }

  Future<void> recordPayment(Debt debt, double amount) async {
    final newPaid =
        (debt.paidAmount + amount).clamp(0.0, debt.amount);
    await update(debt.copyWith(paidAmount: newPaid));
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
