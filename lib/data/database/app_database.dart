import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Transactions, Categories, Budgets, RecurringPayments, Tags, TransactionTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTest(super.connection);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // User requested "refait depuis 0" (reset from scratch)
      // This wipes all data and creates the database with the latest schema.
      await transaction(() async {
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 2000');
    },
  );

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

