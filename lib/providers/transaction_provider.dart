import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'account_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repo = TransactionRepository();
  final _uuid = const Uuid();
  final AccountProvider _accountProvider;

  TransactionProvider(this._accountProvider);

  List<Txn> _items = [];
  bool _loading = false;

  List<Txn> get items => _items;
  bool get loading => _loading;

  /// Statistik bulan berjalan.
  double _monthIncome = 0;
  double _monthExpense = 0;
  double get monthIncome => _monthIncome;
  double get monthExpense => _monthExpense;
  double get monthNet => _monthIncome - _monthExpense;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll(limit: 200);
    await _loadMonthSums();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadMonthSums() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final sums = await _repo.sums(from: start, to: end);
    _monthIncome = sums.income;
    _monthExpense = sums.expense;
  }

  Future<List<Txn>> filter({
    DateTime? from,
    DateTime? to,
    TxnType? type,
    String? accountId,
    String? categoryId,
  }) async {
    return _repo.findAll(
      from: from,
      to: to,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  Future<Txn> create({
    required String accountId,
    String? categoryId,
    required TxnType type,
    required double amount,
    String description = '',
    required DateTime date,
    String? transferToAccountId,
  }) async {
    final now = DateTime.now();
    final txn = Txn(
      id: _uuid.v4(),
      accountId: accountId,
      categoryId: type == TxnType.transfer ? null : categoryId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      transferToAccountId:
          type == TxnType.transfer ? transferToAccountId : null,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(txn);
    await Future.wait([load(), _accountProvider.load()]);
    return txn;
  }

  Future<void> update(Txn txn) async {
    await _repo.update(txn);
    await Future.wait([load(), _accountProvider.load()]);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await Future.wait([load(), _accountProvider.load()]);
  }

  Future<List<Txn>> recent({int limit = 5}) async {
    return _repo.findAll(limit: limit);
  }
}
