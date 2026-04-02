import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'storage_keys.dart';

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
  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txData = prefs.getString(StorageKeys.transactions);
    if (txData != null) {
      final List<dynamic> jsonList = jsonDecode(txData);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.transactions, jsonEncode(transactions.map((tx) => tx.toJson()).toList()));
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
