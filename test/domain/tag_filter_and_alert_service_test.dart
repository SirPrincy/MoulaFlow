import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/domain/tag_alert_service.dart';
import 'package:moula_flow/domain/tag_filter_service.dart';
import 'package:moula_flow/models.dart';

void main() {
  final tags = [
    TagDefinition(id: '1', name: 'Food', type: TagType.expense),
    TagDefinition(id: '2', name: 'ProjetX', type: TagType.project),
  ];
  final txs = [
    Transaction(
      id: 't1',
      amount: 20,
      description: '',
      type: TransactionType.expense,
      date: DateTime(2026, 4, 1),
      tags: const ['Food', 'ProjetX'],
    ),
    Transaction(
      id: 't2',
      amount: 35,
      description: '',
      type: TransactionType.expense,
      date: DateTime(2026, 4, 2),
      tags: const ['Food'],
    ),
  ];

  test('filtre AND / OR / NOT sur tags et types', () {
    final service = TagFilterService();

    final andResult = service.filterTransactions(
      transactions: txs,
      tagDefinitions: tags,
      query: const TagQuery(
        includeTags: {'food', 'projetx'},
        operatorMode: TagQueryOperator.and,
      ),
    );
    expect(andResult.map((e) => e.id), ['t1']);

    final notResult = service.filterTransactions(
      transactions: txs,
      tagDefinitions: tags,
      query: const TagQuery(excludeTypes: {TagType.project}),
    );
    expect(notResult.map((e) => e.id), ['t2']);
  });

  test('déclenche alerte sur dépassement de seuil', () {
    final alertService = TagAlertService();
    final rule = TagAlertRule(
      id: 'r1',
      name: 'Alerte dépense food',
      query: const TagQuery(
        includeTags: {'food'},
        includeTypes: {TagType.expense},
      ),
      maxAmount: 50,
      periodStart: DateTime(2026, 4, 1),
      periodEnd: DateTime(2026, 4, 30),
    );

    final evaluation = alertService.evaluateExpenseRule(
      rule: rule,
      transactions: txs,
      tagDefinitions: tags,
    );

    expect(evaluation.spentAmount, 55);
    expect(evaluation.isTriggered, isTrue);
  });
}
