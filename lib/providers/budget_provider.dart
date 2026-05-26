import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../repositories/budget_repository.dart';
import '../repositories/transaction_repository.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repo = BudgetRepository();
  final TransactionRepository _txnRepo = TransactionRepository();
  final _uuid = const Uuid();

  List<Budget> _items = [];
  Map<String, double> _spentByCategory = {};
  bool _loading = false;

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  int get month => _month;
  int get year => _year;
  DateTime get monthRef => DateTime(_year, _month);
  List<Budget> get items => _items;
  bool get loading => _loading;

  double spentOf(String categoryId) => _spentByCategory[categoryId] ?? 0;

  void setMonth(int month, int year) {
    _month = month;
    _year = year;
    load();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll(month: _month, year: _year);
    final start = DateTime(_year, _month, 1);
    final end = DateTime(_year, _month + 1, 0, 23, 59, 59);
    _spentByCategory = await _txnRepo.expenseByCategory(from: start, to: end);
    _loading = false;
    notifyListeners();
  }

  Future<Budget> create({
    required String categoryId,
    required double amount,
  }) async {
    final now = DateTime.now();
    final budget = Budget(
      id: _uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      month: _month,
      year: _year,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(budget);
    await load();
    return budget;
  }

  Future<void> update(Budget budget) async {
    await _repo.update(budget);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
