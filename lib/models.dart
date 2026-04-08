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
  final String currencyCode;

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
    this.currencyCode = 'MGA',
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
    String? currencyCode,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetAmount: targetAmount ?? this.targetAmount,
      dueDate: dueDate ?? this.dueDate, // If we want to allow nullification it's harder, but normally this is fine
      isSettled: isSettled ?? this.isSettled,
      isCredit: isCredit ?? this.isCredit,
      interestRate: interestRate ?? this.interestRate,
      currencyCode: currencyCode ?? this.currencyCode,
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
        'currencyCode': currencyCode,
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
        currencyCode: json['currencyCode'] ?? 'MGA',
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

  static (String, String?) getNamesFromId(String? id, List<TransactionCategory> categories) {
    if (id == null) return ('Divers', null);
    for (var mainCat in categories) {
      if (mainCat.id == id) return (mainCat.name, null);
      for (var subCat in mainCat.subcategories) {
        if (subCat.id == id) return (mainCat.name, subCat.name);
      }
    }
    return ('Inconnu', null);
  }
}

String formatAmount(double amount, {String symbol = 'Ar', int decimalDigits = 2}) {
  String formatted = amount.abs().toStringAsFixed(decimalDigits);
  List<String> parts = formatted.split('.');
  String integerPart = parts[0];
  String fractionalPart = parts.length > 1 ? parts[1] : '';

  RegExp reg = RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))");
  integerPart = integerPart.replaceAllMapped(reg, (Match match) => "${match[1]} ");
  
  String res = decimalDigits > 0 ? "$integerPart,$fractionalPart $symbol" : "$integerPart $symbol";
  return amount < 0 ? "- $res" : res;
}

enum TransactionType { income, expense, transfer }

enum TagType {
  expense,
  income,
  budget,
  project,
  custom,
  person,
  place,
  recurring,
  debt,
  saving,
  investment,
  health,
  education,
  transport,
  housing,
  food,
  leisure,
  business,
  shopping,
  travel,
}

extension TagTypeUi on TagType {
  String get labelFr {
    switch (this) {
      case TagType.expense:
        return 'Dépense';
      case TagType.income:
        return 'Revenu';
      case TagType.budget:
        return 'Budget';
      case TagType.project:
        return 'Projet';
      case TagType.custom:
        return 'Autre';
      case TagType.person:
        return 'Personne';
      case TagType.place:
        return 'Lieu';
      case TagType.recurring:
        return 'Récurrent';
      case TagType.debt:
        return 'Dette';
      case TagType.saving:
        return 'Épargne';
      case TagType.investment:
        return 'Investissement';
      case TagType.health:
        return 'Santé';
      case TagType.education:
        return 'Éducation';
      case TagType.transport:
        return 'Transport';
      case TagType.housing:
        return 'Logement';
      case TagType.food:
        return 'Alimentation';
      case TagType.leisure:
        return 'Loisir';
      case TagType.business:
        return 'Business';
      case TagType.shopping:
        return 'Shopping';
      case TagType.travel:
        return 'Voyage';
    }
  }
}

class TagDefinition {
  final String id;
  final String name;
  final TagType type;
  final String? color;
  final String? icon;
  final String? description;
  final double? goalAmount;
  final DateTime createdAt;

  TagDefinition({
    required this.id,
    required this.name,
    this.type = TagType.custom,
    this.color,
    this.icon,
    this.description,
    this.goalAmount,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TagDefinition copyWith({
    String? id,
    String? name,
    TagType? type,
    String? color,
    String? icon,
    String? description,
    double? goalAmount,
    DateTime? createdAt,
  }) {
    return TagDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      goalAmount: goalAmount ?? this.goalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'color': color,
        'icon': icon,
        'description': description,
        'goalAmount': goalAmount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TagDefinition.fromJson(Map<String, dynamic> json) => TagDefinition(
        id: json['id'],
        name: json['name'] ?? '',
        type: TagType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TagType.custom,
        ),
        color: json['color'] ?? json['colorHex'],
        icon: json['icon'],
        description: json['description'],
        goalAmount: json['goalAmount']?.toDouble(),
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
  final List<String> tags;
  final String? categoryId;
  final String? relatedDebtId;
  final String? recurringPaymentId;

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
    this.relatedDebtId,
    this.recurringPaymentId,
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
    String? relatedDebtId,
    String? recurringPaymentId,
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
      relatedDebtId: relatedDebtId ?? this.relatedDebtId,
      recurringPaymentId: recurringPaymentId ?? this.recurringPaymentId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type.name,
      'date': date.toIso8601String(),
      'walletId': walletId,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'tags': tags,
      'categoryId': categoryId,
      'relatedDebtId': relatedDebtId,
      'recurringPaymentId': recurringPaymentId,
    };
  }

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
      relatedDebtId: json['relatedDebtId'],
    );
  }
}

enum RecurrenceFrequency { once, daily, weekly, monthly, yearly }
enum RecurringExecutionMode { auto, manual }

class RecurringPayment {
  final String id;
  final String name;
  final String description;
  final double amount;
  final TransactionType type;
  final String? categoryId;
  final String? walletId;
  final List<String> tags;
  final RecurrenceFrequency frequency;
  final RecurringExecutionMode executionMode;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;

  RecurringPayment({
    required this.id,
    required this.name,
    this.description = '',
    required this.amount,
    required this.type,
    this.categoryId,
    this.walletId,
    this.tags = const [],
    required this.frequency,
    this.executionMode = RecurringExecutionMode.auto,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
  });

  DateTime getNextDueDate() {
    if (frequency == RecurrenceFrequency.once) return nextDueDate;
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return nextDueDate.add(const Duration(days: 1));
      case RecurrenceFrequency.weekly:
        return nextDueDate.add(const Duration(days: 7));
      case RecurrenceFrequency.monthly:
        return DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
      case RecurrenceFrequency.yearly:
        return DateTime(nextDueDate.year + 1, nextDueDate.month, nextDueDate.day);
      default:
        return nextDueDate;
    }
  }

  RecurringPayment copyWith({
    String? id,
    String? name,
    String? description,
    double? amount,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    List<String>? tags,
    RecurrenceFrequency? frequency,
    RecurringExecutionMode? executionMode,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      tags: tags ?? this.tags,
      frequency: frequency ?? this.frequency,
      executionMode: executionMode ?? this.executionMode,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'walletId': walletId,
        'tags': tags,
        'frequency': frequency.name,
        'executionMode': executionMode.name,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'isActive': isActive,
      };

  factory RecurringPayment.fromJson(Map<String, dynamic> json) => RecurringPayment(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        amount: json['amount'].toDouble(),
        type: TransactionType.values.firstWhere((e) => e.name == json['type']),
        categoryId: json['categoryId'],
        walletId: json['walletId'],
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        frequency: RecurrenceFrequency.values.firstWhere((e) => e.name == json['frequency']),
        executionMode: RecurringExecutionMode.values.firstWhere(
          (e) => e.name == (json['executionMode'] ?? 'auto'),
          orElse: () => RecurringExecutionMode.auto,
        ),
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

class ProjectItem {
  final String id;
  final String name;
  final double price;
  final bool isPurchased;

  const ProjectItem({
    required this.id,
    required this.name,
    required this.price,
    this.isPurchased = false,
  });

  ProjectItem copyWith({
    String? id,
    String? name,
    double? price,
    bool? isPurchased,
  }) {
    return ProjectItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'isPurchased': isPurchased,
      };

  factory ProjectItem.fromJson(Map<String, dynamic> json) => ProjectItem(
        id: json['id'],
        name: json['name'],
        price: json['price'].toDouble(),
        isPurchased: json['isPurchased'] ?? false,
      );
}

class Project {
  final String id;
  final String title;
  final String icon;
  final String linkedWalletId;
  final List<ProjectItem> items;

  const Project({
    required this.id,
    required this.title,
    required this.icon,
    required this.linkedWalletId,
    required this.items,
  });

  double get targetAmount {
    return items.fold(0.0, (sum, item) => sum + item.price);
  }

  double getProgress(double currentSavings) {
    if (targetAmount == 0) return 0.0;
    double progress = currentSavings / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  Project copyWith({
    String? id,
    String? title,
    String? icon,
    String? linkedWalletId,
    List<ProjectItem>? items,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      linkedWalletId: linkedWalletId ?? this.linkedWalletId,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'linkedWalletId': linkedWalletId,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        title: json['title'],
        icon: json['icon'],
        linkedWalletId: json['linkedWalletId'],
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => ProjectItem.fromJson(e))
                .toList() ??
            [],
      );
}
