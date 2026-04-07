import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  final BudgetPlan? editingBudget;

  const AddBudgetSheet({super.key, this.editingBudget});

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  String _getPeriodName(BudgetPeriodType type) {
    switch (type) {
      case BudgetPeriodType.daily: return 'Quotidien';
      case BudgetPeriodType.weekly: return 'Hebdomadaire';
      case BudgetPeriodType.monthly: return 'Mensuel';
      case BudgetPeriodType.custom: return 'Personnalisé';
    }
  }
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  BudgetPeriodType _periodType = BudgetPeriodType.monthly;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  final Set<String> _selectedWalletIds = {};
  final Set<String> _selectedCategoryIds = {};
  bool _includeAllCategories = true;

  @override
  void initState() {
    super.initState();
    final editing = widget.editingBudget;
    if (editing != null) {
      _nameController.text = editing.name;
      _amountController.text = editing.amount.toStringAsFixed(2);
      _periodType = editing.periodType;
      _startDate = editing.startDate;
      _endDate = editing.endDate;
      _selectedWalletIds.addAll(editing.walletIds);
      _selectedCategoryIds.addAll(editing.categoryIds);
      _includeAllCategories = editing.includeAllCategories;
    } else {
      _refreshDates();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _showCategoriesDialog(List<TransactionCategory> categories) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Catégories incluses'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: categories.map((c) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          leading: Checkbox(
                            value: _selectedCategoryIds.contains(c.id),
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  _selectedCategoryIds.add(c.id);
                                  if (c.subcategories.isNotEmpty) {
                                    for (var sub in c.subcategories) {
                                      _selectedCategoryIds.add(sub.id);
                                    }
                                  }
                                } else {
                                  _selectedCategoryIds.remove(c.id);
                                  if (c.subcategories.isNotEmpty) {
                                    for (var sub in c.subcategories) {
                                      _selectedCategoryIds.remove(sub.id);
                                    }
                                  }
                                }
                              });
                            },
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          children: [
                            if (c.subcategories.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: c.subcategories.map((subC) {
                                      return FilterChip(
                                        label: Text(subC.name, style: const TextStyle(fontSize: 12)),
                                        selected: _selectedCategoryIds.contains(subC.id),
                                        onSelected: (val) {
                                          setDialogState(() {
                                            if (val) {
                                              _selectedCategoryIds.add(subC.id);
                                              _selectedCategoryIds.add(c.id); // Also select parent
                                            } else {
                                              _selectedCategoryIds.remove(subC.id);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
    // Refresh the sheet's state to update the category count text
    setState(() {});
  }

  void _refreshDates() {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;

    final editing = widget.editingBudget;
    final plan = editing?.copyWith(
          name: _nameController.text.trim(),
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
          walletIds: _selectedWalletIds.toList(),
          categoryIds: _includeAllCategories ? [] : _selectedCategoryIds.toList(),
          includeAllCategories: _includeAllCategories,
          amount: amount,
        ) ??
        BudgetPlan(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
          walletIds: _selectedWalletIds.toList(),
          categoryIds: _includeAllCategories ? [] : _selectedCategoryIds.toList(),
          includeAllCategories: _includeAllCategories,
          amount: amount,
          createdAt: DateTime.now(),
        );

    if (editing != null) {
      await ref.read(budgetRepositoryProvider).updateBudget(plan);
    } else {
      await ref.read(budgetRepositoryProvider).insertBudget(plan);
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editing != null
              ? 'Budget modifié avec succès'
              : 'Budget ajouté avec succès',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.editingBudget != null ? 'Modifier le budget' : 'Nouveau Budget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du budget',
                  hintText: 'ex: Alimentation, Vacances...',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant maximum',
                  hintText: '0,00',
                  prefixIcon: Icon(Icons.euro_symbol),
                ),
                validator: (v) {
                  final amount = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (amount == null || amount <= 0) return 'Montant invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BudgetPeriodType>(
                initialValue: _periodType,
                isExpanded: true,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: 'Période',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: BudgetPeriodType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _getPeriodName(e),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _periodType = v;
                    _refreshDates();
                  });
                },
              ),
              if (_periodType == BudgetPeriodType.custom) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Plage de dates (Personnalisée)',
                      prefixIcon: Icon(Icons.date_range),
                    ),
                    child: Text(
                      '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year} au '
                      '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Du ${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year} au '
                    '${_endDate.day.toString().padLeft(2, '0')}/${_endDate.month.toString().padLeft(2, '0')}/${_endDate.year}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Wallets inclus',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              walletsAsync.when(
                data: (wallets) => Wrap(
                  spacing: 8,
                  children: wallets
                      .map((w) => FilterChip(
                            label: Text(w.name),
                            selected: _selectedWalletIds.contains(w.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedWalletIds.add(w.id);
                                } else {
                                  _selectedWalletIds.remove(w.id);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text('Erreur: $e'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Toutes les catégories'),
                subtitle: const Text('Prise en compte de toutes les dépenses'),
                value: _includeAllCategories,
                onChanged: (v) => setState(() => _includeAllCategories = v),
              ),
              if (!_includeAllCategories) ...[
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sélectionner des catégories'),
                    subtitle: Text('${_selectedCategoryIds.length} catégorie(s) sélectionnée(s)'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showCategoriesDialog(categories),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Erreur: $e'),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.editingBudget != null
                        ? 'Enregistrer les modifications'
                        : 'Créer le budget',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
