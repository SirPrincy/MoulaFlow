import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'storage_keys.dart';

class WalletRepository {
  Future<List<Wallet>> loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? walletsData = prefs.getString(StorageKeys.wallets);
    if (walletsData != null) {
      final List<dynamic> jsonList = jsonDecode(walletsData);
      return jsonList.map((json) => Wallet.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.wallets, jsonEncode(wallets.map((w) => w.toJson()).toList()));
  }
}
