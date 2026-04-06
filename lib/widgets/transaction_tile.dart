import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../models.dart';
import '../utils/styles.dart';

class TransactionTile extends ConsumerWidget {
  final Transaction tx;
  final String mainCategoryName;
  final String? subCategoryName;
  final String walletCaption;
  final bool isDetailed;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.mainCategoryName,
    this.subCategoryName,
    required this.walletCaption,
    required this.onTap,
    required this.onDismissed,
    this.isDetailed = false,
    this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final currencySymbol = ref.watch(currencySymbolProvider);
    final decimalDigits = ref.watch(decimalDigitsProvider);
    String sign = '';
    Color amountColor = theme.colorScheme.onSurface;

    if (tx.type == TransactionType.income) {
      sign = '+';
      amountColor = Colors.green;
    } else if (tx.type == TransactionType.expense) {
      sign = '-';
      amountColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: confirmDismiss,
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          child: const Icon(Icons.delete, color: Colors.red),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.type == TransactionType.transfer 
                                      ? 'Transfert' 
                                      : (subCategoryName ?? mainCategoryName),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subCategoryName != null && tx.type != TransactionType.transfer) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    mainCategoryName,
                                    style: TextStyle(
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.6 : 0.45),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isDetailed && tx.tags.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            ...tx.tags.take(2).map((tag) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.4)),
                              ),
                            )),
                          ],
                        ],
                      ),
                      if (tx.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tx.description,
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.88 : 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year} • $walletCaption',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.74 : 0.5), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${formatAmount(tx.amount, symbol: currencySymbol, decimalDigits: decimalDigits)}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: amountColor, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
