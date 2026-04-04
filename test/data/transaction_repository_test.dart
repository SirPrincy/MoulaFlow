import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/data/transaction_repository.dart';
import 'package:moula_flow/data/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() {
    db = AppDatabase.forTest(DatabaseConnection(NativeDatabase.memory()));
    repository = TransactionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionRepository - Serialization', () {
    test('toJson and fromJson should be symmetrical', () {
      final tx = Transaction(
        id: 't1',
        amount: 50.0,
        description: 'd1',
        type: TransactionType.income,
        date: DateTime(2023, 1, 1),
        walletId: 'w1',
      );

      final json = tx.toJson();
      final decoded = Transaction.fromJson(json);

      expect(decoded.id, tx.id);
      expect(decoded.amount, tx.amount);
      expect(decoded.description, tx.description);
      expect(decoded.type, tx.type);
      expect(decoded.date, tx.date);
      expect(decoded.walletId, tx.walletId);
    });
  });

  group('TransactionRepository - Migration', () {
    test('migration minimale d’un ancien format (pas de walletId)', () {
      final oldTx = Transaction(
        id: 't1',
        amount: 20.0,
        description: 'd1',
        type: TransactionType.income,
        date: DateTime.now(),
        walletId: null, // format ancien
        categoryId: null,
      );

      // Si wallets vides et transactions présentes -> crée main_wallet et assigne tx
      final result = repository.migrateIfNeeded([oldTx], []);

      expect(result.changed, isTrue);
      expect(result.wallets.length, 1);
      expect(result.wallets[0].id, 'main_wallet');
      expect(result.transactions[0].walletId, 'main_wallet');
      expect(result.transactions[0].categoryId, 'cat_divers');
    });

    test('migration avec categoryId manquant', () {
        final tx = Transaction(
          id: 't1',
          amount: 5.0,
          description: 'd1',
          type: TransactionType.income,
          date: DateTime.now(),
          walletId: 'w1',
          categoryId: null, // format ancien sans catégorie
        );
        final wallets = [Wallet(id: 'w1', name: 'w1')];

        final result = repository.migrateIfNeeded([tx], wallets);

        expect(result.changed, isTrue);
        expect(result.transactions[0].categoryId, 'cat_divers');
    });
  });

  group('TransactionRepository - Persistence', () {
    test('sauvegarde/lecture cohérente', () async {
      final txs = [
          Transaction(id: 't1', amount: 10, description: 'd1', type: TransactionType.income, date: DateTime(2024, 1, 1), walletId: 'w1'),
      ];

      await repository.saveTransactions(txs);
      final loaded = await repository.loadTransactions();

      expect(loaded.length, 1);
      expect(loaded[0].id, 't1');
      expect(loaded[0].amount, 10);
    });
  });
}
