import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/domain/home_metrics_service.dart';
import 'package:moula_flow/models.dart';

void main() {
  final service = HomeMetricsService();

  final wallets = [
    Wallet(id: 'w1', name: 'Cash', initialBalance: 100),
    Wallet(id: 'w2', name: 'Bank', initialBalance: 50),
  ];

  final categories = [
    TransactionCategory(
      id: 'food',
      name: 'Food',
      subcategories: [TransactionCategory(id: 'resto', name: 'Restaurant')],
    ),
  ];

  final txs = [
    Transaction(
      id: 't1',
      amount: 100,
      description: 'salary',
      type: TransactionType.income,
      date: DateTime(2026, 4, 2),
      walletId: 'w1',
    ),
    Transaction(
      id: 't2',
      amount: 30,
      description: 'lunch',
      type: TransactionType.expense,
      date: DateTime(2026, 4, 3),
      walletId: 'w1',
      categoryId: 'resto',
    ),
    Transaction(
      id: 't3',
      amount: 25,
      description: 'old month',
      type: TransactionType.expense,
      date: DateTime(2026, 3, 25),
      walletId: 'w1',
      categoryId: 'food',
    ),
    Transaction(
      id: 't4',
      amount: 40,
      description: 'w2 salary',
      type: TransactionType.income,
      date: DateTime(2026, 4, 1),
      walletId: 'w2',
    ),
  ];

  test('compute monthly income/expense and net worth', () {
    final metrics = service.compute(
      transactions: txs,
      wallets: wallets,
      categories: categories,
      now: DateTime(2026, 4, 15),
      recentsLimit: 10,
    );

    expect(metrics.monthIncome, 140);
    expect(metrics.monthExpense, 30);
    expect(metrics.netWorth, 235);
    expect(metrics.spendByCategory['Restaurant'], 30);
    expect(metrics.recents.first.id, 't2');
  });

  test('respects selected wallets for dashboard metrics', () {
    final metrics = service.compute(
      transactions: txs,
      wallets: wallets,
      categories: categories,
      selectedWalletIds: const {'w2'},
      now: DateTime(2026, 4, 15),
    );

    expect(metrics.monthIncome, 40);
    expect(metrics.monthExpense, 0);
    expect(metrics.netWorth, 90);
  });
}
