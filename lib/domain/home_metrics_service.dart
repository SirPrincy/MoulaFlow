import 'package:moula_flow/domain/balance_service.dart';
import 'package:moula_flow/models.dart';

class HomeFlowMetrics {
  final double income;
  final double expenses;

  const HomeFlowMetrics({required this.income, required this.expenses});
}

class HomeMetrics {
  final double monthIncome;
  final double monthExpense;
  final double netWorth;
  final Map<String, double> spendByCategory;
  final List<Transaction> recents;

  const HomeMetrics({
    required this.monthIncome,
    required this.monthExpense,
    required this.netWorth,
    required this.spendByCategory,
    required this.recents,
  });
}

class HomeMetricsService {
  HomeMetricsService({BalanceService? balanceService})
    : _balanceService = balanceService ?? BalanceService();

  final BalanceService _balanceService;

  HomeMetrics compute({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required List<TransactionCategory> categories,
    Set<String> selectedWalletIds = const {},
    DateTime? now,
    int recentsLimit = 8,
  }) {
    final snapshotDate = now ?? DateTime.now();
    final filteredTransactions = _balanceService.filterTransactionsByWalletSelection(
      transactions,
      selectedWalletIds,
    );

    final monthIncome = _monthlyTotal(
      filteredTransactions,
      type: TransactionType.income,
      now: snapshotDate,
    );
    final monthExpense = _monthlyTotal(
      filteredTransactions,
      type: TransactionType.expense,
      now: snapshotDate,
    );

    final spendByCategory = <String, double>{};
    for (final tx in filteredTransactions.where((tx) => tx.type == TransactionType.expense)) {
      final categoryLabel = _categoryName(tx.categoryId, categories);
      final key = categoryLabel.split('>').last.trim();
      spendByCategory[key] = (spendByCategory[key] ?? 0) + tx.amount.abs();
    }

    final recents = [...filteredTransactions]..sort((a, b) => b.date.compareTo(a.date));

    return HomeMetrics(
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      netWorth: _balanceService.computeTotalBalance(wallets, transactions, selectedWalletIds),
      spendByCategory: spendByCategory,
      recents: recents.take(recentsLimit).toList(),
    );
  }

  double _monthlyTotal(
    List<Transaction> txs, {
    required TransactionType type,
    required DateTime now,
  }) {
    return txs
        .where((tx) => tx.type == type && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  String _categoryName(String? id, List<TransactionCategory> categories) {
    final (main, sub) = TransactionCategory.getNamesFromId(id, categories);
    return sub == null ? main : '$main > $sub';
  }
}
