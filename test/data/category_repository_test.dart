import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:moula_flow/data/category_repository.dart';
import 'package:moula_flow/data/database/app_database.dart';
import 'package:moula_flow/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late CategoryRepository repository;

  setUp(() {
    db = AppDatabase.forTest(DatabaseConnection(NativeDatabase.memory()));
    repository = CategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository - Default Categories', () {
    test('injection catégories par défaut si absentes', () async {
      final categories = await repository.loadCategories();
      expect(categories.isNotEmpty, isTrue);
      expect(categories.any((c) => c.id == 'cat_aliment'), isTrue);
    });
  });

  group('CategoryRepository - Persistence', () {
    test('sauvegarde/lecture cohérente', () async {
      final categories = await repository.loadCategories();
      final originalCount = categories.length;

      categories.add(TransactionCategory(id: 'cat_new', name: 'New Category'));
      await repository.saveCategories(categories);

      final loaded = await repository.loadCategories();
      expect(loaded.length, originalCount + 1);
      expect(loaded.any((c) => c.id == 'cat_new'), isTrue);
    });
  });
}
