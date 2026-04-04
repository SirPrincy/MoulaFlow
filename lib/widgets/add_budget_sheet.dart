import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers.dart';

class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({super.key});

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
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
    _refreshDates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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

    final plan = BudgetPlan(
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

    await ref.read(budgetRepositoryProvider).insertBudget(plan);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget ajouté avec succès')),
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
                'Nouveau Budget',
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
                decoration: const InputDecoration(
                  labelText: 'Période',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: BudgetPeriodType.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _periodType = v;
                    _refreshDates();
                  });
                },
              ),
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
                  data: (categories) => Wrap(
                    spacing: 8,
                    children: categories
                        .map((c) => FilterChip(
                              label: Text(c.name),
                              selected: _selectedCategoryIds.contains(c.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategoryIds.add(c.id);
                                  } else {
                                    _selectedCategoryIds.remove(c.id);
                                  }
                                });
                              },
                            ))
                        .toList(),
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
                  child: const Text('Créer le budget'),
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
