import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:moula_flow/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('moula_backup_restore_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
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

  test('Backup and Restore should preserve SharedPreferences and Drift Database', () async {
    // 1. Arrange: set some initial data in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', 'TestUser');
    await prefs.setBool('isDarkMode', true);

    // 2. Arrange: set some data in Drift Database
    final walletId = 'wallet-123';
    await db.into(db.wallets).insert(WalletsCompanion.insert(
      id: walletId,
      name: 'Test Wallet',
      type: WalletType.current,
      createdAt: DateTime.now(),
    ));

    final txId = 'tx-456';
    await db.into(db.transactions).insert(TransactionsCompanion.insert(
      id: txId,
      amount: 42.0,
      description: 'Test Transaction',
      type: TransactionType.expense,
      date: DateTime.now(),
      walletId: Value(walletId),
    ));

    // 3. Act: Close before export to ensure file is flushed
    await db.close();
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 4. Act: Export
    final backupBytes = await settingsRepo.exportBinaryBackup();

    // 5. Act: Clear existing data (SharedPreferences only, DB already closed/deleted or will be replaced)
    await prefs.clear();
    
    // 6. Act: Import
    await settingsRepo.importBinaryBackup(backupBytes);
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 7. Re-open database to verify
    db = AppDatabase.forTest(NativeDatabase(dbFile));

    // 6. Assert: SharedPreferences are restored
    final restoredPrefs = await SharedPreferences.getInstance();
    expect(restoredPrefs.getString('userName'), 'TestUser');
    expect(restoredPrefs.getBool('isDarkMode'), true);

    // 7. Assert: Drift Database is restored
    final walletsAfter = await db.select(db.wallets).get();
    expect(walletsAfter.length, 1);
    expect(walletsAfter.first.id, walletId);
    expect(walletsAfter.first.name, 'Test Wallet');

    final txAfter = await db.select(db.transactions).get();
    expect(txAfter.length, 1);
    expect(txAfter.first.id, txId);
    expect(txAfter.first.description, 'Test Transaction');
    expect(txAfter.first.amount, 42.0);
  });
}
