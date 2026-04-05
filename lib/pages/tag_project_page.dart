import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';
import '../utils/app_icons.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/tag_edit_dialog.dart';

class TagProjectPage extends ConsumerStatefulWidget {
  final TagDefinition tag;

  const TagProjectPage({super.key, required this.tag});

  @override
  ConsumerState<TagProjectPage> createState() => _TagProjectPageState();
}

class _TagProjectPageState extends ConsumerState<TagProjectPage> {
  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    // Watch for tag updates or deletion
    final currentTag = tagsAsync.when(
      data: (tags) {
        final found = tags.cast<TagDefinition?>().firstWhere(
          (t) => t?.id == widget.tag.id,
          orElse: () => null,
        );
        if (found == null) {
          // Tag was deleted, pop page after build
          Future.microtask(() {
            if (context.mounted) Navigator.of(context).pop();
          });
          return widget.tag; // Return old tag for this build
        }
        return found;
      },
      loading: () => widget.tag,
      error: (_, _) => widget.tag,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          currentTag.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              TagEditDialog.show(context, tag: currentTag);
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (allTransactions) {
          final projectTransactions = allTransactions
              .where((tx) => tx.tags.contains(currentTag.name))
              .toList();
          final categories = ref.watch(categoriesProvider).value ?? [];
          final wallets = ref.watch(walletsProvider).value ?? [];

          String getCatName(String? id) {
            if (id == null) return 'Divers';
            for (var mainCat in categories) {
              if (mainCat.id == id) return mainCat.name;
              for (var subCat in mainCat.subcategories) {
                if (subCat.id == id) return subCat.name;
              }
            }
            return 'Inconnu';
          }

          String getWalletName(String? id) {
            if (id == null) return 'Inconnu';
            try {
              return wallets.firstWhere((w) => w.id == id).name;
            } catch (_) {
              return 'Inconnu';
            }
          }

          double totalSpent = 0;
          for (var tx in projectTransactions) {
            if (tx.type == TransactionType.expense) totalSpent += tx.amount;
            if (tx.type == TransactionType.income) totalSpent -= tx.amount;
          }

          final limit = currentTag.goalAmount ?? 0;
          final progress = limit > 0
              ? (totalSpent / limit).clamp(0.0, 1.0)
              : 0.0;
          final isOverBudget = limit > 0 && totalSpent > limit;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(
                        theme,
                        currentTag,
                        totalSpent,
                        limit,
                        progress,
                        isOverBudget,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TRANSACTIONS LIÉES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${projectTransactions.length} OPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (projectTransactions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Aucune transaction pour ce projet.'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tx = projectTransactions[index];
                    return TransactionTile(
                      tx: tx,
                      categoryName: getCatName(tx.categoryId),
                      walletCaption: getWalletName(
                        tx.walletId ?? tx.fromWalletId,
                      ),
                      onTap: () {
                        // TODO: Edit transaction logic if needed
                      },
                      onDismissed: () {
                        // Handle dismissal
                      },
                    );
                  }, childCount: projectTransactions.length),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    ThemeData theme,
    TagDefinition tag,
    double spent,
    double limit,
    double progress,
    bool isOverBudget,
  ) {
    final color = tag.color != null
        ? Color(int.parse(tag.color!.replaceAll('#', '0xFF')))
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOverBudget
            ? Colors.red.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius * 1.5),
        border: Border.all(
          color: isOverBudget
              ? Colors.red.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverBudget ? Colors.red : color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tag.icon != null
                      ? AppIcons.getIconFromStr(tag.icon!)
                      : Icons.rocket_launch,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coût Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatAmount(spent),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (limit > 0) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget: ${formatAmount(limit)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget ? Colors.red : color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isOverBudget
                    ? Colors.red.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(
                  isOverBudget ? Colors.red : color,
                ),
              ),
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 12),
              Text(
                'Attention: Budget dépassé de ${formatAmount(spent - limit)}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            Text(
              'Aucun budget défini pour ce projet.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
