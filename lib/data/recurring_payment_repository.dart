import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'storage_keys.dart';

class RecurringPaymentRepository {
  Future<List<RecurringPayment>> loadRecurringPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(StorageKeys.recurringPayments);
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => RecurringPayment.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveRecurringPayments(List<RecurringPayment> payments) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.recurringPayments, 
      jsonEncode(payments.map((p) => p.toJson()).toList())
    );
  }
}
