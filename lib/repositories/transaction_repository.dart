import '../db/database_helper.dart';
import '../models/transaction.dart';

class TransactionRepository {
  Future<List<Txn>> findAll({
    int? limit,
    DateTime? from,
    DateTime? to,
    TxnType? type,
    String? accountId,
    String? categoryId,
  }) async {
    final db = await DB.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }
    if (accountId != null) {
      where.add('(accountId = ? OR transferToAccountId = ?)');
      args.add(accountId);
      args.add(accountId);
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );
    return rows.map(Txn.fromMap).toList();
  }

  Future<Txn?> findById(String id) async {
    final db = await DB.instance.database;
    final rows =
        await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Txn.fromMap(rows.first);
  }

  Future<void> insert(Txn txn) async {
    final db = await DB.instance.database;
    await db.transaction((t) async {
      await t.insert('transactions', txn.toMap());
      await _applyTxnEffect(t, txn, sign: 1);
    });
  }

  Future<void> update(Txn updated) async {
    final db = await DB.instance.database;
    await db.transaction((t) async {
      final oldRows = await t
          .query('transactions', where: 'id = ?', whereArgs: [updated.id]);
      if (oldRows.isNotEmpty) {
        final old = Txn.fromMap(oldRows.first);
        await _applyTxnEffect(t, old, sign: -1);
      }
      await t.update(
        'transactions',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );
      await _applyTxnEffect(t, updated, sign: 1);
    });
  }

  Future<void> delete(String id) async {
    final db = await DB.instance.database;
    await db.transaction((t) async {
      final rows = await t
          .query('transactions', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final old = Txn.fromMap(rows.first);
        await _applyTxnEffect(t, old, sign: -1);
      }
      await t.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// sign = 1 untuk apply (insert), -1 untuk revert (delete/update lama)
  Future<void> _applyTxnEffect(dynamic t, Txn txn, {required int sign}) async {
    final nowIso = DateTime.now().toIso8601String();
    switch (txn.type) {
      case TxnType.income:
        await t.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updatedAt = ? WHERE id = ?',
          [txn.amount * sign, nowIso, txn.accountId],
        );
        break;
      case TxnType.expense:
        await t.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updatedAt = ? WHERE id = ?',
          [txn.amount * sign, nowIso, txn.accountId],
        );
        break;
      case TxnType.transfer:
        if (txn.transferToAccountId == null) break;
        await t.rawUpdate(
          'UPDATE accounts SET balance = balance - ?, updatedAt = ? WHERE id = ?',
          [txn.amount * sign, nowIso, txn.accountId],
        );
        await t.rawUpdate(
          'UPDATE accounts SET balance = balance + ?, updatedAt = ? WHERE id = ?',
          [txn.amount * sign, nowIso, txn.transferToAccountId],
        );
        break;
    }
  }

  /// Total income/expense untuk rentang waktu.
  Future<({double income, double expense})> sums({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await DB.instance.database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.toIso8601String());
    }
    final whereSql = where.isEmpty ? '' : 'AND ${where.join(' AND ')}';

    final incomeRow = await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) AS s FROM transactions WHERE type='income' $whereSql",
      args,
    );
    final expenseRow = await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) AS s FROM transactions WHERE type='expense' $whereSql",
      args,
    );
    return (
      income: (incomeRow.first['s'] as num).toDouble(),
      expense: (expenseRow.first['s'] as num).toDouble(),
    );
  }

  /// Total expense per kategori (untuk budget & report).
  Future<Map<String, double>> expenseByCategory({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await DB.instance.database;
    final rows = await db.rawQuery(
      "SELECT categoryId, COALESCE(SUM(amount),0) AS total "
      "FROM transactions "
      "WHERE type='expense' AND date >= ? AND date <= ? AND categoryId IS NOT NULL "
      "GROUP BY categoryId",
      [from.toIso8601String(), to.toIso8601String()],
    );
    final map = <String, double>{};
    for (final r in rows) {
      map[r['categoryId'] as String] = (r['total'] as num).toDouble();
    }
    return map;
  }

  /// Time-series harian income vs expense untuk grafik laporan.
  Future<List<({DateTime day, double income, double expense})>> dailySeries({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await DB.instance.database;
    final rows = await db.rawQuery(
      "SELECT substr(date, 1, 10) AS d, type, COALESCE(SUM(amount),0) AS total "
      "FROM transactions WHERE date >= ? AND date <= ? AND type IN ('income','expense') "
      "GROUP BY substr(date, 1, 10), type ORDER BY d ASC",
      [from.toIso8601String(), to.toIso8601String()],
    );
    final map = <String, ({double income, double expense})>{};
    for (final r in rows) {
      final d = r['d'] as String;
      final type = r['type'] as String;
      final total = (r['total'] as num).toDouble();
      final prev = map[d] ?? (income: 0.0, expense: 0.0);
      map[d] = type == 'income'
          ? (income: prev.income + total, expense: prev.expense)
          : (income: prev.income, expense: prev.expense + total);
    }
    final entries = map.entries
        .map((e) =>
            (day: DateTime.parse(e.key), income: e.value.income, expense: e.value.expense))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return entries;
  }
}
