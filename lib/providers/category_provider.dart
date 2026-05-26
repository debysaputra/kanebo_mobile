import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repo = CategoryRepository();
  final _uuid = const Uuid();

  List<Category> _items = [];
  bool _loading = false;

  List<Category> get items => _items;
  bool get loading => _loading;

  List<Category> byType(CategoryType type) =>
      _items.where((c) => c.type == type).toList(growable: false);

  Category? byId(String? id) {
    if (id == null) return null;
    for (final c in _items) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _repo.findAll();
    _loading = false;
    notifyListeners();
  }

  Future<Category> create({
    required String name,
    required CategoryType type,
    required int colorValue,
    required String icon,
  }) async {
    final now = DateTime.now();
    final cat = Category(
      id: _uuid.v4(),
      name: name,
      type: type,
      colorValue: colorValue,
      icon: icon,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.insert(cat);
    await load();
    return cat;
  }

  Future<void> update(Category cat) async {
    await _repo.update(cat);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }
}
