import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class RecurringPaymentRepository {
  final AppDatabase db;

  RecurringPaymentRepository(this.db);

  Stream<List<RecurringPayment>> watchRecurringPayments() {
    return db.select(db.recurringPayments).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<RecurringPayment>> loadRecurringPayments() async {
    final entities = await db.select(db.recurringPayments).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> insertRecurringPayment(RecurringPayment p) async {
    await db.into(db.recurringPayments).insert(_mapModelToCompanion(p), mode: InsertMode.replace);
  }

  Future<void> updateRecurringPayment(RecurringPayment p) async {
    await db.update(db.recurringPayments).replace(_mapModelToCompanion(p));
  }

  Future<void> deleteRecurringPayment(String id) async {
    await (db.delete(db.recurringPayments)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveRecurringPayments(List<RecurringPayment> payments) async {
    await db.transaction(() async {
      await db.delete(db.recurringPayments).go();
      for (final p in payments) {
        await insertRecurringPayment(p);
      }
    });
  }

  RecurringPayment _mapEntityToModel(RecurringPaymentEntity e) {
    return RecurringPayment(
      id: e.id,
      name: e.name,
      description: e.description,
      amount: e.amount,
      type: e.type,
      categoryId: e.categoryId,
      walletId: e.walletId,
      tags: e.tags,
      frequency: e.frequency,
      executionMode: e.executionMode,
      startDate: e.startDate,
      nextDueDate: e.nextDueDate,
      isActive: e.isActive,
    );
  }

  RecurringPaymentsCompanion _mapModelToCompanion(RecurringPayment p) {
    return RecurringPaymentsCompanion(
      id: Value(p.id),
      name: Value(p.name),
      description: Value(p.description),
      amount: Value(p.amount),
      type: Value(p.type),
      categoryId: Value(p.categoryId),
      walletId: Value(p.walletId),
      tags: Value(p.tags),
      frequency: Value(p.frequency),
      executionMode: Value(p.executionMode),
      startDate: Value(p.startDate),
      nextDueDate: Value(p.nextDueDate),
      isActive: Value(p.isActive),
    );
  }
}
