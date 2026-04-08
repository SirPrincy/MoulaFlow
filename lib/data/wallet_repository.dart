import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';
import 'settings_repository.dart';

class WalletRepository {
  final AppDatabase db;
  final SettingsRepository settingsRepository;

  WalletRepository(this.db, this.settingsRepository);

  Wallet _mapEntityToModel(WalletEntity entity, Map<String, String> walletCurrencies) {
    return Wallet(
      id: entity.id,
      name: entity.name,
      initialBalance: entity.initialBalance,
      type: entity.type,
      createdAt: entity.createdAt,
      targetAmount: entity.targetAmount,
      dueDate: entity.dueDate,
      isSettled: entity.isSettled,
      isCredit: entity.isCredit,
      interestRate: entity.interestRate,
      currencyCode: walletCurrencies[entity.id] ?? 'MGA',
    );
  }

  WalletsCompanion _mapModelToCompanion(Wallet wallet) {
    return WalletsCompanion(
      id: Value(wallet.id),
      name: Value(wallet.name),
      initialBalance: Value(wallet.initialBalance),
      type: Value(wallet.type),
      createdAt: Value(wallet.createdAt),
      targetAmount: Value(wallet.targetAmount),
      dueDate: Value(wallet.dueDate),
      isSettled: Value(wallet.isSettled),
      isCredit: Value(wallet.isCredit),
      interestRate: Value(wallet.interestRate),
    );
  }

  Stream<List<Wallet>> watchWallets() {
    return db.select(db.wallets).watch().asyncMap((entities) async {
      final walletCurrencies = await settingsRepository.loadWalletCurrencyCodes();
      return entities.map((e) => _mapEntityToModel(e, walletCurrencies)).toList();
    });
  }

  Future<List<Wallet>> loadWallets() async {
    final entities = await db.select(db.wallets).get();
    final walletCurrencies = await settingsRepository.loadWalletCurrencyCodes();
    return entities.map((e) => _mapEntityToModel(e, walletCurrencies)).toList();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    await db.transaction(() async {
      await db.delete(db.wallets).go();
      for (final w in wallets) {
        await db.into(db.wallets).insert(_mapModelToCompanion(w));
        await settingsRepository.saveWalletCurrencyCode(w.id, w.currencyCode);
      }
    });
  }

  Future<void> insertWallet(Wallet wallet) async {
    await db.into(db.wallets).insert(_mapModelToCompanion(wallet), mode: InsertMode.replace);
    await settingsRepository.saveWalletCurrencyCode(wallet.id, wallet.currencyCode);
  }

  Future<void> updateWallet(Wallet wallet) async {
    await db.update(db.wallets).replace(_mapModelToCompanion(wallet));
    await settingsRepository.saveWalletCurrencyCode(wallet.id, wallet.currencyCode);
  }

  Future<void> deleteWallet(String id) async {
    await (db.delete(db.wallets)..where((tbl) => tbl.id.equals(id))).go();
    await settingsRepository.removeWalletCurrencyCode(id);
  }
}
