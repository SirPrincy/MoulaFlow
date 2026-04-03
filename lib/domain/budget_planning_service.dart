import '../models.dart';

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

class BudgetPlanningService {
  List<Transaction> filterTransactions({
    required List<Transaction> transactions,
    required DateTime start,
    required DateTime end,
    Set<String> walletIds = const {},
    Set<String> categoryIds = const {},
    Set<String> tags = const {},
  }) {
    final normalizedTags = tags.map((e) => e.toLowerCase()).toSet();
    return transactions.where((tx) {
      if (tx.type != TransactionType.expense) return false;
      if (tx.date.isBefore(start) || tx.date.isAfter(end)) return false;
      if (walletIds.isNotEmpty && !walletIds.contains(tx.walletId)) return false;
      if (categoryIds.isNotEmpty && !categoryIds.contains(tx.categoryId)) return false;
      if (normalizedTags.isNotEmpty &&
          !tx.tags.any((t) => normalizedTags.contains(t.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
  }

  double computeSpent(List<Transaction> filtered) {
    return filtered.fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  bool respectsDependency({
    required double amount,
    required BudgetPlan parentBudget,
    required double limitPercent,
  }) {
    return amount <= parentBudget.amount * (limitPercent / 100);
  }

  BudgetProjection projectBudget({
    required double spent,
    required double totalBudget,
    required DateTime start,
    required DateTime end,
    required DateTime now,
  }) {
    final totalDays = end.difference(start).inDays + 1;
    final elapsedDays = now.isBefore(start)
        ? 0
        : (now.isAfter(end) ? totalDays : now.difference(start).inDays + 1);

    if (elapsedDays <= 0) {
      return const BudgetProjection(optimistic: 0, average: 0, pessimistic: 0);
    }

    final dailyRate = spent / elapsedDays;
    final optimistic = dailyRate * 0.8 * totalDays;
    final average = dailyRate * totalDays;
    final pessimistic = dailyRate * 1.2 * totalDays;

    DateTime? overrunDate;
    if (dailyRate > 0 && totalBudget > spent) {
      final remainingDaysForBudget = (totalBudget - spent) / dailyRate;
      final candidate = now.add(Duration(days: remainingDaysForBudget.ceil()));
      if (candidate.isBefore(end) || candidate.isAtSameMomentAs(end)) {
        overrunDate = candidate;
      }
    }

    return BudgetProjection(
      optimistic: optimistic,
      average: average,
      pessimistic: pessimistic,
      estimatedOverrunDate: overrunDate,
    );
  }

  double suggestedNextUnitBudget({
    required double totalBudget,
    required double spent,
    required int elapsedUnits,
    required int totalUnits,
  }) {
    final remaining = (totalBudget - spent).clamp(0, double.infinity);
    final remainingUnits = (totalUnits - elapsedUnits).clamp(1, totalUnits);
    return remaining / remainingUnits;
  }
}
