// No need for material import

enum WalletType { current, savings, debt, project, cash, bank, mobileMoney }

class Wallet {
  final String id;
  String name;
  double initialBalance;
  WalletType type;
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
    this.targetAmount,
    this.dueDate,
    this.isSettled = false,
    this.isCredit = false,
    this.interestRate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'initialBalance': initialBalance,
        'type': type.name,
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
