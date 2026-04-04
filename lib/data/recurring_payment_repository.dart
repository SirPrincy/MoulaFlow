import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class RecurringPaymentRepository {
  Stream<List<RecurringPayment>> watchRecurringPayments() {
    return appDb.select(appDb.recurringPayments).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<RecurringPayment>> loadRecurringPayments() async {
    final entities = await appDb.select(appDb.recurringPayments).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> insertRecurringPayment(RecurringPayment p) async {
    await appDb.into(appDb.recurringPayments).insert(_mapModelToCompanion(p), mode: InsertMode.replace);
  }

  Future<void> updateRecurringPayment(RecurringPayment p) async {
    await appDb.update(appDb.recurringPayments).replace(_mapModelToCompanion(p));
  }

  Future<void> deleteRecurringPayment(String id) async {
    await (appDb.delete(appDb.recurringPayments)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveRecurringPayments(List<RecurringPayment> payments) async {
    await appDb.transaction(() async {
      await appDb.delete(appDb.recurringPayments).go();
      for (final p in payments) {
        await insertRecurringPayment(p);
      }
    });
  }

  RecurringPayment _mapEntityToModel(RecurringPaymentEntity e) {
    return RecurringPayment(
      id: e.id,
      name: e.name,
      amount: e.amount,
      type: e.type,
      categoryId: e.categoryId,
      walletId: e.walletId,
      frequency: e.frequency,
      startDate: e.startDate,
      nextDueDate: e.nextDueDate,
      isActive: e.isActive,
    );
  }

  RecurringPaymentsCompanion _mapModelToCompanion(RecurringPayment p) {
    return RecurringPaymentsCompanion(
      id: Value(p.id),
      name: Value(p.name),
      amount: Value(p.amount),
      type: Value(p.type),
      categoryId: Value(p.categoryId),
      walletId: Value(p.walletId),
      frequency: Value(p.frequency),
      startDate: Value(p.startDate),
      nextDueDate: Value(p.nextDueDate),
      isActive: Value(p.isActive),
    );
  }
}
