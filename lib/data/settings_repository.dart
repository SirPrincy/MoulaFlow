import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_access_method.dart';
import 'storage_keys.dart';
import 'database/app_database.dart';
import 'package:moula_flow/utils/app_constants.dart';

class AppSettingsState {
  const AppSettingsState({
    required this.isDarkMode,
    required this.onboardingSeen,
    required this.accessMethod,
    required this.userName,
    required this.userColor,
    required this.userAvatar,
    required this.accentColor,
    required this.currencySymbol,
    required this.baseCurrencyCode,
    required this.decimalDigits,
    required this.biometricsEnabled,
    required this.languageCode,
  });

  final bool isDarkMode;
  final bool onboardingSeen;
  final AppAccessMethod accessMethod;
  final String? userName;
  final int userColor;
  final int userAvatar;
  final int accentColor;
  final String currencySymbol;
  final String baseCurrencyCode;
  final int decimalDigits;
  final bool biometricsEnabled;
  final String? languageCode;
}

class SettingsRepository {
  final AppDatabase? _db;
  SettingsRepository([this._db]);

  static const List<String> _allExportableKeys = [
    StorageKeys.dashboardConfig,
    StorageKeys.isDarkMode,
    StorageKeys.onboardingSeen,
    StorageKeys.appAccessMethod,
    StorageKeys.userName,
    StorageKeys.userColor,
    StorageKeys.userAvatar,
    StorageKeys.accentColor,
    StorageKeys.currencySymbol,
    StorageKeys.walletCurrencyCodes,
    StorageKeys.exchangeRates,
    StorageKeys.baseCurrencyCode,
    StorageKeys.decimalDigits,
    StorageKeys.biometricsEnabled,
    StorageKeys.languageCode,
  ];

  Future<bool> loadIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return _readBool(
      prefs: prefs,
      key: StorageKeys.isDarkMode,
      fallback: false,
    );
  }

  Future<void> saveIsDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isDarkMode, isDark);
  }

  Future<bool> loadOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return _readBool(
      prefs: prefs,
      key: StorageKeys.onboardingSeen,
      fallback: false,
    );
  }

  Future<void> saveOnboardingSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingSeen, seen);
  }

  Future<AppAccessMethod> loadAppAccessMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _readString(
      prefs: prefs,
      key: StorageKeys.appAccessMethod,
      fallback: AppAccessMethod.none.storageValue,
    );
    return AppAccessMethodX.fromStorageValue(raw);
  }

  Future<void> saveAppAccessMethod(AppAccessMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.appAccessMethod, method.storageValue);
  }

  Future<String?> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.userName);
    if (raw == null) return null;
    if (raw is String) return raw;
    _logFallback(StorageKeys.userName, raw, 'null');
    return null;
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userName, name);
  }

  Future<int?> loadUserColor() async {
    final prefs = await SharedPreferences.getInstance();
    return _readOptionalInt(prefs: prefs, key: StorageKeys.userColor);
  }

  Future<void> saveUserColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.userColor, color);
  }

  Future<int?> loadUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return _readOptionalInt(prefs: prefs, key: StorageKeys.userAvatar);
  }

  Future<void> saveUserAvatar(int codePoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.userAvatar, codePoint);
  }

  Future<int?> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return _readOptionalInt(prefs: prefs, key: StorageKeys.accentColor);
  }

  Future<void> saveAccentColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.accentColor, color);
  }

  Future<String?> loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.currencySymbol);
    if (raw == null) return null;
    if (raw is String) return raw;
    _logFallback(StorageKeys.currencySymbol, raw, 'null');
    return null;
  }

  Future<void> saveCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.currencySymbol, symbol);
  }

  Future<String?> loadBaseCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.baseCurrencyCode);
    if (raw == null) return null;
    if (raw is String) return raw;
    _logFallback(StorageKeys.baseCurrencyCode, raw, 'null');
    return null;
  }

  Future<void> saveBaseCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.baseCurrencyCode, code);
  }

  Future<Map<String, String>> loadWalletCurrencyCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.walletCurrencyCodes);
    if (raw == null) return const {};
    if (raw is! String) {
      _logFallback(StorageKeys.walletCurrencyCodes, raw, '{}');
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveWalletCurrencyCode(
    String walletId,
    String currencyCode,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    (await loadWalletCurrencyCodes())[walletId] = currencyCode;
    await prefs.setString(
      StorageKeys.walletCurrencyCodes,
      jsonEncode(await loadWalletCurrencyCodes()),
    );
  }

  Future<void> removeWalletCurrencyCode(String walletId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await loadWalletCurrencyCodes();
    map.remove(walletId);
    await prefs.setString(StorageKeys.walletCurrencyCodes, jsonEncode(map));
  }

  Future<Map<String, double>> loadExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.exchangeRates);
    if (raw == null) return const {};
    if (raw is! String) {
      _logFallback(StorageKeys.exchangeRates, raw, '{}');
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveExchangeRate(
    String fromCode,
    String toCode,
    double rate, {
    String? effectiveDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rates = await loadExchangeRates();
    final dateKey = effectiveDate ?? _formatDateKey(DateTime.now());
    rates['$dateKey|${fromCode}_$toCode'] = rate;
    await prefs.setString(StorageKeys.exchangeRates, jsonEncode(rates));
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<int?> loadDecimalDigits() async {
    final prefs = await SharedPreferences.getInstance();
    return _readOptionalInt(prefs: prefs, key: StorageKeys.decimalDigits);
  }

  Future<void> saveDecimalDigits(int digits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.decimalDigits, digits);
  }

  Future<bool> loadBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return _readBool(
      prefs: prefs,
      key: StorageKeys.biometricsEnabled,
      fallback: false,
    );
  }

  Future<void> saveBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.biometricsEnabled, enabled);
  }

  Future<String?> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(StorageKeys.languageCode);
    if (raw == null) return null;
    if (raw is String) return raw;
    _logFallback(StorageKeys.languageCode, raw, 'null');
    return null;
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.languageCode, code);
  }

  Future<AppSettingsState> loadAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettingsState(
      isDarkMode: _readBool(
        prefs: prefs,
        key: StorageKeys.isDarkMode,
        fallback: false,
      ),
      onboardingSeen: _readBool(
        prefs: prefs,
        key: StorageKeys.onboardingSeen,
        fallback: false,
      ),
      accessMethod: AppAccessMethodX.fromStorageValue(
        _readString(
          prefs: prefs,
          key: StorageKeys.appAccessMethod,
          fallback: AppAccessMethod.none.storageValue,
        ),
      ),
      userName:
          _readOptionalString(prefs: prefs, key: StorageKeys.userName) ??
          AppConstants.defaultUserName,
      userColor: _readInt(
        prefs: prefs,
        key: StorageKeys.userColor,
        fallback: 0xFF6200EE,
      ),
      userAvatar: _readInt(
        prefs: prefs,
        key: StorageKeys.userAvatar,
        fallback: AppConstants.defaultUserAvatar,
      ),
      accentColor: _readInt(
        prefs: prefs,
        key: StorageKeys.accentColor,
        fallback: 0xFFBCC2FF,
      ),
      currencySymbol: _readString(
        prefs: prefs,
        key: StorageKeys.currencySymbol,
        fallback: 'Ar',
      ),
      baseCurrencyCode: _readString(
        prefs: prefs,
        key: StorageKeys.baseCurrencyCode,
        fallback: 'MGA',
      ),
      decimalDigits: _readInt(
        prefs: prefs,
        key: StorageKeys.decimalDigits,
        fallback: 2,
      ),
      biometricsEnabled: _readBool(
        prefs: prefs,
        key: StorageKeys.biometricsEnabled,
        fallback: false,
      ),
      languageCode: _readOptionalString(
        prefs: prefs,
        key: StorageKeys.languageCode,
      ),
    );
  }

  bool _readBool({
    required SharedPreferences prefs,
    required String key,
    required bool fallback,
  }) {
    final raw = prefs.get(key);
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    _logFallback(key, raw, fallback);
    return fallback;
  }

  int _readInt({
    required SharedPreferences prefs,
    required String key,
    required int fallback,
  }) {
    final raw = prefs.get(key);
    if (raw == null) return fallback;
    if (raw is int) return raw;
    _logFallback(key, raw, fallback);
    return fallback;
  }

  int? _readOptionalInt({
    required SharedPreferences prefs,
    required String key,
  }) {
    final raw = prefs.get(key);
    if (raw == null) return null;
    if (raw is int) return raw;
    _logFallback(key, raw, 'null');
    return null;
  }

  String _readString({
    required SharedPreferences prefs,
    required String key,
    required String fallback,
  }) {
    final raw = prefs.get(key);
    if (raw == null) return fallback;
    if (raw is String) return raw;
    _logFallback(key, raw, fallback);
    return fallback;
  }

  String? _readOptionalString({
    required SharedPreferences prefs,
    required String key,
  }) {
    final raw = prefs.get(key);
    if (raw == null) return null;
    if (raw is String) return raw;
    _logFallback(key, raw, 'null');
    return null;
  }

  void _logFallback(String key, Object rawValue, Object fallback) {
    debugPrint(
      '[SettingsRepository] Invalid value for "$key": '
      '"$rawValue" (${rawValue.runtimeType}). Using fallback: $fallback',
    );
  }

  Future<void> clearAllDataExceptTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(StorageKeys.isDarkMode);
    await _db?.clearAllData();
    await prefs.clear();
    if (isDark != null) {
      await prefs.setBool(StorageKeys.isDarkMode, isDark);
    }
  }

  Future<Uint8List> exportBinaryBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final meta = <String, dynamic>{};
    for (final key in _allExportableKeys) {
      meta[key] = prefs.get(key);
    }
    final metaBytes = utf8.encode(jsonEncode(meta));

    final dbPath = await AppDatabase.getDbFilePath();
    final dbFile = File(dbPath);
    final dbBytes = await dbFile.exists()
        ? await dbFile.readAsBytes()
        : Uint8List(0);

    final result = BytesBuilder();

    // 1. Header (16 bytes)
    final header = ascii.encode('MOULA_FLOW_BK_1'.padRight(16));
    result.add(header);

    // 2. Meta Segment
    final metaLen = ByteData(4)..setInt32(0, metaBytes.length);
    result.add(metaLen.buffer.asUint8List());
    result.add(metaBytes);

    // 3. DB Segment
    final dbLen = ByteData(4)..setInt32(0, dbBytes.length);
    result.add(dbLen.buffer.asUint8List());
    result.add(dbBytes);

    return result.toBytes();
  }

  Future<void> importBinaryBackup(Uint8List bytes) async {
    if (bytes.length < 16)
      throw const FormatException('Données de sauvegarde trop courtes.');

    final data = ByteData.sublistView(bytes);
    final header = ascii.decode(bytes.sublist(0, 16)).trim();
    if (header != 'MOULA_FLOW_BK_1')
      throw const FormatException('Format de sauvegarde invalide.');

    var offset = 16;

    // 1. Meta Segment
    if (offset + 4 > bytes.length)
      throw const FormatException('Données de segment méta manquantes.');
    final metaLen = data.getInt32(offset);
    offset += 4;

    if (offset + metaLen > bytes.length)
      throw const FormatException('Taille de segment méta invalide.');
    final metaBytes = bytes.sublist(offset, offset + metaLen);
    offset += metaLen;
    final meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;

    // 2. DB Segment
    if (offset + 4 > bytes.length)
      throw const FormatException('Données de segment DB manquantes.');
    final dbLen = data.getInt32(offset);
    offset += 4;

    if (offset + dbLen > bytes.length)
      throw const FormatException('Taille de segment DB invalide.');
    final dbBytes = bytes.sublist(offset, offset + dbLen);

    // Apply DB first (atomic replacement)
    await _db?.hardClose();
    final dbPath = await AppDatabase.getDbFilePath();
    final dbFile = File(dbPath);
    final tmpFile = File('$dbPath.tmp');
    final oldFile = File('$dbPath.old');
    if (await tmpFile.exists()) {
      await tmpFile.delete();
    }
    await tmpFile.writeAsBytes(dbBytes, flush: true);

    try {
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
      if (await dbFile.exists()) {
        await dbFile.rename(oldFile.path);
      }
      await tmpFile.rename(dbFile.path);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    } catch (_) {
      if (await oldFile.exists() && !await dbFile.exists()) {
        await oldFile.rename(dbFile.path);
      }
      rethrow;
    } finally {
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
    }

    // Apply Meta (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    for (final entry in meta.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is List) {
        await prefs.setStringList(
          entry.key,
          value.map((e) => e.toString()).toList(),
        );
      }
    }
  }

  Future<bool> shouldShowRecoveryHint() async {
    if (_db == null) return false;
    final userName = await loadUserName();
    if (userName == null || userName.trim().isEmpty) return false;

    final walletsRow = await _db
        .customSelect('SELECT COUNT(*) AS c FROM wallets;')
        .getSingle();
    final transactionsRow = await _db
        .customSelect('SELECT COUNT(*) AS c FROM transactions;')
        .getSingle();
    return walletsRow.read<int>('c') == 0 &&
        transactionsRow.read<int>('c') == 0;
  }
}
