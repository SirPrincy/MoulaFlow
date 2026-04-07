import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_access_method.dart';
import 'storage_keys.dart';
import 'database/app_database.dart';

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
    StorageKeys.decimalDigits,
    StorageKeys.biometricsEnabled,
    StorageKeys.languageCode,
  ];

  Future<bool> loadIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.isDarkMode) ?? false;
  }

  Future<void> saveIsDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isDarkMode, isDark);
  }

  Future<bool> loadOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.onboardingSeen) ?? false;
  }

  Future<void> saveOnboardingSeen(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.onboardingSeen, seen);
  }

  Future<AppAccessMethod> loadAppAccessMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.appAccessMethod);
    return AppAccessMethodX.fromStorageValue(raw);
  }

  Future<void> saveAppAccessMethod(AppAccessMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.appAccessMethod, method.storageValue);
  }

  Future<String?> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.userName);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userName, name);
  }

  Future<int?> loadUserColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.userColor);
  }

  Future<void> saveUserColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.userColor, color);
  }

  Future<int?> loadUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.userAvatar);
  }

  Future<void> saveUserAvatar(int codePoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.userAvatar, codePoint);
  }

  Future<int?> loadAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.accentColor);
  }

  Future<void> saveAccentColor(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.accentColor, color);
  }

  Future<String?> loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.currencySymbol);
  }

  Future<void> saveCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.currencySymbol, symbol);
  }

  Future<int?> loadDecimalDigits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.decimalDigits);
  }

  Future<void> saveDecimalDigits(int digits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.decimalDigits, digits);
  }

  Future<bool> loadBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(StorageKeys.biometricsEnabled) ?? false;
  }

  Future<void> saveBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.biometricsEnabled, enabled);
  }

  Future<String?> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.languageCode);
  }

  Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.languageCode, code);
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
    final dbBytes = await dbFile.exists() ? await dbFile.readAsBytes() : Uint8List(0);

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
    if (bytes.length < 16) throw const FormatException('Données de sauvegarde trop courtes.');

    final data = ByteData.sublistView(bytes);
    final header = ascii.decode(bytes.sublist(0, 16)).trim();
    if (header != 'MOULA_FLOW_BK_1') throw const FormatException('Format de sauvegarde invalide.');

    var offset = 16;

    // 1. Meta Segment
    if (offset + 4 > bytes.length) throw const FormatException('Données de segment méta manquantes.');
    final metaLen = data.getInt32(offset);
    offset += 4;
    
    if (offset + metaLen > bytes.length) throw const FormatException('Taille de segment méta invalide.');
    final metaBytes = bytes.sublist(offset, offset + metaLen);
    offset += metaLen;
    final meta = jsonDecode(utf8.decode(metaBytes)) as Map<String, dynamic>;

    // 2. DB Segment
    if (offset + 4 > bytes.length) throw const FormatException('Données de segment DB manquantes.');
    final dbLen = data.getInt32(offset);
    offset += 4;
    
    if (offset + dbLen > bytes.length) throw const FormatException('Taille de segment DB invalide.');
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
        await prefs.setStringList(entry.key, value.map((e) => e.toString()).toList());
      }
    }
  }

  Future<bool> shouldShowRecoveryHint() async {
    if (_db == null) return false;
    final userName = await loadUserName();
    if (userName == null || userName.trim().isEmpty) return false;

    final walletsRow = await _db!.customSelect('SELECT COUNT(*) AS c FROM wallets;').getSingle();
    final transactionsRow = await _db!.customSelect('SELECT COUNT(*) AS c FROM transactions;').getSingle();
    return walletsRow.read<int>('c') == 0 && transactionsRow.read<int>('c') == 0;
  }
}
