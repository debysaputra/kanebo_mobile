import '../db/database_helper.dart';
import '../models/account.dart';

class AccountRepository {
  Future<List<Account>> findAll({bool includeInactive = false}) async {
    final db = await DB.instance.database;
    final rows = await db.query(
      'accounts',
      where: includeInactive ? null : 'isActive = ?',
      whereArgs: includeInactive ? null : [1],
      orderBy: 'createdAt ASC',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> findById(String id) async {
    final db = await DB.instance.database;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  Future<void> insert(Account account) async {
    final db = await DB.instance.database;
    await db.insert('accounts', account.toMap());
  }

  Future<void> update(Account account) async {
    final db = await DB.instance.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> adjustBalance(String id, double delta) async {
    final db = await DB.instance.database;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ?, updatedAt = ? WHERE id = ?',
      [delta, DateTime.now().toIso8601String(), id],
    );
  }

  Future<double> totalBalance() async {
    final db = await DB.instance.database;
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(balance), 0) AS total FROM accounts WHERE isActive = 1');
    return (rows.first['total'] as num).toDouble();
  }
}
