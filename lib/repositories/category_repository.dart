import '../db/database_helper.dart';
import '../models/category.dart';

class CategoryRepository {
  Future<List<Category>> findAll({CategoryType? type}) async {
    final db = await DB.instance.database;
    final rows = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type.name],
      orderBy: 'isDefault DESC, name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> findById(String id) async {
    final db = await DB.instance.database;
    final rows =
        await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<void> insert(Category category) async {
    final db = await DB.instance.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    final db = await DB.instance.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
