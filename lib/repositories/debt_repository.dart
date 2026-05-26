import '../db/database_helper.dart';
import '../models/debt.dart';

class DebtRepository {
  Future<List<Debt>> findAll({DebtType? type, DebtStatus? status}) async {
    final db = await DB.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    final rows = await db.query(
      'debts',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
    );
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt?> findById(String id) async {
    final db = await DB.instance.database;
    final rows = await db.query('debts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Debt.fromMap(rows.first);
  }

  Future<void> insert(Debt debt) async {
    final db = await DB.instance.database;
    await db.insert('debts', debt.toMap());
  }

  Future<void> update(Debt debt) async {
    final db = await DB.instance.database;
    await db.update('debts', debt.toMap(), where: 'id = ?', whereArgs: [debt.id]);
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }
}
