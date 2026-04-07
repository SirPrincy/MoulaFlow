import 'dart:io';
import 'dart:developer' as developer;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Transactions, Categories, Budgets, RecurringPayments, Tags, TransactionTags, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTest(super.connection);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      developer.log('DB migration started', name: 'AppDatabase', error: {'from': from, 'to': to});
      await transaction(() async {
        if (from < 9) {
          await m.createTable(projects);
        }
        if (from < 10) {
          if (await _tableExists('wallets')) {
            await m.addColumn(wallets, wallets.updatedAt as dynamic);
            await m.addColumn(wallets, wallets.deletedAt as dynamic);
          }
          if (await _tableExists('categories')) {
            await m.addColumn(categories, categories.deletedAt as dynamic);
            await m.alterTable(TableMigration(categories));
          }
          if (await _tableExists('budgets')) {
            await m.addColumn(budgets, budgets.updatedAt as dynamic);
            await m.alterTable(TableMigration(budgets));
          }
          if (await _tableExists('transactions')) {
            await m.addColumn(transactions, transactions.isCleared as dynamic);
            await m.alterTable(TableMigration(transactions));
          }
          if (await _tableExists('recurring_payments')) {
            await m.alterTable(TableMigration(recurringPayments));
          }
          if (await _tableExists('projects')) {
            await m.alterTable(TableMigration(projects));
          }
        }
      });
      developer.log('DB migration completed', name: 'AppDatabase', error: {'from': from, 'to': to});
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 2000');
      await _runIntegrityChecks();
    },
  );

  Future<void> _runIntegrityChecks() async {
    final integrity = await customSelect('PRAGMA integrity_check;').getSingle();
    final integrityStatus = integrity.data.values.first.toString().toLowerCase();
    if (integrityStatus != 'ok') {
      developer.log('SQLite integrity_check failed: $integrityStatus', name: 'AppDatabase');
      throw StateError('Database integrity check failed: $integrityStatus');
    }

    for (final tableName in const ['wallets', 'transactions', 'categories']) {
      final exists = await customSelect(
        "SELECT COUNT(*) AS c FROM sqlite_master WHERE type='table' AND name=?;",
        variables: [Variable.withString(tableName)],
      ).getSingle();
      if (exists.read<int>('c') == 0) {
        developer.log('Missing critical table: $tableName', name: 'AppDatabase');
        throw StateError('Critical table missing after open: $tableName');
      }
    }
  }

  Future<bool> _tableExists(String tableName) async {
    final exists = await customSelect(
      "SELECT COUNT(*) AS c FROM sqlite_master WHERE type='table' AND name=?;",
      variables: [Variable.withString(tableName)],
    ).getSingle();
    return exists.read<int>('c') > 0;
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  static Future<String> getDbFilePath() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'moula_flow.sqlite');
  }

  Future<void> hardClose() async {
    await close();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'moula_flow.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// final appDb = AppDatabase();
