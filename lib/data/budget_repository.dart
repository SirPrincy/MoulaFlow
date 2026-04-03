import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'storage_keys.dart';

class BudgetRepository {
  Future<List<BudgetPlan>> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? budgetsData = prefs.getString(StorageKeys.budgets);
    if (budgetsData == null) return [];
    final List<dynamic> jsonList = jsonDecode(budgetsData);
    return jsonList.map((e) => BudgetPlan.fromJson(e)).toList();
  }

  Future<void> saveBudgets(List<BudgetPlan> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.budgets,
      jsonEncode(budgets.map((b) => b.toJson()).toList()),
    );
  }
}
