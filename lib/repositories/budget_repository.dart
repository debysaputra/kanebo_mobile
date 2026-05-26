import '../db/database_helper.dart';
import '../models/budget.dart';

class BudgetRepository {
  Future<List<Budget>> findAll({int? month, int? year}) async {
    final db = await DB.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (month != null) {
      where.add('month = ?');
      args.add(month);
    }
    if (year != null) {
      where.add('year = ?');
      args.add(year);
    }
    final rows = await db.query(
      'budgets',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'amount DESC',
    );
    return rows.map(Budget.fromMap).toList();
  }

  Future<Budget?> findById(String id) async {
    final db = await DB.instance.database;
    final rows = await db.query('budgets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<void> insert(Budget budget) async {
    final db = await DB.instance.database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> update(Budget budget) async {
    final db = await DB.instance.database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}
