import 'package:drift/drift.dart';
import '../../models.dart';

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',').where((e) => e.isNotEmpty).toList();
  }

  @override
  String toSql(List<String> value) => value.join(',');
}

@DataClassName('WalletEntity')
class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get initialBalance => real().withDefault(const Constant(0.0))();
  IntColumn get type => intEnum<WalletType>()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get targetAmount => real().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  RealColumn get interestRate => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionEntity')
class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  IntColumn get type => intEnum<TransactionType>()();
  DateTimeColumn get date => dateTime()();
  TextColumn get walletId => text().nullable()();
  TextColumn get fromWalletId => text().nullable()();
  TextColumn get toWalletId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get tags => text().map(const StringListConverter()).withDefault(const Constant(''))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get relatedDebtId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryEntity')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()(); // null if main category

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TagEntity')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  RealColumn get goalAmount => real().nullable()(); // Max budget for this project tag
  TextColumn get description => text().nullable()();
  IntColumn get type => intEnum<TagType>()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionTagEntity')
class TransactionTags extends Table {
  TextColumn get transactionId => text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

@DataClassName('BudgetPlanEntity')
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get periodType => intEnum<BudgetPeriodType>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get walletIds => text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get categoryIds => text().map(const StringListConverter()).withDefault(const Constant(''))();
  BoolColumn get includeAllCategories => boolean().withDefault(const Constant(true))();
  TextColumn get tags => text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get excludedTags => text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get includedTagTypes => text().map(const StringListConverter()).withDefault(const Constant(''))();
  TextColumn get excludedTagTypes => text().map(const StringListConverter()).withDefault(const Constant(''))();
  RealColumn get amount => real()();
  BoolColumn get enableAlerts => boolean().withDefault(const Constant(true))();
  BoolColumn get enableProgressiveAdjustment => boolean().withDefault(const Constant(false))();
  TextColumn get dependencyBudgetId => text().nullable()();
  RealColumn get dependencyPercentLimit => real().nullable()();
  IntColumn get repeatFrequency => intEnum<BudgetRepeatFrequency>()();
  RealColumn get repeatAdjustmentPercent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecurringPaymentEntity')
class RecurringPayments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get walletId => text().nullable()();
  IntColumn get frequency => intEnum<RecurrenceFrequency>()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
