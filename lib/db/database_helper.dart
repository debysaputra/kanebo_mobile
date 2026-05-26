import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../theme/app_colors.dart';

class DB {
  DB._();
  static final DB instance = DB._();

  static const _dbName = 'kanebo.db';
  static const _dbVersion = 1;

  Database? _db;
  final _uuid = const Uuid();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0,
        colorValue INTEGER NOT NULL,
        icon TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        icon TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        categoryId TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        transferToAccountId TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (accountId) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY (transferToAccountId) REFERENCES accounts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_txn_date ON transactions(date DESC)');
    await db.execute(
        'CREATE INDEX idx_txn_account ON transactions(accountId)');
    await db.execute(
        'CREATE INDEX idx_txn_category ON transactions(categoryId)');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE,
        UNIQUE(categoryId, month, year)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0,
        deadline TEXT,
        colorValue INTEGER NOT NULL,
        icon TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        personName TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        dueDate TEXT,
        status TEXT NOT NULL DEFAULT 'unpaid',
        description TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Default akun: Tunai
    await db.insert('accounts', {
      'id': _uuid.v4(),
      'name': 'Tunai',
      'type': 'cash',
      'balance': 0,
      'colorValue': AppColors.tertiary.value,
      'icon': '💵',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    // Default kategori pengeluaran
    final expenseCats = [
      {'icon': '🍔', 'name': 'Makanan', 'color': 0xFFFF7AC6},
      {'icon': '🚗', 'name': 'Transportasi', 'color': 0xFF3B82F6},
      {'icon': '🛍️', 'name': 'Belanja', 'color': 0xFFA855F7},
      {'icon': '🏠', 'name': 'Tagihan', 'color': 0xFF14B8A6},
      {'icon': '🎬', 'name': 'Hiburan', 'color': 0xFFF97316},
      {'icon': '💊', 'name': 'Kesehatan', 'color': 0xFFEF4444},
      {'icon': '📚', 'name': 'Pendidikan', 'color': 0xFF7C5CFF},
      {'icon': '✨', 'name': 'Lainnya', 'color': 0xFF6B6480},
    ];

    final incomeCats = [
      {'icon': '💼', 'name': 'Gaji', 'color': 0xFF22C55E},
      {'icon': '🎁', 'name': 'Bonus', 'color': 0xFFFFB547},
      {'icon': '💸', 'name': 'Investasi', 'color': 0xFF22D3B4},
      {'icon': '✨', 'name': 'Lainnya', 'color': 0xFF6B6480},
    ];

    for (final c in expenseCats) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': c['name'],
        'type': 'expense',
        'colorValue': c['color'],
        'icon': c['icon'],
        'isDefault': 1,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    for (final c in incomeCats) {
      await db.insert('categories', {
        'id': _uuid.v4(),
        'name': c['name'],
        'type': 'income',
        'colorValue': c['color'],
        'icon': c['icon'],
        'isDefault': 1,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
