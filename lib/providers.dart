import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/data/transaction_repository.dart';
import 'package:moula_flow/data/wallet_repository.dart';
import 'package:moula_flow/data/category_repository.dart';
import 'package:moula_flow/data/budget_repository.dart';
import 'package:moula_flow/data/recurring_payment_repository.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/domain/balance_service.dart';

final transactionRepositoryProvider = Provider((ref) => TransactionRepository());
final walletRepositoryProvider = Provider((ref) => WalletRepository());
final categoryRepositoryProvider = Provider((ref) => CategoryRepository());
final budgetRepositoryProvider = Provider((ref) => BudgetRepository());
final recurringPaymentRepositoryProvider = Provider((ref) => RecurringPaymentRepository());
final balanceServiceProvider = Provider((ref) => BalanceService());

final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  return ref.watch(walletRepositoryProvider).watchWallets();
});

final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchTransactions();
});

final categoriesProvider = StreamProvider<List<TransactionCategory>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final budgetsProvider = StreamProvider<List<BudgetPlan>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchBudgets();
});

final recurringPaymentsProvider = StreamProvider<List<RecurringPayment>>((ref) {
  return ref.watch(recurringPaymentRepositoryProvider).watchRecurringPayments();
});
