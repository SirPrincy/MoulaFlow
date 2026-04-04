import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_access_method.dart';
import 'storage_keys.dart';
import 'database/app_database.dart';

class SettingsRepository {
  final AppDatabase? _db;
  SettingsRepository([this._db]);

  static const int _backupVersion = 1;

  static const List<String> _allExportableKeys = [
    StorageKeys.wallets,
    StorageKeys.transactions,
    StorageKeys.categories,
    StorageKeys.tags,
    StorageKeys.recurringPayments,
    StorageKeys.dashboardConfig,
    StorageKeys.isDarkMode,
    StorageKeys.onboardingSeen,
    StorageKeys.appAccessMethod,
    StorageKeys.userName,
    StorageKeys.userColor,
    StorageKeys.userAvatar,
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

  Future<void> clearAllDataExceptTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(StorageKeys.isDarkMode);
    await _db?.clearAllData();
    await prefs.clear();
    if (isDark != null) {
      await prefs.setBool(StorageKeys.isDarkMode, isDark);
    }
  }

  Future<String> exportAllDataAsJson() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': <String, dynamic>{},
    };

    final data = payload['data'] as Map<String, dynamic>;
    for (final key in _allExportableKeys) {
      data[key] = prefs.get(key);
    }

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importAllDataFromJson(String rawJson) async {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Le JSON doit être un objet.');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Le champ "data" est manquant ou invalide.');
    }

    final prefs = await SharedPreferences.getInstance();
    await _db?.clearAllData();
    await prefs.clear();

    for (final key in _allExportableKeys) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (value == null) continue;

      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      } else if (value is List) {
        await prefs.setStringList(key, value.map((e) => e.toString()).toList());
      } else {
        throw FormatException('Type non supporté pour la clé "$key".');
      }
    }
  }

  Future<String> exportAllDataAsCsv() async {
    final prefs = await SharedPreferences.getInstance();
    final buffer = StringBuffer();
    buffer.writeln('key,type,value_base64');
    buffer.writeln('_meta_version,int,${_encodeCsvValue(_backupVersion.toString())}');
    buffer.writeln(
      '_meta_exportedAt,string,${_encodeCsvValue(DateTime.now().toIso8601String())}',
    );

    for (final key in _allExportableKeys) {
      final value = prefs.get(key);
      if (value == null) continue;
      final type = _typeOfValue(value);
      final serialized = _serializeValue(value);
      buffer.writeln('$key,$type,${_encodeCsvValue(serialized)}');
    }

    return buffer.toString();
  }

  Future<void> importAllDataFromCsv(String rawCsv) async {
    final lines = rawCsv
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty || lines.first != 'key,type,value_base64') {
      throw const FormatException('CSV invalide: en-tête manquant.');
    }

    final prefs = await SharedPreferences.getInstance();
    await _db?.clearAllData();
    await prefs.clear();

    for (final line in lines.skip(1)) {
      final parts = line.split(',');
      if (parts.length < 3) {
        throw FormatException('CSV invalide: ligne mal formée "$line".');
      }

      final key = parts[0];
      final type = parts[1];
      final encodedValue = parts.sublist(2).join(',');
      final decodedValue = utf8.decode(base64Decode(encodedValue));

      if (key.startsWith('_meta_')) continue;
      if (!_allExportableKeys.contains(key)) continue;

      switch (type) {
        case 'string':
          await prefs.setString(key, decodedValue);
          break;
        case 'bool':
          await prefs.setBool(key, decodedValue == 'true');
          break;
        case 'int':
          await prefs.setInt(key, int.parse(decodedValue));
          break;
        case 'double':
          await prefs.setDouble(key, double.parse(decodedValue));
          break;
        case 'string_list':
          final list = (jsonDecode(decodedValue) as List<dynamic>)
              .map((e) => e.toString())
              .toList();
          await prefs.setStringList(key, list);
          break;
        default:
          throw FormatException('Type CSV non supporté: "$type".');
      }
    }
  }

  String _encodeCsvValue(String value) => base64Encode(utf8.encode(value));

  String _typeOfValue(Object value) {
    if (value is String) return 'string';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is List<String>) return 'string_list';
    if (value is List) return 'string_list';
    throw FormatException('Type non supporté pour export CSV: ${value.runtimeType}');
  }

  String _serializeValue(Object value) {
    if (value is List<String>) return jsonEncode(value);
    if (value is List) return jsonEncode(value.map((e) => e.toString()).toList());
    return value.toString();
  }
}
