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
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Safety: Run migrations in order
      if (from < 2) {
        for (final table in allTables) await m.drop(table);
        await m.createAll();
        return; // Fresh start
      }

      if (from < 4) {
        await m.createTable(tags);
        await m.createTable(transactionTags);

        // Migrate existing tags from Transactions.tags to the new table
        final allTransactions = await select(transactions).get();
        for (var tx in allTransactions) {
          if (tx.tags.isNotEmpty) {
            for (var tagName in tx.tags) {
              String tagId;
              final existingTag = await (select(tags)..where((t) => t.name.equals(tagName))).getSingleOrNull();
              
              if (existingTag == null) {
                tagId = DateTime.now().millisecondsSinceEpoch.toString() + tagName.hashCode.toString();
                await into(tags).insert(TagsCompanion.insert(
                  id: tagId,
                  name: tagName,
                  type: TagType.custom,
                  createdAt: DateTime.now(),
                ));
              } else {
                tagId = existingTag.id;
              }

              await into(transactionTags).insert(TransactionTagsCompanion.insert(
                transactionId: tx.id,
                tagId: tagId,
              ), mode: InsertMode.insertOrIgnore);
            }
          }
        }
      }

      if (from < 5) {
        await m.addColumn(recurringPayments, recurringPayments.executionMode);
      }

      if (from < 6) {
        // v6 added missing columns to RecurringPayments
        await m.addColumn(recurringPayments, recurringPayments.description);
        await m.addColumn(recurringPayments, recurringPayments.tags);
        await m.addColumn(recurringPayments, recurringPayments.isActive);
      }

      if (from < 7) {
        // v7 ensures all data is consistent and defaults are applied
        await customStatement("UPDATE recurring_payments SET execution_mode = 0 WHERE execution_mode IS NULL");
        await customStatement("UPDATE recurring_payments SET description = '' WHERE description IS NULL");
        await customStatement("UPDATE recurring_payments SET tags = '' WHERE tags IS NULL");
        await customStatement("UPDATE recurring_payments SET is_active = 1 WHERE is_active IS NULL");
        
        final nowStr = DateTime.now().toIso8601String();
        await customStatement("UPDATE recurring_payments SET start_date = '$nowStr' WHERE start_date IS NULL");
        await customStatement("UPDATE recurring_payments SET next_due_date = '$nowStr' WHERE next_due_date IS NULL");
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
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

