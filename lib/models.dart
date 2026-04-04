// No need for material import

enum WalletType { current, savings, debt, project, cash, bank, mobileMoney }

class Wallet {
  final String id;
  final String name;
  final double initialBalance;
  final WalletType type;
  final DateTime createdAt;
  final double? targetAmount;
  final DateTime? dueDate;
  final bool isSettled;
  final bool isCredit; // true if someone owes ME, false if I owe someone
  final double? interestRate; // Annual interest rate in percentage (%)

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

  Wallet copyWith({
    String? id,
    String? name,
    double? initialBalance,
    WalletType? type,
    DateTime? createdAt,
    double? targetAmount,
    DateTime? dueDate,
    bool? isSettled,
    bool? isCredit,
    double? interestRate,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetAmount: targetAmount != null ? targetAmount : this.targetAmount,
      dueDate: dueDate != null ? dueDate : this.dueDate, // If we want to allow nullification it's harder, but normally this is fine
      isSettled: isSettled ?? this.isSettled,
      isCredit: isCredit ?? this.isCredit,
      interestRate: interestRate != null ? interestRate : this.interestRate,
    );
  }

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
  final String name;
  final List<TransactionCategory> subcategories;

  TransactionCategory({
    required this.id,
    required this.name,
    List<TransactionCategory>? subcategories,
  }) : subcategories = subcategories ?? [];

  TransactionCategory copyWith({
    String? id,
    String? name,
    List<TransactionCategory>? subcategories,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      subcategories: subcategories ?? this.subcategories,
    );
  }

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
                .toList(),
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
  final String name;
  final TagType type;
  final String? colorHex;
  final String? description;
  final DateTime createdAt;

  TagDefinition({
    required this.id,
    required this.name,
    this.type = TagType.custom,
    this.colorHex,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TagDefinition copyWith({
    String? id,
    String? name,
    TagType? type,
    String? colorHex,
    String? description,
    DateTime? createdAt,
  }) {
    return TagDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorHex: colorHex != null ? colorHex : this.colorHex,
      description: description != null ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

  const Transaction({
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

  Transaction copyWith({
    String? id,
    double? amount,
    String? description,
    TransactionType? type,
    DateTime? date,
    String? walletId,
    String? fromWalletId,
    String? toWalletId,
    String? categoryId,
    List<String>? tags,
    bool? isRecurring,
    String? relatedDebtId,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      walletId: walletId ?? this.walletId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      relatedDebtId: relatedDebtId ?? this.relatedDebtId,
    );
  }

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
      tType = (json['isIncome'] as bool) ? TransactionType.income : TransactionType.expense;
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
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isRecurring: json['isRecurring'] ?? false,
      relatedDebtId: json['relatedDebtId'],
    );
  }
}

enum RecurrenceFrequency { once, daily, weekly, monthly, yearly }

class RecurringPayment {
  final String id;
  final String name;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String? walletId;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;

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

  RecurringPayment copyWith({
    String? id,
    String? name,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

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
  final String name;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> walletIds;
  final List<String> categoryIds;
  final bool includeAllCategories;
  final List<String> tags;
  final List<String> excludedTags;
  final List<String> includedTagTypes;
  final List<String> excludedTagTypes;
  final double amount;
  final bool enableAlerts;
  final bool enableProgressiveAdjustment;
  final String? dependencyBudgetId;
  final double? dependencyPercentLimit;
  final BudgetRepeatFrequency repeatFrequency;
  final double repeatAdjustmentPercent;
  final DateTime createdAt;

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

  BudgetPlan copyWith({
    String? id,
    String? name,
    BudgetPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? walletIds,
    List<String>? categoryIds,
    bool? includeAllCategories,
    List<String>? tags,
    List<String>? excludedTags,
    List<String>? includedTagTypes,
    List<String>? excludedTagTypes,
    double? amount,
    bool? enableAlerts,
    bool? enableProgressiveAdjustment,
    String? dependencyBudgetId,
    double? dependencyPercentLimit,
    BudgetRepeatFrequency? repeatFrequency,
    double? repeatAdjustmentPercent,
    DateTime? createdAt,
  }) {
    return BudgetPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      walletIds: walletIds ?? this.walletIds,
      categoryIds: categoryIds ?? this.categoryIds,
      includeAllCategories: includeAllCategories ?? this.includeAllCategories,
      tags: tags ?? this.tags,
      excludedTags: excludedTags ?? this.excludedTags,
      includedTagTypes: includedTagTypes ?? this.includedTagTypes,
      excludedTagTypes: excludedTagTypes ?? this.excludedTagTypes,
      amount: amount ?? this.amount,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      enableProgressiveAdjustment: enableProgressiveAdjustment ?? this.enableProgressiveAdjustment,
      dependencyBudgetId: dependencyBudgetId ?? this.dependencyBudgetId,
      dependencyPercentLimit: dependencyPercentLimit ?? this.dependencyPercentLimit,
      repeatFrequency: repeatFrequency ?? this.repeatFrequency,
      repeatAdjustmentPercent: repeatAdjustmentPercent ?? this.repeatAdjustmentPercent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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

  const BudgetStatus({
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
