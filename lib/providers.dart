import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/data/database/app_database.dart';
import 'package:moula_flow/data/transaction_repository.dart';
import 'package:moula_flow/data/wallet_repository.dart';
import 'package:moula_flow/data/category_repository.dart';
import 'package:moula_flow/data/budget_repository.dart';
import 'package:moula_flow/data/recurring_payment_repository.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/domain/balance_service.dart';
import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/data/dashboard_repository.dart';
import 'package:moula_flow/data/app_access_method.dart';
import 'package:flutter/material.dart';

final databaseProvider = Provider((ref) => AppDatabase());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final walletRepositoryProvider = Provider((ref) => WalletRepository(ref.watch(databaseProvider)));
final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final recurringPaymentRepositoryProvider = Provider((ref) => RecurringPaymentRepository(ref.watch(databaseProvider)));
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

// Settings Providers
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final onboardingSeenProvider = StateProvider<bool>((ref) => false);
final appAccessMethodProvider = StateProvider<AppAccessMethod>((ref) => AppAccessMethod.none);

// Dashboard Config Notifier
class DashboardNotifier extends StateNotifier<AsyncValue<DashboardConfig>> {
  final DashboardRepository _repository;
  DashboardNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.loadConfig());
  }

  Future<void> updateConfig(DashboardConfig config) async {
    await _repository.saveConfig(config);
    state = AsyncValue.data(config);
  }
}

final dashboardConfigProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardConfig>>((ref) {
  return DashboardNotifier(ref.watch(dashboardRepositoryProvider));
});
