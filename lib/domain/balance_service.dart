import '../models.dart';

class BalanceService {
  double computeTotalBalance(
    List<Wallet> wallets,
    List<Transaction> transactions,
    Set<String> selectedWalletIds,
  ) {
    double total = 0;
    if (selectedWalletIds.isEmpty) {
      for (var w in wallets) {
        total += w.initialBalance;
      }
      for (var tx in transactions) {
        if (tx.type == TransactionType.income) {
          total += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          total -= tx.amount;
        }
        // Transfers are internally neutral on the global balance
      }
    } else {
      for (var w in wallets.where((w) => selectedWalletIds.contains(w.id))) {
        total += w.initialBalance;
      }
      for (var tx in transactions) {
        if (tx.type == TransactionType.income && selectedWalletIds.contains(tx.walletId)) {
          total += tx.amount;
        } else if (tx.type == TransactionType.expense && selectedWalletIds.contains(tx.walletId)) {
          total -= tx.amount;
        } else if (tx.type == TransactionType.transfer) {
          if (selectedWalletIds.contains(tx.toWalletId)) total += tx.amount;
          if (selectedWalletIds.contains(tx.fromWalletId)) total -= tx.amount;
        }
      }
    }
    return total;
  }

  double computeWalletBalance(
    String walletId,
    List<Wallet> wallets,
    List<Transaction> transactions,
  ) {
    double total = 0;
    try {
      total += wallets.firstWhere((w) => w.id == walletId).initialBalance;
    } catch (_) {}

    for (var tx in transactions) {
      if (tx.type == TransactionType.income && tx.walletId == walletId) {
        total += tx.amount;
      } else if (tx.type == TransactionType.expense && tx.walletId == walletId) {
        total -= tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        if (tx.toWalletId == walletId) total += tx.amount;
        if (tx.fromWalletId == walletId) total -= tx.amount;
      }
    }
    return total;
  }

  List<Transaction> filterTransactionsByWalletSelection(
    List<Transaction> transactions,
    Set<String> selectedWalletIds,
  ) {
    if (selectedWalletIds.isEmpty) return List.from(transactions);
    return transactions.where((tx) {
      if (tx.type == TransactionType.transfer) {
        return selectedWalletIds.contains(tx.fromWalletId) ||
            selectedWalletIds.contains(tx.toWalletId);
      }
      return selectedWalletIds.contains(tx.walletId);
    }).toList();
  }

  List<double> computeHistoricalBalances(
    List<Wallet> wallets,
    List<Transaction> transactions,
    Set<String> selectedWalletIds,
    int days,
  ) {
    final List<double> history = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < days; i++) {
        final targetDate = today.subtract(Duration(days: i));
        final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

        double balanceAtDate = 0;
        
        // Sum initial balances of relevant wallets
        if (selectedWalletIds.isEmpty) {
            for (var w in wallets) { balanceAtDate += w.initialBalance; }
        } else {
            for (var w in wallets.where((w) => selectedWalletIds.contains(w.id))) { balanceAtDate += w.initialBalance; }
        }

        // Apply all transactions that happened ON or BEFORE the end of this day
        for (var tx in transactions) {
            if (tx.date.isAfter(endOfDay)) continue;

            if (selectedWalletIds.isEmpty) {
                if (tx.type == TransactionType.income) { balanceAtDate += tx.amount; }
                else if (tx.type == TransactionType.expense) { balanceAtDate -= tx.amount; }
            } else {
                if (tx.type == TransactionType.income && selectedWalletIds.contains(tx.walletId)) { balanceAtDate += tx.amount; }
                else if (tx.type == TransactionType.expense && selectedWalletIds.contains(tx.walletId)) { balanceAtDate -= tx.amount; }
                else if (tx.type == TransactionType.transfer) {
                    if (selectedWalletIds.contains(tx.toWalletId)) { balanceAtDate += tx.amount; }
                    if (selectedWalletIds.contains(tx.fromWalletId)) { balanceAtDate -= tx.amount; }
                }
            }
        }
        history.add(balanceAtDate);
    }

    return history.reversed.toList();
  }
}
