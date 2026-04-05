import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';
import '../widgets/recurring_payment_form.dart';

class RecurringPaymentsPage extends ConsumerStatefulWidget {
  const RecurringPaymentsPage({super.key});

  @override
  ConsumerState<RecurringPaymentsPage> createState() => _RecurringPaymentsPageState();
}

class _RecurringPaymentsPageState extends ConsumerState<RecurringPaymentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecurringPayment> _payments = [];
  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final recurringRepo = ref.read(recurringPaymentRepositoryProvider);
    final walletRepo = ref.read(walletRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    _payments = await recurringRepo.loadRecurringPayments();
    _wallets = await walletRepo.loadWallets();
    _categories = await categoryRepo.loadCategories();
    if (mounted) setState(() {});
  }

  double _calculateMonthlyImpact() {
    double total = 0;
    for (final p in _payments) {
      if (!p.isActive) continue;
      double factor = 0;
      switch (p.frequency) {
        case RecurrenceFrequency.daily: factor = 30; break;
        case RecurrenceFrequency.weekly: factor = 4.33; break;
        case RecurrenceFrequency.monthly: factor = 1; break;
        case RecurrenceFrequency.yearly: factor = 1 / 12; break;
        case RecurrenceFrequency.once: factor = 0; break;
      }
      final signedAmount = p.type == TransactionType.expense ? -p.amount : p.amount;
      total += signedAmount * factor;
    }
    return total;
  }

  void _showForm({RecurringPayment? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.kDefaultRadius * 2)),
        ),
        child: RecurringPaymentForm(
          wallets: _wallets,
          categories: _categories,
          editingPayment: editing,
        ),
      ),
    ).then((result) {
      if (result != null && result is RecurringPayment) {
        _savePayment(result);
      }
    });
  }

  Future<void> _savePayment(RecurringPayment p) async {
    await ref.read(recurringPaymentRepositoryProvider).insertRecurringPayment(p);
    _loadData();
  }

  Future<void> _toggleActive(RecurringPayment p) async {
    final updated = p.copyWith(isActive: !p.isActive);
    await ref.read(recurringPaymentRepositoryProvider).updateRecurringPayment(updated);
    _loadData();
  }

  Future<void> _deletePayment(String id) async {
    await ref.read(recurringPaymentRepositoryProvider).deleteRecurringPayment(id);
    _loadData();
  }

  String _getWalletName(String? id) {
    if (id == null) return 'Aucun';
    final w = _wallets.firstWhere((element) => element.id == id, orElse: () => Wallet(id: '?', name: 'Wallet inconnu'));
    return w.name;
  }

  String _getCategoryName(String? id) {
    if (id == null) return 'Autre';
    for (var mainCat in _categories) {
      if (mainCat.id == id) return mainCat.name;
      for (var subCat in mainCat.subcategories) {
        if (subCat.id == id) return subCat.name;
      }
    }
    return 'Autre';
  }

  @override
  Widget build(BuildContext context) {
    final monthlyImpact = _calculateMonthlyImpact();
    final active = _payments.where((p) => p.isActive).toList();
    final inactive = _payments.where((p) => !p.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Flow', style: TextStyle(fontWeight: FontWeight.w900)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Abonnements'),
            Tab(text: 'Historique/Archives'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveList(context, active, monthlyImpact),
          _buildInactiveList(context, inactive),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildActiveList(BuildContext context, List<RecurringPayment> active, double impact) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildImpactCard(context, impact),
          const SizedBox(height: 24),
          if (active.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text('Aucun abonnement actif.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            )
          else
            ...active.map((p) => _buildPaymentTile(context, p)),
        ],
      ),
    );
  }

  Widget _buildImpactCard(BuildContext context, double impact) {
    final theme = Theme.of(context);
    final isNegative = impact < 0;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative 
            ? [
                isDark ? theme.colorScheme.errorContainer.withValues(alpha: 0.3) : theme.colorScheme.errorContainer,
                isDark ? theme.colorScheme.errorContainer.withValues(alpha: 0.1) : theme.colorScheme.errorContainer.withValues(alpha: 0.7),
              ]
            : [
                isDark ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : theme.colorScheme.primaryContainer,
                isDark ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: (isNegative ? Colors.red : Colors.blue).withValues(alpha: 0.15)) : null,
        boxShadow: [
          BoxShadow(
            color: (isNegative ? Colors.red : Colors.blue).withValues(alpha: isDark ? 0.05 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impact mensuel estimé',
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600,
              color: isNegative ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatAmount(impact),
            style: TextStyle(
              fontSize: 32, 
              fontWeight: FontWeight.w900,
              color: isNegative ? theme.colorScheme.error : theme.colorScheme.primary,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isNegative ? Icons.trending_down : Icons.trending_up, 
                size: 16, 
                color: isNegative ? theme.colorScheme.error : theme.colorScheme.primary
              ),
              const SizedBox(width: 6),
              Text(
                isNegative ? 'Sortie nette par mois' : 'Entrée nette par mois',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: (isNegative ? theme.colorScheme.error : theme.colorScheme.primary).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(BuildContext context, RecurringPayment p) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => _showForm(editing: p),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      p.type == TransactionType.expense ? Icons.remove_circle_outline : Icons.add_circle_outline,
                      color: p.type == TransactionType.expense ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        if (p.description.isNotEmpty)
                          Text(p.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                  Text(
                    formatAmount(p.type == TransactionType.expense ? -p.amount : p.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: p.type == TransactionType.expense ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildSubTag(context, Icons.calendar_today_rounded, p.frequency.name.toUpperCase()),
                  const SizedBox(width: 8),
                  _buildSubTag(context, Icons.account_balance_wallet_outlined, _getWalletName(p.walletId)),
                  const SizedBox(width: 8),
                  _buildSubTag(context, Icons.category_outlined, _getCategoryName(p.categoryId)),
                  const Spacer(),
                  if (p.executionMode == RecurringExecutionMode.auto)
                    Icon(Icons.bolt, size: 16, color: Colors.amber[700]),
                ],
              ),
              const SizedBox(height: 12),
              if (p.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: p.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleActive(p),
                    icon: Icon(p.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                    label: Text(p.isActive ? 'Mettre en pause' : 'Réactiver'),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showDeleteDialog(p),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubTag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildInactiveList(BuildContext context, List<RecurringPayment> inactive) {
    final theme = Theme.of(context);
    if (inactive.isEmpty) {
      return Center(child: Text('Aucun paiement archivé.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: inactive.length,
      itemBuilder: (context, index) => Opacity(
        opacity: 0.6,
        child: _buildPaymentTile(context, inactive[index]),
      ),
    );
  }

  void _showDeleteDialog(RecurringPayment p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'abonnement ?'),
        content: Text('Voulez-vous vraiment supprimer "${p.name}" ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              _deletePayment(p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
