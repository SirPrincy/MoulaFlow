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
      isRecurring: entity.isRecurring,
      relatedDebtId: entity.relatedDebtId,
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
      isRecurring: Value(tx.isRecurring),
      relatedDebtId: Value(tx.relatedDebtId),
    );
  }

  Stream<List<Transaction>> watchTransactions() {
    return appDb.select(appDb.transactions).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<Transaction>> loadTransactions() async {
    final entities = await appDb.select(appDb.transactions).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await appDb.transaction(() async {
      await appDb.delete(appDb.transactions).go();
      for (final tx in transactions) {
        await appDb.into(appDb.transactions).insert(_mapModelToCompanion(tx));
      }
    });
  }

  Future<void> insertTransaction(Transaction tx) async {
    await appDb.into(appDb.transactions).insert(_mapModelToCompanion(tx), mode: InsertMode.replace);
  }

  Future<void> updateTransaction(Transaction tx) async {
    await appDb.update(appDb.transactions).replace(_mapModelToCompanion(tx));
  }

  Future<void> deleteTransaction(String id) async {
    await (appDb.delete(appDb.transactions)..where((tbl) => tbl.id.equals(id))).go();
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
