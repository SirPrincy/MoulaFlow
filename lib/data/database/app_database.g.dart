// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WalletsTable extends Wallets
    with TableInfo<$WalletsTable, WalletEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalletsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<WalletType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<WalletType>($WalletsTable.$convertertype);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCreditMeta = const VerificationMeta(
    'isCredit',
  );
  @override
  late final GeneratedColumn<bool> isCredit = GeneratedColumn<bool>(
    'is_credit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    initialBalance,
    type,
    createdAt,
    targetAmount,
    dueDate,
    isSettled,
    isCredit,
    interestRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wallets';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalletEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('is_credit')) {
      context.handle(
        _isCreditMeta,
        isCredit.isAcceptableOrUnknown(data['is_credit']!, _isCreditMeta),
      );
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalletEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalletEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_balance'],
      )!,
      type: $WalletsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      isCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credit'],
      )!,
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      ),
    );
  }

  @override
  $WalletsTable createAlias(String alias) {
    return $WalletsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WalletType, int, int> $convertertype =
      const EnumIndexConverter<WalletType>(WalletType.values);
}

class WalletEntity extends DataClass implements Insertable<WalletEntity> {
  final String id;
  final String name;
  final double initialBalance;
  final WalletType type;
  final DateTime createdAt;
  final double? targetAmount;
  final DateTime? dueDate;
  final bool isSettled;
  final bool isCredit;
  final double? interestRate;
  const WalletEntity({
    required this.id,
    required this.name,
    required this.initialBalance,
    required this.type,
    required this.createdAt,
    this.targetAmount,
    this.dueDate,
    required this.isSettled,
    required this.isCredit,
    this.interestRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['initial_balance'] = Variable<double>(initialBalance);
    {
      map['type'] = Variable<int>($WalletsTable.$convertertype.toSql(type));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<double>(targetAmount);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_settled'] = Variable<bool>(isSettled);
    map['is_credit'] = Variable<bool>(isCredit);
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    return map;
  }

  WalletsCompanion toCompanion(bool nullToAbsent) {
    return WalletsCompanion(
      id: Value(id),
      name: Value(name),
      initialBalance: Value(initialBalance),
      type: Value(type),
      createdAt: Value(createdAt),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isSettled: Value(isSettled),
      isCredit: Value(isCredit),
      interestRate: interestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRate),
    );
  }

  factory WalletEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalletEntity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      type: $WalletsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      targetAmount: serializer.fromJson<double?>(json['targetAmount']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      isCredit: serializer.fromJson<bool>(json['isCredit']),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'type': serializer.toJson<int>($WalletsTable.$convertertype.toJson(type)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'targetAmount': serializer.toJson<double?>(targetAmount),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isSettled': serializer.toJson<bool>(isSettled),
      'isCredit': serializer.toJson<bool>(isCredit),
      'interestRate': serializer.toJson<double?>(interestRate),
    };
  }

  WalletEntity copyWith({
    String? id,
    String? name,
    double? initialBalance,
    WalletType? type,
    DateTime? createdAt,
    Value<double?> targetAmount = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isSettled,
    bool? isCredit,
    Value<double?> interestRate = const Value.absent(),
  }) => WalletEntity(
    id: id ?? this.id,
    name: name ?? this.name,
    initialBalance: initialBalance ?? this.initialBalance,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isSettled: isSettled ?? this.isSettled,
    isCredit: isCredit ?? this.isCredit,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
  );
  WalletEntity copyWithCompanion(WalletsCompanion data) {
    return WalletEntity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      isCredit: data.isCredit.present ? data.isCredit.value : this.isCredit,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalletEntity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('isSettled: $isSettled, ')
          ..write('isCredit: $isCredit, ')
          ..write('interestRate: $interestRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    initialBalance,
    type,
    createdAt,
    targetAmount,
    dueDate,
    isSettled,
    isCredit,
    interestRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalletEntity &&
          other.id == this.id &&
          other.name == this.name &&
          other.initialBalance == this.initialBalance &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.targetAmount == this.targetAmount &&
          other.dueDate == this.dueDate &&
          other.isSettled == this.isSettled &&
          other.isCredit == this.isCredit &&
          other.interestRate == this.interestRate);
}

class WalletsCompanion extends UpdateCompanion<WalletEntity> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> initialBalance;
  final Value<WalletType> type;
  final Value<DateTime> createdAt;
  final Value<double?> targetAmount;
  final Value<DateTime?> dueDate;
  final Value<bool> isSettled;
  final Value<bool> isCredit;
  final Value<double?> interestRate;
  final Value<int> rowid;
  const WalletsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WalletsCompanion.insert({
    required String id,
    required String name,
    this.initialBalance = const Value.absent(),
    required WalletType type,
    required DateTime createdAt,
    this.targetAmount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       createdAt = Value(createdAt);
  static Insertable<WalletEntity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? initialBalance,
    Expression<int>? type,
    Expression<DateTime>? createdAt,
    Expression<double>? targetAmount,
    Expression<DateTime>? dueDate,
    Expression<bool>? isSettled,
    Expression<bool>? isCredit,
    Expression<double>? interestRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (dueDate != null) 'due_date': dueDate,
      if (isSettled != null) 'is_settled': isSettled,
      if (isCredit != null) 'is_credit': isCredit,
      if (interestRate != null) 'interest_rate': interestRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WalletsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? initialBalance,
    Value<WalletType>? type,
    Value<DateTime>? createdAt,
    Value<double?>? targetAmount,
    Value<DateTime?>? dueDate,
    Value<bool>? isSettled,
    Value<bool>? isCredit,
    Value<double?>? interestRate,
    Value<int>? rowid,
  }) {
    return WalletsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      targetAmount: targetAmount ?? this.targetAmount,
      dueDate: dueDate ?? this.dueDate,
      isSettled: isSettled ?? this.isSettled,
      isCredit: isCredit ?? this.isCredit,
      interestRate: interestRate ?? this.interestRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $WalletsTable.$convertertype.toSql(type.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (isCredit.present) {
      map['is_credit'] = Variable<bool>(isCredit.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalletsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('dueDate: $dueDate, ')
          ..write('isSettled: $isSettled, ')
          ..write('isCredit: $isCredit, ')
          ..write('interestRate: $interestRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _walletIdMeta = const VerificationMeta(
    'walletId',
  );
  @override
  late final GeneratedColumn<String> walletId = GeneratedColumn<String>(
    'wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromWalletIdMeta = const VerificationMeta(
    'fromWalletId',
  );
  @override
  late final GeneratedColumn<String> fromWalletId = GeneratedColumn<String>(
    'from_wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toWalletIdMeta = const VerificationMeta(
    'toWalletId',
  );
  @override
  late final GeneratedColumn<String> toWalletId = GeneratedColumn<String>(
    'to_wallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>(
        'tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<List<String>>($TransactionsTable.$convertertags);
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _relatedDebtIdMeta = const VerificationMeta(
    'relatedDebtId',
  );
  @override
  late final GeneratedColumn<String> relatedDebtId = GeneratedColumn<String>(
    'related_debt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    description,
    type,
    date,
    walletId,
    fromWalletId,
    toWalletId,
    categoryId,
    tags,
    isRecurring,
    relatedDebtId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('wallet_id')) {
      context.handle(
        _walletIdMeta,
        walletId.isAcceptableOrUnknown(data['wallet_id']!, _walletIdMeta),
      );
    }
    if (data.containsKey('from_wallet_id')) {
      context.handle(
        _fromWalletIdMeta,
        fromWalletId.isAcceptableOrUnknown(
          data['from_wallet_id']!,
          _fromWalletIdMeta,
        ),
      );
    }
    if (data.containsKey('to_wallet_id')) {
      context.handle(
        _toWalletIdMeta,
        toWalletId.isAcceptableOrUnknown(
          data['to_wallet_id']!,
          _toWalletIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('related_debt_id')) {
      context.handle(
        _relatedDebtIdMeta,
        relatedDebtId.isAcceptableOrUnknown(
          data['related_debt_id']!,
          _relatedDebtIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      walletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallet_id'],
      ),
      fromWalletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_wallet_id'],
      ),
      toWalletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_wallet_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      tags: $TransactionsTable.$convertertags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}tags'],
        )!,
      ),
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      relatedDebtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_debt_id'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
  static TypeConverter<List<String>, String> $convertertags =
      const TransactionTagsConverter();
}

class TransactionEntity extends DataClass
    implements Insertable<TransactionEntity> {
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
  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.date,
    this.walletId,
    this.fromWalletId,
    this.toWalletId,
    this.categoryId,
    required this.tags,
    required this.isRecurring,
    this.relatedDebtId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['amount'] = Variable<double>(amount);
    map['description'] = Variable<String>(description);
    {
      map['type'] = Variable<int>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || walletId != null) {
      map['wallet_id'] = Variable<String>(walletId);
    }
    if (!nullToAbsent || fromWalletId != null) {
      map['from_wallet_id'] = Variable<String>(fromWalletId);
    }
    if (!nullToAbsent || toWalletId != null) {
      map['to_wallet_id'] = Variable<String>(toWalletId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    {
      map['tags'] = Variable<String>(
        $TransactionsTable.$convertertags.toSql(tags),
      );
    }
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || relatedDebtId != null) {
      map['related_debt_id'] = Variable<String>(relatedDebtId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      description: Value(description),
      type: Value(type),
      date: Value(date),
      walletId: walletId == null && nullToAbsent
          ? const Value.absent()
          : Value(walletId),
      fromWalletId: fromWalletId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromWalletId),
      toWalletId: toWalletId == null && nullToAbsent
          ? const Value.absent()
          : Value(toWalletId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      tags: Value(tags),
      isRecurring: Value(isRecurring),
      relatedDebtId: relatedDebtId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedDebtId),
    );
  }

  factory TransactionEntity.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEntity(
      id: serializer.fromJson<String>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      date: serializer.fromJson<DateTime>(json['date']),
      walletId: serializer.fromJson<String?>(json['walletId']),
      fromWalletId: serializer.fromJson<String?>(json['fromWalletId']),
      toWalletId: serializer.fromJson<String?>(json['toWalletId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      relatedDebtId: serializer.fromJson<String?>(json['relatedDebtId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'amount': serializer.toJson<double>(amount),
      'description': serializer.toJson<String>(description),
      'type': serializer.toJson<int>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'date': serializer.toJson<DateTime>(date),
      'walletId': serializer.toJson<String?>(walletId),
      'fromWalletId': serializer.toJson<String?>(fromWalletId),
      'toWalletId': serializer.toJson<String?>(toWalletId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'tags': serializer.toJson<List<String>>(tags),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'relatedDebtId': serializer.toJson<String?>(relatedDebtId),
    };
  }

  TransactionEntity copyWith({
    String? id,
    double? amount,
    String? description,
    TransactionType? type,
    DateTime? date,
    Value<String?> walletId = const Value.absent(),
    Value<String?> fromWalletId = const Value.absent(),
    Value<String?> toWalletId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    List<String>? tags,
    bool? isRecurring,
    Value<String?> relatedDebtId = const Value.absent(),
  }) => TransactionEntity(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    type: type ?? this.type,
    date: date ?? this.date,
    walletId: walletId.present ? walletId.value : this.walletId,
    fromWalletId: fromWalletId.present ? fromWalletId.value : this.fromWalletId,
    toWalletId: toWalletId.present ? toWalletId.value : this.toWalletId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    tags: tags ?? this.tags,
    isRecurring: isRecurring ?? this.isRecurring,
    relatedDebtId: relatedDebtId.present
        ? relatedDebtId.value
        : this.relatedDebtId,
  );
  TransactionEntity copyWithCompanion(TransactionsCompanion data) {
    return TransactionEntity(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      date: data.date.present ? data.date.value : this.date,
      walletId: data.walletId.present ? data.walletId.value : this.walletId,
      fromWalletId: data.fromWalletId.present
          ? data.fromWalletId.value
          : this.fromWalletId,
      toWalletId: data.toWalletId.present
          ? data.toWalletId.value
          : this.toWalletId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      tags: data.tags.present ? data.tags.value : this.tags,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      relatedDebtId: data.relatedDebtId.present
          ? data.relatedDebtId.value
          : this.relatedDebtId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntity(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('walletId: $walletId, ')
          ..write('fromWalletId: $fromWalletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tags: $tags, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('relatedDebtId: $relatedDebtId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    description,
    type,
    date,
    walletId,
    fromWalletId,
    toWalletId,
    categoryId,
    tags,
    isRecurring,
    relatedDebtId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEntity &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.type == this.type &&
          other.date == this.date &&
          other.walletId == this.walletId &&
          other.fromWalletId == this.fromWalletId &&
          other.toWalletId == this.toWalletId &&
          other.categoryId == this.categoryId &&
          other.tags == this.tags &&
          other.isRecurring == this.isRecurring &&
          other.relatedDebtId == this.relatedDebtId);
}

class TransactionsCompanion extends UpdateCompanion<TransactionEntity> {
  final Value<String> id;
  final Value<double> amount;
  final Value<String> description;
  final Value<TransactionType> type;
  final Value<DateTime> date;
  final Value<String?> walletId;
  final Value<String?> fromWalletId;
  final Value<String?> toWalletId;
  final Value<String?> categoryId;
  final Value<List<String>> tags;
  final Value<bool> isRecurring;
  final Value<String?> relatedDebtId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.date = const Value.absent(),
    this.walletId = const Value.absent(),
    this.fromWalletId = const Value.absent(),
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tags = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.relatedDebtId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required double amount,
    required String description,
    required TransactionType type,
    required DateTime date,
    this.walletId = const Value.absent(),
    this.fromWalletId = const Value.absent(),
    this.toWalletId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tags = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.relatedDebtId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amount = Value(amount),
       description = Value(description),
       type = Value(type),
       date = Value(date);
  static Insertable<TransactionEntity> custom({
    Expression<String>? id,
    Expression<double>? amount,
    Expression<String>? description,
    Expression<int>? type,
    Expression<DateTime>? date,
    Expression<String>? walletId,
    Expression<String>? fromWalletId,
    Expression<String>? toWalletId,
    Expression<String>? categoryId,
    Expression<String>? tags,
    Expression<bool>? isRecurring,
    Expression<String>? relatedDebtId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (date != null) 'date': date,
      if (walletId != null) 'wallet_id': walletId,
      if (fromWalletId != null) 'from_wallet_id': fromWalletId,
      if (toWalletId != null) 'to_wallet_id': toWalletId,
      if (categoryId != null) 'category_id': categoryId,
      if (tags != null) 'tags': tags,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (relatedDebtId != null) 'related_debt_id': relatedDebtId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<double>? amount,
    Value<String>? description,
    Value<TransactionType>? type,
    Value<DateTime>? date,
    Value<String?>? walletId,
    Value<String?>? fromWalletId,
    Value<String?>? toWalletId,
    Value<String?>? categoryId,
    Value<List<String>>? tags,
    Value<bool>? isRecurring,
    Value<String?>? relatedDebtId,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
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
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (walletId.present) {
      map['wallet_id'] = Variable<String>(walletId.value);
    }
    if (fromWalletId.present) {
      map['from_wallet_id'] = Variable<String>(fromWalletId.value);
    }
    if (toWalletId.present) {
      map['to_wallet_id'] = Variable<String>(toWalletId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(
        $TransactionsTable.$convertertags.toSql(tags.value),
      );
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (relatedDebtId.present) {
      map['related_debt_id'] = Variable<String>(relatedDebtId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('walletId: $walletId, ')
          ..write('fromWalletId: $fromWalletId, ')
          ..write('toWalletId: $toWalletId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tags: $tags, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('relatedDebtId: $relatedDebtId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WalletsTable wallets = $WalletsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wallets, transactions];
}

typedef $$WalletsTableCreateCompanionBuilder =
    WalletsCompanion Function({
      required String id,
      required String name,
      Value<double> initialBalance,
      required WalletType type,
      required DateTime createdAt,
      Value<double?> targetAmount,
      Value<DateTime?> dueDate,
      Value<bool> isSettled,
      Value<bool> isCredit,
      Value<double?> interestRate,
      Value<int> rowid,
    });
typedef $$WalletsTableUpdateCompanionBuilder =
    WalletsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> initialBalance,
      Value<WalletType> type,
      Value<DateTime> createdAt,
      Value<double?> targetAmount,
      Value<DateTime?> dueDate,
      Value<bool> isSettled,
      Value<bool> isCredit,
      Value<double?> interestRate,
      Value<int> rowid,
    });

class $$WalletsTableFilterComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WalletType, WalletType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalletsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalletsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalletsTable> {
  $$WalletsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<WalletType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<bool> get isCredit =>
      $composableBuilder(column: $table.isCredit, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );
}

class $$WalletsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalletsTable,
          WalletEntity,
          $$WalletsTableFilterComposer,
          $$WalletsTableOrderingComposer,
          $$WalletsTableAnnotationComposer,
          $$WalletsTableCreateCompanionBuilder,
          $$WalletsTableUpdateCompanionBuilder,
          (
            WalletEntity,
            BaseReferences<_$AppDatabase, $WalletsTable, WalletEntity>,
          ),
          WalletEntity,
          PrefetchHooks Function()
        > {
  $$WalletsTableTableManager(_$AppDatabase db, $WalletsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalletsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalletsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalletsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> initialBalance = const Value.absent(),
                Value<WalletType> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<double?> targetAmount = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion(
                id: id,
                name: name,
                initialBalance: initialBalance,
                type: type,
                createdAt: createdAt,
                targetAmount: targetAmount,
                dueDate: dueDate,
                isSettled: isSettled,
                isCredit: isCredit,
                interestRate: interestRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<double> initialBalance = const Value.absent(),
                required WalletType type,
                required DateTime createdAt,
                Value<double?> targetAmount = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WalletsCompanion.insert(
                id: id,
                name: name,
                initialBalance: initialBalance,
                type: type,
                createdAt: createdAt,
                targetAmount: targetAmount,
                dueDate: dueDate,
                isSettled: isSettled,
                isCredit: isCredit,
                interestRate: interestRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalletsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalletsTable,
      WalletEntity,
      $$WalletsTableFilterComposer,
      $$WalletsTableOrderingComposer,
      $$WalletsTableAnnotationComposer,
      $$WalletsTableCreateCompanionBuilder,
      $$WalletsTableUpdateCompanionBuilder,
      (
        WalletEntity,
        BaseReferences<_$AppDatabase, $WalletsTable, WalletEntity>,
      ),
      WalletEntity,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required double amount,
      required String description,
      required TransactionType type,
      required DateTime date,
      Value<String?> walletId,
      Value<String?> fromWalletId,
      Value<String?> toWalletId,
      Value<String?> categoryId,
      Value<List<String>> tags,
      Value<bool> isRecurring,
      Value<String?> relatedDebtId,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<double> amount,
      Value<String> description,
      Value<TransactionType> type,
      Value<DateTime> date,
      Value<String?> walletId,
      Value<String?> fromWalletId,
      Value<String?> toWalletId,
      Value<String?> categoryId,
      Value<List<String>> tags,
      Value<bool> isRecurring,
      Value<String?> relatedDebtId,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromWalletId => $composableBuilder(
    column: $table.fromWalletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toWalletId => $composableBuilder(
    column: $table.toWalletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
        column: $table.tags,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedDebtId => $composableBuilder(
    column: $table.relatedDebtId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get walletId => $composableBuilder(
    column: $table.walletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromWalletId => $composableBuilder(
    column: $table.fromWalletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toWalletId => $composableBuilder(
    column: $table.toWalletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedDebtId => $composableBuilder(
    column: $table.relatedDebtId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get walletId =>
      $composableBuilder(column: $table.walletId, builder: (column) => column);

  GeneratedColumn<String> get fromWalletId => $composableBuilder(
    column: $table.fromWalletId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toWalletId => $composableBuilder(
    column: $table.toWalletId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedDebtId => $composableBuilder(
    column: $table.relatedDebtId,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionEntity,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionEntity,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTable,
              TransactionEntity
            >,
          ),
          TransactionEntity,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> walletId = const Value.absent(),
                Value<String?> fromWalletId = const Value.absent(),
                Value<String?> toWalletId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> relatedDebtId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amount: amount,
                description: description,
                type: type,
                date: date,
                walletId: walletId,
                fromWalletId: fromWalletId,
                toWalletId: toWalletId,
                categoryId: categoryId,
                tags: tags,
                isRecurring: isRecurring,
                relatedDebtId: relatedDebtId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double amount,
                required String description,
                required TransactionType type,
                required DateTime date,
                Value<String?> walletId = const Value.absent(),
                Value<String?> fromWalletId = const Value.absent(),
                Value<String?> toWalletId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<List<String>> tags = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> relatedDebtId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amount: amount,
                description: description,
                type: type,
                date: date,
                walletId: walletId,
                fromWalletId: fromWalletId,
                toWalletId: toWalletId,
                categoryId: categoryId,
                tags: tags,
                isRecurring: isRecurring,
                relatedDebtId: relatedDebtId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionEntity,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionEntity,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionEntity>,
      ),
      TransactionEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db, _db.wallets);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
