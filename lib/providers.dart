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
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode? _initial;
  ThemeModeNotifier([this._initial]);

  @override
  ThemeMode build() => _initial ?? ThemeMode.system;
  void update(ThemeMode mode) => state = mode;
}
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class OnboardingSeenNotifier extends Notifier<bool> {
  final bool? _initial;
  OnboardingSeenNotifier([this._initial]);

  @override
  bool build() => _initial ?? false;
  void update(bool seen) => state = seen;
}
final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);

class AppAccessMethodNotifier extends Notifier<AppAccessMethod> {
  final AppAccessMethod? _initial;
  AppAccessMethodNotifier([this._initial]);

  @override
  AppAccessMethod build() => _initial ?? AppAccessMethod.none;
  void update(AppAccessMethod method) => state = method;
}
final appAccessMethodProvider = NotifierProvider<AppAccessMethodNotifier, AppAccessMethod>(AppAccessMethodNotifier.new);

// Dashboard Config AsyncNotifier
class DashboardNotifier extends AsyncNotifier<DashboardConfig> {
  @override
  Future<DashboardConfig> build() async {
    return ref.watch(dashboardRepositoryProvider).loadConfig();
  }

  Future<void> updateConfig(DashboardConfig config) async {
    state = const AsyncLoading();
    await ref.read(dashboardRepositoryProvider).saveConfig(config);
    state = AsyncData(config);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(dashboardRepositoryProvider).loadConfig());
  }
}

final dashboardConfigProvider = AsyncNotifierProvider<DashboardNotifier, DashboardConfig>(DashboardNotifier.new);
