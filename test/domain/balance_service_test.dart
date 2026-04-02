import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/domain/balance_service.dart';

void main() {
  final service = BalanceService();
  final wallet1 = Wallet(id: 'w1', name: 'Wallet 1', initialBalance: 100.0);
  final wallet2 = Wallet(id: 'w2', name: 'Wallet 2', initialBalance: 50.0);
  final wallets = [wallet1, wallet2];

  group('BalanceService - computeTotalBalance', () {
    test('total global sans filtre', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 20.0,
          description: 'd1',
          type: TransactionType.income,
          date: DateTime.now(),
          walletId: 'w1',
        ),
        Transaction(
          id: 't2',
          amount: 10.0,
          description: 'd2',
          type: TransactionType.expense,
          date: DateTime.now(),
          walletId: 'w2',
        ),
      ];

      // 100 + 50 + 20 - 10 = 160
      final result = service.computeTotalBalance(wallets, transactions, {});
      expect(result, 160.0);
    });

    test('total avec wallets sélectionnés', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 20.0,
          description: 'd1',
          type: TransactionType.income,
          date: DateTime.now(),
          walletId: 'w1',
        ),
        Transaction(
          id: 't2',
          amount: 10.0,
          description: 'd2',
          type: TransactionType.expense,
          date: DateTime.now(),
          walletId: 'w2',
        ),
        Transaction(
          id: 't3',
          amount: 5.0,
          description: 'd3',
          type: TransactionType.transfer,
          date: DateTime.now(),
          fromWalletId: 'w1',
          toWalletId: 'w2',
        ),
      ];

      // Sélectionner w1 uniquement
      // Initial w1 (100) + income t1 (20) - transfer t3 out (5) = 115
      final result = service.computeTotalBalance(wallets, transactions, {'w1'});
      expect(result, 115.0);
    });
  });

  group('BalanceService - computeWalletBalance', () {
    test('balance d’un wallet avec transferts entrants/sortants', () {
      final transactions = [
        Transaction(
          id: 't1',
          amount: 50.0,
          description: 'd1',
          type: TransactionType.income,
          date: DateTime.now(),
          walletId: 'w1',
        ),
        Transaction(
          id: 't2',
          amount: 10.0,
          description: 'd2',
          type: TransactionType.transfer,
          date: DateTime.now(),
          fromWalletId: 'w1',
          toWalletId: 'w2',
        ),
        Transaction(
          id: 't3',
          amount: 20.0,
          description: 'd3',
          type: TransactionType.transfer,
          date: DateTime.now(),
          fromWalletId: 'w2',
          toWalletId: 'w1',
        ),
      ];

      // w1: 100 (init) + 50 (income) - 10 (out) + 20 (in) = 160
      final result = service.computeWalletBalance('w1', wallets, transactions);
      expect(result, 160.0);
    });
  });

  group('BalanceService - filterTransactionsByWalletSelection', () {
    test('filtre les transactions par wallet', () {
       final transactions = [
        Transaction(id: 't1', amount: 1, description: '', type: TransactionType.income, date: DateTime.now(), walletId: 'w1'),
        Transaction(id: 't2', amount: 1, description: '', type: TransactionType.expense, date: DateTime.now(), walletId: 'w2'),
        Transaction(id: 't3', amount: 1, description: '', type: TransactionType.transfer, date: DateTime.now(), fromWalletId: 'w1', toWalletId: 'w2'),
      ];

      final filtered = service.filterTransactionsByWalletSelection(transactions, {'w1'});
      expect(filtered.length, 2);
      expect(filtered.any((tx) => tx.id == 't1'), isTrue);
      expect(filtered.any((tx) => tx.id == 't3'), isTrue);
      expect(filtered.any((tx) => tx.id == 't2'), isFalse);
    });
  });
}
