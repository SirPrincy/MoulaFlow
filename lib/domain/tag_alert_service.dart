import '../models.dart';
import 'tag_filter_service.dart';

class TagAlertRule {
  final String id;
  final String name;
  final TagQuery query;
  final double maxAmount;
  final DateTime periodStart;
  final DateTime periodEnd;

  const TagAlertRule({
    required this.id,
    required this.name,
    required this.query,
    required this.maxAmount,
    required this.periodStart,
    required this.periodEnd,
  });
}

class TagAlertEvaluation {
  final bool isTriggered;
  final double spentAmount;
  final double threshold;

  const TagAlertEvaluation({
    required this.isTriggered,
    required this.spentAmount,
    required this.threshold,
  });
}

class TagAlertService {
  final TagFilterService _tagFilterService;

  TagAlertService({TagFilterService? tagFilterService})
      : _tagFilterService = tagFilterService ?? TagFilterService();

  TagAlertEvaluation evaluateExpenseRule({
    required TagAlertRule rule,
    required List<Transaction> transactions,
    required List<TagDefinition> tagDefinitions,
  }) {
    final periodTx = transactions.where((tx) {
      if (tx.type != TransactionType.expense) return false;
      return !tx.date.isBefore(rule.periodStart) && !tx.date.isAfter(rule.periodEnd);
    }).toList();

    final filtered = _tagFilterService.filterTransactions(
      transactions: periodTx,
      tagDefinitions: tagDefinitions,
      query: rule.query,
    );

    final spent = filtered.fold<double>(0, (sum, tx) => sum + tx.amount.abs());
    return TagAlertEvaluation(
      isTriggered: spent > rule.maxAmount,
      spentAmount: spent,
      threshold: rule.maxAmount,
    );
  }
}
