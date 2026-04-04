import 'package:drift/drift.dart';
import '../models.dart';
import 'database/app_database.dart';

class WalletRepository {
  Wallet _mapEntityToModel(WalletEntity entity) {
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
    return appDb.select(appDb.wallets).watch().map((entities) {
      return entities.map(_mapEntityToModel).toList();
    });
  }

  Future<List<Wallet>> loadWallets() async {
    final entities = await appDb.select(appDb.wallets).get();
    return entities.map(_mapEntityToModel).toList();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    await appDb.transaction(() async {
      await appDb.delete(appDb.wallets).go();
      for (final w in wallets) {
        await appDb.into(appDb.wallets).insert(_mapModelToCompanion(w));
      }
    });
  }

  Future<void> insertWallet(Wallet wallet) async {
    await appDb.into(appDb.wallets).insert(_mapModelToCompanion(wallet), mode: InsertMode.replace);
  }

  Future<void> updateWallet(Wallet wallet) async {
    await appDb.update(appDb.wallets).replace(_mapModelToCompanion(wallet));
  }

  Future<void> deleteWallet(String id) async {
    await (appDb.delete(appDb.wallets)..where((tbl) => tbl.id.equals(id))).go();
  }
}
