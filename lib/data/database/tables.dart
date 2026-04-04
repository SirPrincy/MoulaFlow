import 'package:drift/drift.dart';
import '../../models.dart';

class TransactionTagsConverter extends TypeConverter<List<String>, String> {
  const TransactionTagsConverter();

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
  TextColumn get tags => text().map(const TransactionTagsConverter()).withDefault(const Constant(''))();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get relatedDebtId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
