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
import 'package:moula_flow/data/tag_repository.dart';
import 'package:moula_flow/domain/budget_planning_service.dart';
import 'package:moula_flow/utils/app_constants.dart';
import 'package:flutter/material.dart';

final databaseProvider = Provider((ref) => AppDatabase());
final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref.watch(databaseProvider)));
final walletRepositoryProvider = Provider((ref) => WalletRepository(ref.watch(databaseProvider)));
final categoryRepositoryProvider = Provider((ref) => CategoryRepository(ref.watch(databaseProvider)));
final budgetRepositoryProvider = Provider((ref) => BudgetRepository(ref.watch(databaseProvider)));
final recurringPaymentRepositoryProvider = Provider((ref) => RecurringPaymentRepository(ref.watch(databaseProvider)));
final tagRepositoryProvider = Provider((ref) => TagRepository(ref.watch(databaseProvider)));
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

final tagsProvider = StreamProvider<List<TagDefinition>>((ref) {
  return ref.watch(tagRepositoryProvider).watchTags();
});

final budgetPlanningServiceProvider = Provider((ref) => BudgetPlanningService());

final budgetStatusProvider = FutureProvider.autoDispose.family<BudgetStatus, String>((ref, budgetId) async {
  // 1. Establish synchronous dependencies first (CRITICAL for Riverpod stability)
  final budgetsAsync = ref.watch(budgetsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final service = ref.watch(budgetPlanningServiceProvider);

  // 2. Resolve data (waiting for first emission if needed)
  final List<BudgetPlan> budgets = budgetsAsync.asData?.value ?? await ref.watch(budgetsProvider.future);
  final List<Transaction> transactions = transactionsAsync.asData?.value ?? await ref.watch(transactionsProvider.future);

  final plan = budgets.cast<BudgetPlan?>().firstWhere((b) => b?.id == budgetId, orElse: () => null);
  if (plan == null) throw Exception('Budget not found: $budgetId');

  final filtered = service.filterTransactions(
    transactions: transactions,
    start: plan.startDate,
    end: plan.endDate,
    walletIds: plan.walletIds.toSet(),
    categoryIds: plan.categoryIds.toSet(),
    tags: plan.tags.toSet(),
    excludedTags: plan.excludedTags.toSet(),
  );
  final spent = service.computeSpent(filtered);
  final projection = service.projectBudget(
    spent: spent,
    totalBudget: plan.amount,
    start: plan.startDate,
    end: plan.endDate,
    now: DateTime.now(),
  );

  return BudgetStatus(
    plan: plan,
    spent: spent,
    percentage: plan.amount > 0 ? spent / plan.amount : 0,
    remaining: (plan.amount - spent).clamp(0, double.infinity),
    transactions: filtered,
    projection: projection,
  );
});

final activeBudgetsProvider = Provider<AsyncValue<List<BudgetPlan>>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  return budgetsAsync.whenData((budgets) {
    final now = DateTime.now();
    // Sort by end date (closest first)
    final active = budgets.where((b) => b.endDate.isAfter(now) || b.endDate.isAtSameMomentAs(now)).toList();
    active.sort((a, b) => a.endDate.compareTo(b.endDate));
    return active;
  });
});

// Settings Providers
class ThemeModeNotifier extends Notifier<ThemeMode> {
  final ThemeMode? _initial;
  ThemeModeNotifier([this._initial]);

  @override
  ThemeMode build() => _initial ?? ThemeMode.system;
  
  void update(ThemeMode mode) {
    state = mode;
    // Persist change
    final isDark = mode == ThemeMode.dark;
    ref.read(settingsRepositoryProvider).saveIsDarkMode(isDark);
  }
}
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class OnboardingSeenNotifier extends Notifier<bool> {
  final bool? _initial;
  OnboardingSeenNotifier([this._initial]);

  @override
  bool build() => _initial ?? false;
  
  void update(bool seen) {
    state = seen;
    ref.read(settingsRepositoryProvider).saveOnboardingSeen(seen);
  }
}
final onboardingSeenProvider = NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);

class AppAccessMethodNotifier extends Notifier<AppAccessMethod> {
  final AppAccessMethod? _initial;
  AppAccessMethodNotifier([this._initial]);

  @override
  AppAccessMethod build() => _initial ?? AppAccessMethod.none;
  
  void update(AppAccessMethod method) {
    state = method;
    ref.read(settingsRepositoryProvider).saveAppAccessMethod(method);
  }
}
final appAccessMethodProvider = NotifierProvider<AppAccessMethodNotifier, AppAccessMethod>(AppAccessMethodNotifier.new);

class UserNameNotifier extends Notifier<String?> {
  final String? _initial;
  UserNameNotifier([this._initial]);

  @override
  String? build() => _initial ?? AppConstants.defaultUserName;
  
  void update(String? name) {
    state = name;
    if (name != null) {
      ref.read(settingsRepositoryProvider).saveUserName(name);
    }
  }
}
final userNameProvider = NotifierProvider<UserNameNotifier, String?>(UserNameNotifier.new);

class UserColorNotifier extends Notifier<int> {
  final int? _initial;
  UserColorNotifier([this._initial]);

  @override
  int build() => _initial ?? 0xFF6200EE;
  
  void update(int color) {
    state = color;
    ref.read(settingsRepositoryProvider).saveUserColor(color);
  }
}
final userColorProvider = NotifierProvider<UserColorNotifier, int>(UserColorNotifier.new);

class UserAvatarNotifier extends Notifier<int> {
  final int? _initial;
  UserAvatarNotifier([this._initial]);

  @override
  int build() => _initial ?? AppConstants.defaultUserAvatar;
  
  void update(int codePoint) {
    state = codePoint;
    ref.read(settingsRepositoryProvider).saveUserAvatar(codePoint);
  }
}
final userAvatarProvider = NotifierProvider<UserAvatarNotifier, int>(UserAvatarNotifier.new);

class AccentColorNotifier extends Notifier<Color> {
  final int? _initial;
  AccentColorNotifier([this._initial]);

  @override
  Color build() => Color(_initial ?? 0xFFBCC2FF); // Default Moula Primary
  
  void update(Color color) {
    state = color;
    ref.read(settingsRepositoryProvider).saveAccentColor(color.toARGB32());
  }
}
final accentColorProvider = NotifierProvider<AccentColorNotifier, Color>(AccentColorNotifier.new);

class CurrencySymbolNotifier extends Notifier<String> {
  final String? _initial;
  CurrencySymbolNotifier([this._initial]);

  @override
  String build() => _initial ?? 'Ar';
  
  void update(String symbol) {
    state = symbol;
    ref.read(settingsRepositoryProvider).saveCurrencySymbol(symbol);
  }
}
final currencySymbolProvider = NotifierProvider<CurrencySymbolNotifier, String>(CurrencySymbolNotifier.new);

class DecimalDigitsNotifier extends Notifier<int> {
  final int? _initial;
  DecimalDigitsNotifier([this._initial]);

  @override
  int build() => _initial ?? 2;
  
  void update(int digits) {
    state = digits;
    ref.read(settingsRepositoryProvider).saveDecimalDigits(digits);
  }
}
final decimalDigitsProvider = NotifierProvider<DecimalDigitsNotifier, int>(DecimalDigitsNotifier.new);

class BiometricsEnabledNotifier extends Notifier<bool> {
  final bool? _initial;
  BiometricsEnabledNotifier([this._initial]);

  @override
  bool build() => _initial ?? false;
  
  void update(bool enabled) {
    state = enabled;
    ref.read(settingsRepositoryProvider).saveBiometricsEnabled(enabled);
  }
}
final biometricsEnabledProvider = NotifierProvider<BiometricsEnabledNotifier, bool>(BiometricsEnabledNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  final String? _initial;
  LocaleNotifier([this._initial]);

  @override
  Locale? build() => _initial != null ? Locale(_initial) : null;
  
  void update(String? languageCode) {
    state = languageCode != null ? Locale(languageCode) : null;
    if (languageCode != null) {
      ref.read(settingsRepositoryProvider).saveLanguageCode(languageCode);
    }
  }
}
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

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
