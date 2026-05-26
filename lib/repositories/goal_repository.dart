import '../db/database_helper.dart';
import '../models/goal.dart';

class GoalRepository {
  Future<List<Goal>> findAll() async {
    final db = await DB.instance.database;
    final rows = await db.query('goals', orderBy: 'createdAt DESC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<Goal?> findById(String id) async {
    final db = await DB.instance.database;
    final rows = await db.query('goals', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Goal.fromMap(rows.first);
  }

  Future<void> insert(Goal goal) async {
    final db = await DB.instance.database;
    await db.insert('goals', goal.toMap());
  }

  Future<void> update(Goal goal) async {
    final db = await DB.instance.database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
