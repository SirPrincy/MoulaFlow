import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';

class BudgetCard extends ConsumerWidget {
  final String budgetId;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budgetId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider(budgetId));

    return statusAsync.when(
      data: (status) => _buildCard(context, status),
      loading: () => const Card(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, s) => Card(
        child: ListTile(
          title: const Text('Erreur de chargement'),
          subtitle: Text(e.toString()),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color progressColor;
    if (status.isOverBudget) {
      progressColor = Colors.redAccent;
    } else if (status.isNearLimit) {
      progressColor = Colors.orangeAccent;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    final daysLeft = status.plan.endDate.difference(DateTime.now()).inDays;
    final formattedDays = daysLeft < 0 ? 'Terminé' : (daysLeft == 0 ? 'Dernier jour' : '$daysLeft jours restants');

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: status.isOverBudget ? 4 : 2,
      shadowColor: status.isOverBudget ? Colors.redAccent.withValues(alpha: 0.4) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: status.isOverBudget 
          ? const BorderSide(color: Colors.redAccent, width: 1.5) 
          : BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedDays,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(status.percentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatAmount(status.spent),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatAmount(status.plan.amount),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: status.percentage.clamp(0, 1),
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    status.isOverBudget ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: status.isOverBudget ? Colors.redAccent : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      status.isOverBudget
                          ? 'Budget dépassé de ${formatAmount(status.spent - status.plan.amount)}'
                          : 'Reste ${formatAmount(status.remaining)} à dépenser',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: status.isOverBudget ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
