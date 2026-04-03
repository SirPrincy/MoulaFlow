import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/domain/tag_management_service.dart';
import 'package:moula_flow/models.dart';

void main() {
  group('TagManagementService', () {
    final service = TagManagementService();

    test('empêche la création de doublon de nom', () {
      final tags = [
        TagDefinition(id: '1', name: 'Food', type: TagType.expense),
      ];

      expect(
        () => service.createTag(
          tags: tags,
          tag: TagDefinition(id: '2', name: 'food', type: TagType.expense),
          transactions: const [],
          budgets: const [],
        ),
        throwsArgumentError,
      );
    });

    test('renomme dans transactions et budgets', () {
      final tags = [
        TagDefinition(id: '1', name: 'Food', type: TagType.expense),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 25,
          description: '',
          type: TransactionType.expense,
          date: DateTime(2026, 4, 1),
          tags: const ['Food', 'Fixe'],
        ),
      ];
      final budgets = [
        BudgetPlan(
          id: 'b1',
          name: 'Budget',
          periodType: BudgetPeriodType.monthly,
          startDate: DateTime(2026, 4, 1),
          endDate: DateTime(2026, 4, 30),
          tags: const ['Food'],
          excludedTags: const ['Taxi'],
          amount: 100,
        ),
      ];

      final res = service.updateTag(
        tags: tags,
        updatedTag: TagDefinition(id: '1', name: 'Alimentation', type: TagType.expense),
        transactions: txs,
        budgets: budgets,
      );

      expect(res.transactions.first.tags, contains('Alimentation'));
      expect(res.transactions.first.tags, isNot(contains('Food')));
      expect(res.budgets.first.tags, contains('Alimentation'));
    });

    test('suppression avec remplacement', () {
      final tags = [
        TagDefinition(id: '1', name: 'Taxi', type: TagType.expense),
      ];
      final txs = [
        Transaction(
          id: 'tx1',
          amount: 12,
          description: '',
          type: TransactionType.expense,
          date: DateTime(2026, 4, 1),
          tags: const ['Taxi'],
        ),
      ];

      final res = service.deleteTag(
        tags: tags,
        tagId: '1',
        action: const TagDeleteAction.replaceWith('Transport'),
        transactions: txs,
        budgets: const [],
      );

      expect(res.tags, isEmpty);
      expect(res.transactions.first.tags, contains('Transport'));
    });
  });
}
