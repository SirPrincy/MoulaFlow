import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:moula_flow/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  late SettingsRepository settingsRepo;
  late AppDatabase db;
  late File dbFile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final path = await AppDatabase.getDbFilePath();
    dbFile = File(path);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    db = AppDatabase.forTest(NativeDatabase(dbFile));
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  });

  test('Full Round-Trip: Backup -> Clear All -> Restore', () async {
    // 1. Arrange: Setup initial state (Prefs + DB)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', 'RoundTripUser');
    await prefs.setBool('isDarkMode', true);
    await prefs.setBool('onboardingSeen', true);
    
    final walletId = 'wallet-id-1';
    await db.into(db.wallets).insert(WalletsCompanion.insert(
      id: walletId,
      name: 'Round Trip Wallet',
      type: WalletType.current,
      createdAt: DateTime.now(),
    ));

    // 2. Act: Backup
    await db.close(); // Flush
    final backupBytes = await settingsRepo.exportBinaryBackup();
    
    // Reopen for clear operation
    db = AppDatabase.forTest(NativeDatabase(dbFile));
    settingsRepo = SettingsRepository(db);

    // 3. Act: Clear All Data (except theme, per logic)
    await settingsRepo.clearAllDataExceptTheme();
    
    // Verify it's cleared
    expect(prefs.getBool('isDarkMode'), true); // Should be kept
    expect(prefs.getString('userName'), null);
    expect(prefs.getBool('onboardingSeen'), null);
    
    await db.close();
    db = AppDatabase.forTest(NativeDatabase(dbFile));
    final walletsBefore = await db.select(db.wallets).get();
    expect(walletsBefore.isEmpty, true);

    // 4. Act: Restore
    await db.close();
    await settingsRepo.importBinaryBackup(backupBytes);
    
    // 5. Assert: Data is back
    db = AppDatabase.forTest(NativeDatabase(dbFile));
    final restoredPrefs = await SharedPreferences.getInstance();
    expect(restoredPrefs.getString('userName'), 'RoundTripUser');
    expect(restoredPrefs.getBool('onboardingSeen'), true);
    expect(restoredPrefs.getBool('isDarkMode'), true);

    final walletsAfter = await db.select(db.wallets).get();
    expect(walletsAfter.length, 1);
    expect(walletsAfter.first.name, 'Round Trip Wallet');
  });
}
