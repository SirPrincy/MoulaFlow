import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/data/database/app_database.dart';
import 'package:drift/native.dart';

void main() {
  late SettingsRepository settingsRepo;
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTest(NativeDatabase.memory());
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Backup and Restore should preserve SharedPreferences', () async {
    // 1. Arrange: set some initial data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', 'TestUser');
    await prefs.setBool('isDarkMode', true);

    // 2. Act: Export
    final backupBytes = await settingsRepo.exportBinaryBackup();

    // 3. Act: Clear existing
    await prefs.clear();
    expect(prefs.getString('userName'), null);

    // 4. Act: Import
    await settingsRepo.importBinaryBackup(backupBytes);

    // 5. Assert: Data is restored
    final restoredPrefs = await SharedPreferences.getInstance();
    expect(restoredPrefs.getString('userName'), 'TestUser');
    expect(restoredPrefs.getBool('isDarkMode'), true);
  });
}
