import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../models.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Wallets, Transactions, Categories, Budgets, RecurringPayments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTest(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < to) {
        // Simple for development: Recreate everything on schema change
        // You would typically handle each version upgrade specifically 
        // in a production app.
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'moula_flow.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// final appDb = AppDatabase();

