import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/domain/budget_planning_service.dart';
import 'package:moula_flow/models.dart';

void main() {
  final service = BudgetPlanningService();

  test('filtre transactions par wallet/catégorie/tag et période', () {
    final txs = [
      Transaction(id: '1', amount: 10, description: '', type: TransactionType.expense, date: DateTime(2026, 4, 1), walletId: 'w1', categoryId: 'c1', tags: const ['food']),
      Transaction(id: '2', amount: 10, description: '', type: TransactionType.expense, date: DateTime(2026, 4, 2), walletId: 'w2', categoryId: 'c1', tags: const ['food']),
      Transaction(id: '3', amount: 8, description: '', type: TransactionType.expense, date: DateTime(2026, 4, 2), walletId: 'w1', categoryId: 'c2', tags: const ['taxi']),
    ];

    final filtered = service.filterTransactions(
      transactions: txs,
      start: DateTime(2026, 4, 1),
      end: DateTime(2026, 4, 3),
      walletIds: const {'w1'},
      categoryIds: const {'c1'},
      tags: const {'food'},
    );

    expect(filtered.length, 1);
    expect(filtered.first.id, '1');
  });

  test('filtre transactions avec tags exclus et type de tag inclus', () {
    final txs = [
      Transaction(id: '1', amount: 10, description: '', type: TransactionType.expense, date: DateTime(2026, 4, 1), walletId: 'w1', categoryId: 'c1', tags: const ['food']),
      Transaction(id: '2', amount: 15, description: '', type: TransactionType.expense, date: DateTime(2026, 4, 2), walletId: 'w1', categoryId: 'c1', tags: const ['projetx']),
    ];
    final defs = [
      TagDefinition(id: 't1', name: 'food', type: TagType.expense),
      TagDefinition(id: 't2', name: 'projetx', type: TagType.project),
    ];
    final service = BudgetPlanningService();

    final filtered = service.filterTransactions(
      transactions: txs,
      start: DateTime(2026, 4, 1),
      end: DateTime(2026, 4, 30),
      tagDefinitions: defs,
      excludedTagTypes: const {TagType.project},
    );

    expect(filtered.map((e) => e.id), ['1']);
  });

  test('respecte dépendance de budget parent', () {
    final parent = BudgetPlan(
      id: 'p',
      name: 'Mensuel',
      periodType: BudgetPeriodType.monthly,
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 4, 30),
      amount: 1000,
    );

    expect(service.respectsDependency(amount: 250, parentBudget: parent, limitPercent: 30), isTrue);
    expect(service.respectsDependency(amount: 400, parentBudget: parent, limitPercent: 30), isFalse);
  });
}
