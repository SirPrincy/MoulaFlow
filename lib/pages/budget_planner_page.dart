import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../domain/budget_planning_service.dart';
import '../models.dart';
import '../responsive_layout.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/app_side_menu.dart';

class BudgetPlannerPage extends ConsumerStatefulWidget {
  const BudgetPlannerPage({super.key});

  @override
  ConsumerState<BudgetPlannerPage> createState() => _BudgetPlannerPageState();
}

class _BudgetPlannerPageState extends ConsumerState<BudgetPlannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = BudgetPlanningService();

  List<Wallet> _wallets = [];
  List<TransactionCategory> _categories = [];
  List<Transaction> _transactions = [];
  List<BudgetPlan> _budgets = [];

  final _nameController = TextEditingController(text: 'Budget principal');
  final _tagsController = TextEditingController();
  final _amountController = TextEditingController();
  final _dependencyPercentController = TextEditingController(text: '30');
  final _repeatAdjustController = TextEditingController(text: '0');

  BudgetPeriodType _periodType = BudgetPeriodType.monthly;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  final Set<String> _selectedWalletIds = {};
  final Set<String> _selectedCategoryIds = {};
  bool _includeAllCategories = true;
  bool _enableAlerts = true;
  bool _enableProgressive = false;
  bool _enableDependency = false;
  String? _dependencyBudgetId;
  BudgetRepeatFrequency _repeatFrequency = BudgetRepeatFrequency.none;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    _amountController.dispose();
    _dependencyPercentController.dispose();
    _repeatAdjustController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _wallets = await ref.read(walletRepositoryProvider).loadWallets();
    _categories = await ref.read(categoryRepositoryProvider).loadCategories();
    _transactions = await ref.read(transactionRepositoryProvider).loadTransactions();
    _budgets = await ref.read(budgetRepositoryProvider).loadBudgets();
    if (mounted) setState(() {});
  }

  List<TransactionCategory> get _flatCategories {
    final res = <TransactionCategory>[];
    for (final cat in _categories) {
      res.add(cat);
      res.addAll(cat.subcategories);
    }
    return res;
  }

  Set<String> get _parsedTags => _tagsController.text
      .split(';')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toSet();

  void _refreshPeriod() {
    final now = DateTime.now();
    setState(() {
      switch (_periodType) {
        case BudgetPeriodType.daily:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = _startDate;
          break;
        case BudgetPeriodType.weekly:
          final first = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(first.year, first.month, first.day);
          _endDate = _startDate.add(const Duration(days: 6));
          break;
        case BudgetPeriodType.monthly:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case BudgetPeriodType.custom:
          break;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime(2020) : _startDate;
    final selected = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = selected;
      }
    });
  }

  BudgetProjection _projection(double amount) {
    final effectiveEnd = _endDate.isBefore(DateTime.now()) ? _endDate : DateTime.now();
    final filtered = _service.filterTransactions(
      transactions: _transactions,
      start: _startDate,
      end: effectiveEnd,
      walletIds: _selectedWalletIds,
      categoryIds: _includeAllCategories ? {} : _selectedCategoryIds,
      tags: _parsedTags,
    );
    final spent = _service.computeSpent(filtered);
    return _service.projectBudget(
      spent: spent,
      totalBudget: amount,
      start: _startDate,
      end: _endDate,
      now: DateTime.now(),
    );
  }

  double _spentNow() {
    final effectiveEnd = _endDate.isBefore(DateTime.now()) ? _endDate : DateTime.now();
    final filtered = _service.filterTransactions(
      transactions: _transactions,
      start: _startDate,
      end: effectiveEnd,
      walletIds: _selectedWalletIds,
      categoryIds: _includeAllCategories ? {} : _selectedCategoryIds,
      tags: _parsedTags,
    );
    return _service.computeSpent(filtered);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez au moins un wallet.')));
      return;
    }
    if (!_includeAllCategories && _selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez au moins une catégorie.')));
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    if (_enableDependency && _dependencyBudgetId != null) {
      final parent = _budgets.firstWhere((b) => b.id == _dependencyBudgetId);
      final pct = double.tryParse(_dependencyPercentController.text.replaceAll(',', '.')) ?? 0;
      if (!_service.respectsDependency(amount: amount, parentBudget: parent, limitPercent: pct)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dépendance invalide: max ${formatAmount(parent.amount * pct / 100)}')),
        );
        return;
      }
    }

    final projection = _projection(amount);
    final spent = _spentNow();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validation finale'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nom: ${_nameController.text.trim()}'),
              Text('Période: ${_startDate.day}/${_startDate.month}/${_startDate.year} → ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
              Text('Wallets: ${_selectedWalletIds.length}'),
              Text('Catégories: ${_includeAllCategories ? 'Toutes' : _selectedCategoryIds.length.toString()}'),
              Text('Tags: ${_parsedTags.isEmpty ? 'Aucun' : _parsedTags.join(', ')}'),
              Text('Montant: ${formatAmount(amount)}'),
              Text('Alertes: ${_enableAlerts ? 'Activées' : 'Désactivées'}'),
              Text('Budget progressif: ${_enableProgressive ? 'Oui' : 'Non'}'),
              Text('Interdépendance: ${_enableDependency ? 'Oui' : 'Non'}'),
              Text('Répétition: ${_repeatFrequency.name}'),
              const Divider(),
              Text('Dépensé actuellement: ${formatAmount(spent)}'),
              Text('Projection moyenne: ${formatAmount(projection.average)}'),
              Text('Projection optimiste: ${formatAmount(projection.optimistic)}'),
              Text('Projection pessimiste: ${formatAmount(projection.pessimistic)}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm != true) return;

    final plan = BudgetPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      periodType: _periodType,
      startDate: _startDate,
      endDate: _endDate,
      walletIds: _selectedWalletIds.toList(),
      categoryIds: _selectedCategoryIds.toList(),
      includeAllCategories: _includeAllCategories,
      tags: _parsedTags.toList(),
      amount: amount,
      enableAlerts: _enableAlerts,
      enableProgressiveAdjustment: _enableProgressive,
      dependencyBudgetId: _enableDependency ? _dependencyBudgetId : null,
      dependencyPercentLimit: _enableDependency
          ? double.tryParse(_dependencyPercentController.text.replaceAll(',', '.'))
          : null,
      repeatFrequency: _repeatFrequency,
      repeatAdjustmentPercent: double.tryParse(_repeatAdjustController.text.replaceAll(',', '.')) ?? 0,
    );

    _budgets.insert(0, plan);
    await ref.read(budgetRepositoryProvider).saveBudgets(_budgets);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget créé avec succès.')));
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final spent = _spentNow();
    final projection = _projection(amount);
    final totalUnits = _periodType == BudgetPeriodType.daily ? 1 : (_periodType == BudgetPeriodType.weekly ? 7 : (_endDate.difference(_startDate).inDays + 1));
    final elapsedUnits = DateTime.now().isBefore(_startDate) ? 0 : DateTime.now().difference(_startDate).inDays + 1;
    final suggested = _service.suggestedNextUnitBudget(
      totalBudget: amount,
      spent: spent,
      elapsedUnits: elapsedUnits,
      totalUnits: totalUnits,
    );

    Widget content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom du budget'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BudgetPeriodType>(
            initialValue: _periodType,
            items: BudgetPeriodType.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              _periodType = v;
              _refreshPeriod();
            },
            decoration: const InputDecoration(labelText: 'Période du budget'),
          ),
          if (_periodType == BudgetPeriodType.custom) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              OutlinedButton.icon(onPressed: () => _pickDate(isStart: true), icon: const Icon(Icons.calendar_today), label: Text('Début ${_startDate.day}/${_startDate.month}/${_startDate.year}')),
              OutlinedButton.icon(onPressed: () => _pickDate(isStart: false), icon: const Icon(Icons.calendar_today), label: Text('Fin ${_endDate.day}/${_endDate.month}/${_endDate.year}')),
            ]),
          ],
          const SizedBox(height: 16),
          const Text('Wallets'),
          Wrap(
            spacing: 8,
            children: _wallets
                .map((w) => FilterChip(
                      label: Text(w.name),
                      selected: _selectedWalletIds.contains(w.id),
                      onSelected: (v) => setState(() => v ? _selectedWalletIds.add(w.id) : _selectedWalletIds.remove(w.id)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _includeAllCategories,
            onChanged: (v) => setState(() => _includeAllCategories = v),
            title: const Text('Inclure toutes les catégories'),
          ),
          if (!_includeAllCategories)
            Wrap(
              spacing: 8,
              children: _flatCategories
                  .map((c) => FilterChip(
                        label: Text(c.name),
                        selected: _selectedCategoryIds.contains(c.id),
                        onSelected: (v) => setState(() => v ? _selectedCategoryIds.add(c.id) : _selectedCategoryIds.remove(c.id)),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: 'Tags (séparés par ;)'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Montant du budget'),
            validator: (v) {
              final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) return 'Montant invalide';
              return null;
            },
          ),
          SwitchListTile(
            value: _enableAlerts,
            onChanged: (v) => setState(() => _enableAlerts = v),
            title: const Text('Alertes intelligentes'),
            subtitle: const Text('Notification quand une limite est atteinte'),
          ),
          SwitchListTile(
            value: _enableProgressive,
            onChanged: (v) => setState(() => _enableProgressive = v),
            title: const Text('Budget progressif'),
            subtitle: Text('Suggestion prochain palier: ${formatAmount(suggested)}'),
          ),
          if (_enableProgressive)
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights),
                title: const Text('Ajustement proposé'),
                subtitle: Text('Dépensé: ${formatAmount(spent)} • Prochain palier conseillé: ${formatAmount(suggested)}'),
              ),
            ),
          SwitchListTile(
            value: _enableDependency,
            onChanged: (v) => setState(() => _enableDependency = v),
            title: const Text('Budgets interdépendants'),
          ),
          if (_enableDependency) ...[
            DropdownButtonFormField<String>(
              initialValue: _dependencyBudgetId,
              items: _budgets
                  .map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${formatAmount(b.amount)})')))
                  .toList(),
              onChanged: (v) => setState(() => _dependencyBudgetId = v),
              decoration: const InputDecoration(labelText: 'Budget parent'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dependencyPercentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Pourcentage max autorisé'),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<BudgetRepeatFrequency>(
            initialValue: _repeatFrequency,
            items: BudgetRepeatFrequency.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => _repeatFrequency = v ?? BudgetRepeatFrequency.none),
            decoration: const InputDecoration(labelText: 'Répétition automatique'),
          ),
          if (_repeatFrequency != BudgetRepeatFrequency.none)
            TextFormField(
              controller: _repeatAdjustController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Ajustement par répétition (%)'),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Simulation / projection', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Moyenne: ${formatAmount(projection.average)}'),
                  Text('Optimiste: ${formatAmount(projection.optimistic)}'),
                  Text('Pessimiste: ${formatAmount(projection.pessimistic)}'),
                  Text('Dépassement estimé: ${projection.estimatedOverrunDate == null ? 'Aucun' : '${projection.estimatedOverrunDate!.day}/${projection.estimatedOverrunDate!.month}/${projection.estimatedOverrunDate!.year}'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmer la création du budget'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );

    final sideMenu = AppSideMenu(
      currentRoute: '/budgets',
      isCollapsed: false,
      onDataChange: _load,
    );

    if (context.isMobileScreen) {
      return Scaffold(
        appBar: const AppMenuBar(title: 'Budgets'),
        drawer: Drawer(child: sideMenu),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 280, child: sideMenu),
          Expanded(
            child: Scaffold(
              appBar: const AppMenuBar(title: 'Budgets'),
              body: ResponsiveCenter(maxWidth: 950, child: content),
            ),
          ),
        ],
      ),
    );
  }
}
