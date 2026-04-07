import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/data/database/app_database.dart';

void main() {
  test('upgrade 8 -> 9 preserves existing rows and creates projects table', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        db.execute('PRAGMA user_version = 8;');
        db.execute('''
          CREATE TABLE wallets (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            initial_balance REAL NOT NULL DEFAULT 0.0,
            type INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            target_amount REAL,
            due_date INTEGER,
            is_settled INTEGER NOT NULL DEFAULT 0,
            is_credit INTEGER NOT NULL DEFAULT 0,
            interest_rate REAL
          );
        ''');
        db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY NOT NULL,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            type INTEGER NOT NULL,
            date INTEGER NOT NULL,
            wallet_id TEXT,
            from_wallet_id TEXT,
            to_wallet_id TEXT,
            category_id TEXT,
            tags TEXT NOT NULL DEFAULT '',
            related_debt_id TEXT,
            recurring_payment_id TEXT
          );
        ''');
        db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY NOT NULL,
            name TEXT NOT NULL,
            parent_id TEXT
          );
        ''');
        db.execute(
          "INSERT INTO wallets (id, name, initial_balance, type, created_at, is_settled, is_credit) VALUES ('w1', 'Main', 12.5, 0, 1712448000000, 0, 0);",
        );
      },
    );

    final appDb = AppDatabase.forTest(executor);

    final walletCountRow = await appDb.customSelect('SELECT COUNT(*) AS c FROM wallets;').getSingle();
    expect(walletCountRow.read<int>('c'), 1);

    final projectsTableRow = await appDb
        .customSelect("SELECT COUNT(*) AS c FROM sqlite_master WHERE type='table' AND name='projects';")
        .getSingle();
    expect(projectsTableRow.read<int>('c'), 1);

    await appDb.close();
  });
}
