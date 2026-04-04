import 'dart:math' as math;
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
      loading: () => _buildSkeleton(context),
      error: (e, s) => _buildError(context, e),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError(BuildContext context, Object e) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.redAccent.withValues(alpha: 0.08),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(child: Text('Erreur de chargement', style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);

    Color accentColor;
    if (status.isOverBudget) {
      accentColor = Colors.redAccent;
    } else if (status.isNearLimit) {
      accentColor = Colors.orangeAccent;
    } else {
      accentColor = theme.colorScheme.primary;
    }

    final daysLeft = status.plan.endDate.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final formattedDays = isExpired
        ? 'Terminé'
        : daysLeft == 0
            ? 'Dernier jour !'
            : '$daysLeft j restants';

    final pct = status.percentage;
    final pctText = pct >= 10 ? '${(pct * 100).toStringAsFixed(0)}%' : '${(pct * 100).toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          border: Border.all(
            color: status.isOverBudget
                ? Colors.redAccent.withValues(alpha: 0.4)
                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: status.isOverBudget ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top gradient accent bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: name + circular gauge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.plan.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    isExpired
                                        ? Icons.event_busy_rounded
                                        : Icons.schedule_rounded,
                                    size: 12,
                                    color: isExpired
                                        ? Colors.redAccent
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDays,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isExpired
                                          ? Colors.redAccent
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (status.isOverBudget) ...[ 
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Dépassé',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ] else if (status.isNearLimit) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Presque atteint',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Circular percentage gauge
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CustomPaint(
                            painter: _CircularGaugePainter(
                              value: pct.clamp(0, 1),
                              color: accentColor,
                              backgroundColor: accentColor.withValues(alpha: 0.1),
                            ),
                            child: Center(
                              child: Text(
                                pctText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stat row: spent vs budget
                    Row(
                      children: [
                        Expanded(
                          child: _buildStat(
                            context,
                            label: 'Dépensé',
                            value: formatAmount(status.spent),
                            color: accentColor,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStat(
                            context,
                            label: status.isOverBudget ? 'Dépassement' : 'Restant',
                            value: status.isOverBudget
                                ? formatAmount(status.spent - status.plan.amount)
                                : formatAmount(status.remaining),
                            color: status.isOverBudget
                                ? Colors.redAccent
                                : theme.colorScheme.onSurfaceVariant,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStat(
                            context,
                            label: 'Budget',
                            value: formatAmount(status.plan.amount),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            theme: theme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color backgroundColor;

  _CircularGaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter old) =>
      old.value != value || old.color != color;
}
