import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class BudgetRepository {
  Stream<List<BudgetPlan>> watchBudgets() {
    return appDb.select(appDb.budgets).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<BudgetPlan>> loadBudgets() async {
    final entities = await appDb.select(appDb.budgets).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> insertBudget(BudgetPlan budget) async {
    await appDb.into(appDb.budgets).insert(_mapModelToCompanion(budget), mode: InsertMode.replace);
  }

  Future<void> updateBudget(BudgetPlan budget) async {
    await appDb.update(appDb.budgets).replace(_mapModelToCompanion(budget));
  }

  Future<void> deleteBudget(String id) async {
    await (appDb.delete(appDb.budgets)..where((t) => t.id.equals(id))).go();
  }

  Future<void> saveBudgets(List<BudgetPlan> budgets) async {
    await appDb.transaction(() async {
      await appDb.delete(appDb.budgets).go();
      for (final b in budgets) {
        await insertBudget(b);
      }
    });
  }

  BudgetPlan _mapEntityToModel(BudgetPlanEntity e) {
    return BudgetPlan(
      id: e.id,
      name: e.name,
      periodType: e.periodType,
      startDate: e.startDate,
      endDate: e.endDate,
      walletIds: e.walletIds,
      categoryIds: e.categoryIds,
      includeAllCategories: e.includeAllCategories,
      tags: e.tags,
      excludedTags: e.excludedTags,
      includedTagTypes: e.includedTagTypes,
      excludedTagTypes: e.excludedTagTypes,
      amount: e.amount,
      enableAlerts: e.enableAlerts,
      enableProgressiveAdjustment: e.enableProgressiveAdjustment,
      dependencyBudgetId: e.dependencyBudgetId,
      dependencyPercentLimit: e.dependencyPercentLimit,
      repeatFrequency: e.repeatFrequency,
      repeatAdjustmentPercent: e.repeatAdjustmentPercent,
      createdAt: e.createdAt,
    );
  }

  BudgetsCompanion _mapModelToCompanion(BudgetPlan b) {
    return BudgetsCompanion(
      id: Value(b.id),
      name: Value(b.name),
      periodType: Value(b.periodType),
      startDate: Value(b.startDate),
      endDate: Value(b.endDate),
      walletIds: Value(b.walletIds),
      categoryIds: Value(b.categoryIds),
      includeAllCategories: Value(b.includeAllCategories),
      tags: Value(b.tags),
      excludedTags: Value(b.excludedTags),
      includedTagTypes: Value(b.includedTagTypes),
      excludedTagTypes: Value(b.excludedTagTypes),
      amount: Value(b.amount),
      enableAlerts: Value(b.enableAlerts),
      enableProgressiveAdjustment: Value(b.enableProgressiveAdjustment),
      dependencyBudgetId: Value(b.dependencyBudgetId),
      dependencyPercentLimit: Value(b.dependencyPercentLimit),
      repeatFrequency: Value(b.repeatFrequency),
      repeatAdjustmentPercent: Value(b.repeatAdjustmentPercent),
      createdAt: Value(b.createdAt),
    );
  }
}
