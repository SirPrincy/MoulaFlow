import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class MigrationResult {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final bool changed;

  MigrationResult({
    required this.transactions,
    required this.wallets,
    required this.changed,
  });
}

class TransactionRepository {
  final AppDatabase db;

  TransactionRepository(this.db);

  Transaction _mapEntityToModel(TransactionEntity entity) {
    return Transaction(
      id: entity.id,
      amount: entity.amount,
      description: entity.description,
      type: entity.type,
      date: entity.date,
      walletId: entity.walletId,
      fromWalletId: entity.fromWalletId,
      toWalletId: entity.toWalletId,
      categoryId: entity.categoryId,
      tags: entity.tags,
      relatedDebtId: entity.relatedDebtId,
      recurringPaymentId: entity.recurringPaymentId,
    );
  }

  TransactionsCompanion _mapModelToCompanion(Transaction tx) {
    return TransactionsCompanion(
      id: Value(tx.id),
      amount: Value(tx.amount),
      description: Value(tx.description),
      type: Value(tx.type),
      date: Value(tx.date),
      walletId: Value(tx.walletId),
      fromWalletId: Value(tx.fromWalletId),
      toWalletId: Value(tx.toWalletId),
      categoryId: Value(tx.categoryId),
      tags: Value(tx.tags),
      relatedDebtId: Value(tx.relatedDebtId),
      recurringPaymentId: Value(tx.recurringPaymentId),
    );
  }

  Future<List<String>> _getTagsForTransaction(String txId) async {
    final query = db.select(db.tags).join([
      innerJoin(db.transactionTags, db.transactionTags.tagId.equalsExp(db.tags.id)),
    ])
      ..where(db.transactionTags.transactionId.equals(txId));
    final rows = await query.get();
    return rows.map((row) => row.readTable(db.tags).name).toList();
  }

  Stream<List<Transaction>> watchTransactionsByTag(String tagName) {
    final query = db.select(db.transactions).join([
      innerJoin(db.transactionTags, db.transactionTags.transactionId.equalsExp(db.transactions.id)),
      innerJoin(db.tags, db.tags.id.equalsExp(db.transactionTags.tagId)),
    ])
      ..where(db.tags.name.equals(tagName));

    return query.watch().asyncMap((rows) async {
      final List<Transaction> result = [];
      for (final row in rows) {
        final entity = row.readTable(db.transactions);
        final tags = await _getTagsForTransaction(entity.id);
        result.add(_mapEntityToModel(entity).copyWith(tags: tags));
      }
      return result;
    });
  }

  Stream<List<Transaction>> watchTransactions() {
    // We use a stream of the transactions table and then fetch tags for each
    return db.select(db.transactions).watch().asyncMap((entities) async {
      final List<Transaction> result = [];
      for (final entity in entities) {
        final tags = await _getTagsForTransaction(entity.id);
        result.add(_mapEntityToModel(entity).copyWith(tags: tags));
      }
      return result;
    });
  }

  Future<List<Transaction>> loadTransactions() async {
    final entities = await db.select(db.transactions).get();
    final List<Transaction> result = [];
    for (final entity in entities) {
      final tags = await _getTagsForTransaction(entity.id);
      result.add(_mapEntityToModel(entity).copyWith(tags: tags));
    }
    return result;
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await db.transaction(() async {
      await db.delete(db.transactions).go();
      for (final tx in transactions) {
        await db.into(db.transactions).insert(_mapModelToCompanion(tx));
      }
    });
  }

  Future<void> _syncTags(String txId, List<String> tagNames) async {
    // 1. Delete old links
    await (db.delete(db.transactionTags)..where((t) => t.transactionId.equals(txId))).go();

    // 2. Add new links
    for (final name in tagNames) {
      // Find or create tag
      var tag = await (db.select(db.tags)..where((t) => t.name.equals(name))).getSingleOrNull();
      if (tag == null) {
        final newId = DateTime.now().millisecondsSinceEpoch.toString() + name.hashCode.toString();
        await db.into(db.tags).insert(TagsCompanion.insert(
              id: newId,
              name: name,
              type: TagType.custom,
              createdAt: DateTime.now(),
            ));
        tag = await (db.select(db.tags)..where((t) => t.id.equals(newId))).getSingle();
      }
      
      await db.into(db.transactionTags).insert(TransactionTagsCompanion.insert(
            transactionId: txId,
            tagId: tag.id,
          ), mode: InsertMode.insertOrIgnore);
    }
  }

  Future<void> insertTransaction(Transaction tx) async {
    await db.transaction(() async {
      await db.into(db.transactions).insert(_mapModelToCompanion(tx), mode: InsertMode.replace);
      await _syncTags(tx.id, tx.tags);
    });
  }

  Future<void> updateTransaction(Transaction tx) async {
    await db.transaction(() async {
      await db.update(db.transactions).replace(_mapModelToCompanion(tx));
      await _syncTags(tx.id, tx.tags);
    });
  }

  Future<void> deleteTransaction(String id) async {
    await db.transaction(() async {
      await (db.delete(db.transactionTags)..where((t) => t.transactionId.equals(id))).go();
      await (db.delete(db.transactions)..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// Migrates transactions to the new format if needed.
  /// Logic preserved from the original HomePage implementation.
  MigrationResult migrateIfNeeded(List<Transaction> transactions, List<Wallet> wallets) {
    bool needsSave = false;
    List<Transaction> migratedTxs = List.from(transactions);
    List<Wallet> migratedWallets = List.from(wallets);

    if (migratedTxs.isNotEmpty && migratedWallets.isEmpty) {
      final mainWallet = Wallet(id: 'main_wallet', name: 'Compte Principal');
      migratedWallets.add(mainWallet);

      migratedTxs = migratedTxs.map((tx) {
        String? cId = tx.categoryId;
        if (cId == null && tx.type != TransactionType.transfer) cId = 'cat_divers';

        if (tx.walletId == null && tx.fromWalletId == null && tx.toWalletId == null) {
          return Transaction(
            id: tx.id,
            amount: tx.amount,
            description: tx.description,
            type: tx.type,
            date: tx.date,
            walletId: mainWallet.id,
            categoryId: cId,
            tags: tx.tags,
          );
        } else if (tx.categoryId == null && tx.type != TransactionType.transfer) {
          return Transaction(
            id: tx.id,
            amount: tx.amount,
            description: tx.description,
            type: tx.type,
            date: tx.date,
            walletId: tx.walletId,
            fromWalletId: tx.fromWalletId,
            toWalletId: tx.toWalletId,
            categoryId: cId,
            tags: tx.tags,
          );
        }
        return tx;
      }).toList();
      needsSave = true;
    } else if (migratedWallets.isEmpty) {
      migratedWallets.add(Wallet(id: 'main_wallet', name: 'Compte Principal'));
      needsSave = true;
    } else {
      // Migrate existing txs that miss categoryId
      List<Transaction> updatedTxs = [];
      for (var tx in migratedTxs) {
        if (tx.categoryId == null && tx.type != TransactionType.transfer) {
          updatedTxs.add(Transaction(
            id: tx.id,
            amount: tx.amount,
            description: tx.description,
            type: tx.type,
            date: tx.date,
            walletId: tx.walletId,
            fromWalletId: tx.fromWalletId,
            toWalletId: tx.toWalletId,
            categoryId: 'cat_divers',
            tags: tx.tags,
          ));
          needsSave = true;
        } else {
          updatedTxs.add(tx);
        }
      }
      migratedTxs = updatedTxs;
    }

    return MigrationResult(
      transactions: migratedTxs,
      wallets: migratedWallets,
      changed: needsSave,
    );
  }
}
