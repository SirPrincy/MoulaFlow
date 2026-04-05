import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../data/recurring_payment_repository.dart';
import '../data/transaction_repository.dart';

final recurringPaymentServiceProvider = Provider<RecurringPaymentService>((ref) {
  return RecurringPaymentService(
    ref.read(recurringPaymentRepositoryProvider),
    ref.read(transactionRepositoryProvider),
  );
});

class RecurringPaymentService {
  final RecurringPaymentRepository _recurringRepo;
  final TransactionRepository _transactionRepo;

  RecurringPaymentService(this._recurringRepo, this._transactionRepo);

  /// Scans all active recurring payments and processes those that are due.
  /// If [auto] is true, it automatically creates a Transaction.
  /// If [auto] is false, it does nothing (manual validation handled in UI).
  Future<int> checkAndProcessPayments() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final allPayments = await _recurringRepo.loadRecurringPayments();
    final activeDue = allPayments.where((p) => p.isActive && (p.nextDueDate.isBefore(today) || p.nextDueDate.isAtSameMomentAs(today))).toList();

    int processedCount = 0;

    for (final p in activeDue) {
      if (p.executionMode == RecurringExecutionMode.auto) {
        await _executePayment(p);
        processedCount++;
      }
      // Manual payments are left as is; they appear in the "Bills to Pay" page
      // because their nextDueDate is <= today and isActive is true.
    }

    return processedCount;
  }

  /// Creates a transaction and updates the recurring payment's next due date.
  Future<void> _executePayment(RecurringPayment p) async {
    // 1. Create Transaction
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString() + p.id.hashCode.toString(),
      amount: p.amount,
      description: p.name,
      type: p.type,
      date: DateTime.now(),
      walletId: p.walletId,
      categoryId: p.categoryId,
      tags: p.tags,
      recurringPaymentId: p.id,
    );

    await _transactionRepo.insertTransaction(transaction);

    // 2. Schedule next occurrence or deactivate
    late DateTime newNextDueDate;
    bool newIsActive = p.isActive;

    if (p.frequency == RecurrenceFrequency.once) {
      newIsActive = false;
      newNextDueDate = p.nextDueDate; // Doesn't matter much as it's inactive
    } else {
      newNextDueDate = p.getNextDueDate();
    }

    final updatedPayment = p.copyWith(
      isActive: newIsActive,
      nextDueDate: newNextDueDate,
    );

    await _recurringRepo.updateRecurringPayment(updatedPayment);
  }
}
