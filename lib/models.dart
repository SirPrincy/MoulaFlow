// No need for material import

enum WalletType { current, savings, debt, project, cash, bank, mobileMoney }

class Wallet {
  final String id;
  String name;
  double initialBalance;
  WalletType type;
  DateTime createdAt;
  double? targetAmount;
  DateTime? dueDate;
  bool isSettled;
  bool isCredit; // true if someone owes ME, false if I owe someone
  double? interestRate; // Annual interest rate in percentage (%)

  Wallet({
    required this.id,
    required this.name,
    this.initialBalance = 0.0,
    this.type = WalletType.current,
    DateTime? createdAt,
    this.targetAmount,
    this.dueDate,
    this.isSettled = false,
    this.isCredit = false,
    this.interestRate,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialBalance': initialBalance,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'targetAmount': targetAmount,
        'dueDate': dueDate?.toIso8601String(),
        'isSettled': isSettled,
        'isCredit': isCredit,
        'interestRate': interestRate,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'],
        name: json['name'],
        initialBalance: json['initialBalance']?.toDouble() ?? 0.0,
        type: WalletType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => WalletType.current,
        ),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        targetAmount: json['targetAmount']?.toDouble(),
        dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        isSettled: json['isSettled'] ?? false,
        isCredit: json['isCredit'] ?? false,
        interestRate: json['interestRate']?.toDouble(),
      );
}


class TransactionCategory {
  final String id;
  String name;
  List<TransactionCategory> subcategories;

  TransactionCategory({
    required this.id,
    required this.name,
    List<TransactionCategory>? subcategories,
  }) : subcategories = subcategories ?? [];


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subcategories': subcategories.map((c) => c.toJson()).toList(),
      };

  factory TransactionCategory.fromJson(Map<String, dynamic> json) =>
      TransactionCategory(
        id: json['id'],
        name: json['name'],
        subcategories: (json['subcategories'] as List<dynamic>?)
                ?.map((e) => TransactionCategory.fromJson(e))
                .toList() ??
            [],
      );
}

String formatAmount(double amount) {
  String formatted = amount.abs().toStringAsFixed(2);
  List<String> parts = formatted.split('.');
  String integerPart = parts[0];
  String fractionalPart = parts[1];

  RegExp reg = RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
  integerPart = integerPart.replaceAllMapped(reg, (Match match) => "${match[1]} ");
  
  String res = "$integerPart,$fractionalPart €";
  return amount < 0 ? "- $res" : res;
}

enum TransactionType { income, expense, transfer }

enum TagType {
  expense,
  income,
  budget,
  project,
  custom,
}

class TagDefinition {
  final String id;
  String name;
  TagType type;
  String? colorHex;
  String? description;
  DateTime createdAt;

  TagDefinition({
    required this.id,
    required this.name,
    this.type = TagType.custom,
    this.colorHex,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'colorHex': colorHex,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TagDefinition.fromJson(Map<String, dynamic> json) => TagDefinition(
        id: json['id'],
        name: json['name'] ?? '',
        type: TagType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TagType.custom,
        ),
        colorHex: json['colorHex'],
        description: json['description'],
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      );
}

class Transaction {
  final String id;
  final double amount;
  final String description;
  final TransactionType type;
  final DateTime date;
  final String? walletId;
  final String? fromWalletId;
  final String? toWalletId;
  final String? categoryId;
  final List<String> tags;
  final bool isRecurring;
  final String? relatedDebtId;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    this.walletId,
    this.fromWalletId,
    this.toWalletId,
    this.categoryId,
    this.tags = const [],
    this.isRecurring = false,
    this.relatedDebtId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'type': type.name,
        'date': date.toIso8601String(),
        'walletId': walletId,
        'fromWalletId': fromWalletId,
        'toWalletId': toWalletId,
        'categoryId': categoryId,
        'tags': tags,
        'isRecurring': isRecurring,
        'relatedDebtId': relatedDebtId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    TransactionType tType;
    if (json.containsKey('isIncome')) {
      tType = json['isIncome'] ? TransactionType.income : TransactionType.expense;
    } else {
      tType = TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      );
    }

    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      description: json['description'] ?? '',
      type: tType,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      walletId: json['walletId'],
      fromWalletId: json['fromWalletId'],
      toWalletId: json['toWalletId'],
      categoryId: json['categoryId'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isRecurring: json['isRecurring'] ?? false,
      relatedDebtId: json['relatedDebtId'],
    );
  }
}

enum RecurrenceFrequency { once, daily, weekly, monthly, yearly }

class RecurringPayment {
  final String id;
  String name;
  double amount;
  TransactionType type;
  String? categoryId;
  String? walletId;
  RecurrenceFrequency frequency;
  DateTime startDate;
  DateTime nextDueDate;
  bool isActive;

  RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.categoryId,
    this.walletId,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'walletId': walletId,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringPayment.fromJson(Map<String, dynamic> json) => RecurringPayment(
        id: json['id'],
        name: json['name'],
        amount: json['amount'].toDouble(),
        type: TransactionType.values.firstWhere((e) => e.name == json['type']),
        categoryId: json['categoryId'],
        walletId: json['walletId'],
        frequency: RecurrenceFrequency.values.firstWhere((e) => e.name == json['frequency']),
        startDate: DateTime.parse(json['startDate']),
        nextDueDate: DateTime.parse(json['nextDueDate']),
        isActive: json['isActive'] ?? true,
      );
}


enum BudgetPeriodType { daily, weekly, monthly, custom }
enum BudgetRepeatFrequency { none, weekly, monthly }

class BudgetPlan {
  final String id;
  String name;
  BudgetPeriodType periodType;
  DateTime startDate;
  DateTime endDate;
  List<String> walletIds;
  List<String> categoryIds;
  bool includeAllCategories;
  List<String> tags;
  List<String> excludedTags;
  List<String> includedTagTypes;
  List<String> excludedTagTypes;
  double amount;
  bool enableAlerts;
  bool enableProgressiveAdjustment;
  String? dependencyBudgetId;
  double? dependencyPercentLimit;
  BudgetRepeatFrequency repeatFrequency;
  double repeatAdjustmentPercent;
  DateTime createdAt;

  BudgetPlan({
    required this.id,
    required this.name,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.walletIds = const [],
    this.categoryIds = const [],
    this.includeAllCategories = true,
    this.tags = const [],
    this.excludedTags = const [],
    this.includedTagTypes = const [],
    this.excludedTagTypes = const [],
    required this.amount,
    this.enableAlerts = true,
    this.enableProgressiveAdjustment = false,
    this.dependencyBudgetId,
    this.dependencyPercentLimit,
    this.repeatFrequency = BudgetRepeatFrequency.none,
    this.repeatAdjustmentPercent = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'periodType': periodType.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'walletIds': walletIds,
        'categoryIds': categoryIds,
        'includeAllCategories': includeAllCategories,
        'tags': tags,
        'excludedTags': excludedTags,
        'includedTagTypes': includedTagTypes,
        'excludedTagTypes': excludedTagTypes,
        'amount': amount,
        'enableAlerts': enableAlerts,
        'enableProgressiveAdjustment': enableProgressiveAdjustment,
        'dependencyBudgetId': dependencyBudgetId,
        'dependencyPercentLimit': dependencyPercentLimit,
        'repeatFrequency': repeatFrequency.name,
        'repeatAdjustmentPercent': repeatAdjustmentPercent,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> json) => BudgetPlan(
        id: json['id'],
        name: json['name'] ?? 'Budget',
        periodType: BudgetPeriodType.values.firstWhere(
          (e) => e.name == json['periodType'],
          orElse: () => BudgetPeriodType.monthly,
        ),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        walletIds: (json['walletIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        categoryIds: (json['categoryIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        includeAllCategories: json['includeAllCategories'] ?? true,
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        excludedTags: (json['excludedTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        includedTagTypes: (json['includedTagTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        excludedTagTypes: (json['excludedTagTypes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        amount: (json['amount'] ?? 0).toDouble(),
        enableAlerts: json['enableAlerts'] ?? true,
        enableProgressiveAdjustment: json['enableProgressiveAdjustment'] ?? false,
        dependencyBudgetId: json['dependencyBudgetId'],
        dependencyPercentLimit: json['dependencyPercentLimit']?.toDouble(),
        repeatFrequency: BudgetRepeatFrequency.values.firstWhere(
          (e) => e.name == json['repeatFrequency'],
          orElse: () => BudgetRepeatFrequency.none,
        ),
        repeatAdjustmentPercent: (json['repeatAdjustmentPercent'] ?? 0).toDouble(),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      );
}

class BudgetProjection {
  final double optimistic;
  final double average;
  final double pessimistic;
  final DateTime? estimatedOverrunDate;

  const BudgetProjection({
    required this.optimistic,
    required this.average,
    required this.pessimistic,
    this.estimatedOverrunDate,
  });
}

class BudgetStatus {
  final BudgetPlan plan;
  final double spent;
  final double percentage;
  final double remaining;
  final List<Transaction> transactions;
  final BudgetProjection projection;

  BudgetStatus({
    required this.plan,
    required this.spent,
    required this.percentage,
    required this.remaining,
    required this.transactions,
    required this.projection,
  });

  bool get isOverBudget => spent > plan.amount;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;
}
