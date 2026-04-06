import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/transaction_tile.dart';
import '../responsive_layout.dart';

class BudgetDetailPage extends ConsumerWidget {
  final String budgetId;

  const BudgetDetailPage({super.key, required this.budgetId});

  Future<void> _deleteBudget(BuildContext context, WidgetRef ref, BudgetPlan plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le budget'),
        content: Text('Voulez-vous vraiment supprimer le budget "${plan.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(budgetRepositoryProvider).deleteBudget(plan.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget supprimé')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider(budgetId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final walletsAsync = ref.watch(walletsProvider);

    return statusAsync.when(
      data: (status) {
        final plan = status.plan;
        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _deleteBudget(context, ref, plan),
              ),
            ],
          ),
          body: ResponsiveCenter(
            maxWidth: 800,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, status),
                  const SizedBox(height: 32),
                  _buildProjections(context, status),
                  const SizedBox(height: 32),
                  Text(
                    'Transactions (${status.transactions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (status.transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text('Aucune transaction pour ce budget.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                      ),
                    )
                  else
                    ...status.transactions.map((tx) {
                      return categoriesAsync.when(
                        data: (categories) {
                          return walletsAsync.when(
                            data: (wallets) {
                              final wallet = wallets.cast<Wallet?>().firstWhere(
                                (w) => w?.id == tx.walletId,
                                orElse: () => null,
                              );
                              final catNames = TransactionCategory.getNamesFromId(tx.categoryId, categories);
                              return TransactionTile(
                                tx: tx,
                                mainCategoryName: catNames.$1,
                                subCategoryName: catNames.$2,
                                walletCaption: wallet?.name ?? 'Inconnu',
                                onTap: () {},
                                onDismissed: () {},
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildHeader(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);
    final isOver = status.isOverBudget;
    final color = isOver ? Colors.redAccent : (status.isNearLimit ? Colors.orangeAccent : theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dépensé', style: theme.textTheme.bodySmall),
                  Text(
                    formatAmount(status.spent),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOver ? Colors.redAccent : null,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Budget total', style: theme.textTheme.bodySmall),
                  Text(
                    formatAmount(status.plan.amount),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: status.percentage.clamp(0, 1),
              minHeight: 12,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(status.percentage * 100).toStringAsFixed(1)}% utilisé',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                status.isOverBudget
                    ? 'Dépassement de ${formatAmount(status.spent - status.plan.amount)}'
                    : 'Reste ${formatAmount(status.remaining)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isOver ? Colors.redAccent : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjections(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);
    final proj = status.projection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projections',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProjCard(
                context,
                'Moyenne estimée',
                formatAmount(proj.average),
                Icons.trending_up,
                proj.average > status.plan.amount ? Colors.orangeAccent : Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProjCard(
                context,
                'Date de dépassement',
                proj.estimatedOverrunDate == null
                    ? 'Aucun'
                    : '${proj.estimatedOverrunDate!.day}/${proj.estimatedOverrunDate!.month}',
                Icons.event_busy,
                proj.estimatedOverrunDate == null ? Colors.green : Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(title, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
