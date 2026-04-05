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
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Recreate everything for very old versions (destructive)
        for (final table in allTables) {
          await m.drop(table);
        }
        await m.createAll();
      } else if (from == 2) {
        // Version 2 -> 3: Migration safely handled here.
      } else if (from == 3) {
        // Version 3 -> 4: Tag migration
        await m.createTable(tags);
        await m.createTable(transactionTags);

        // Migrate existing tags from Transactions.tags to the new table
        final allTransactions = await select(transactions).get();
        for (var tx in allTransactions) {
          if (tx.tags.isNotEmpty) {
            for (var tagName in tx.tags) {
              // Check if tag already exists (simplistic check)
              // Note: In a real large DB this should be optimized, but here it's fine.
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

              // Create link
              await into(transactionTags).insert(TransactionTagsCompanion.insert(
                transactionId: tx.id,
                tagId: tagId,
              ), mode: InsertMode.insertOrIgnore);
            }
          }
        }
      } else if (from == 4) {
        // Version 4 -> 5: Added executionMode to RecurringPayments
        await m.addColumn(recurringPayments, recurringPayments.executionMode);
      }
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

