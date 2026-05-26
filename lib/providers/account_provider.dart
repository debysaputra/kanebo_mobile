import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/account.dart';
import '../repositories/account_repository.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository _repo = AccountRepository();
  final _uuid = const Uuid();

  List<Account> _items = [];
  bool _loading = false;

  List<Account> get items => _items;
  List<Account> get activeItems =>
      _items.where((a) => a.isActive).toList(growable: false);
  bool get loading => _loading;
  double get totalBalance =>
      activeItems.fold(0.0, (sum, a) => sum + a.balance);

  Account? byId(String id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll(includeInactive: true);
    _loading = false;
    notifyListeners();
  }

  Future<Account> create({
    required String name,
    required AccountType type,
    required double balance,
    required int colorValue,
    required String icon,
  }) async {
    final now = DateTime.now();
    final account = Account(
      id: _uuid.v4(),
      name: name,
      type: type,
      balance: balance,
      colorValue: colorValue,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(account);
    await load();
    return account;
  }

  Future<void> update(Account account) async {
    await _repo.update(account);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
