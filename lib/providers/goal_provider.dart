import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../repositories/goal_repository.dart';

class GoalProvider extends ChangeNotifier {
  final GoalRepository _repo = GoalRepository();
  final _uuid = const Uuid();

  List<Goal> _items = [];
  bool _loading = false;

  List<Goal> get items => _items;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll();
    _loading = false;
    notifyListeners();
  }

  Future<Goal> create({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
    required int colorValue,
    required String icon,
  }) async {
    final now = DateTime.now();
    final goal = Goal(
      id: _uuid.v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      colorValue: colorValue,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(goal);
    await load();
    return goal;
  }

  Future<void> update(Goal goal) async {
    await _repo.update(goal);
    await load();
  }

  Future<void> contribute(Goal goal, double delta) async {
    final newAmount = (goal.currentAmount + delta).clamp(0.0, double.infinity);
    await update(goal.copyWith(currentAmount: newAmount));
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
