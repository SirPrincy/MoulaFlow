import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart';
import 'models.dart';
import 'responsive_layout.dart';
import 'utils/styles.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends ConsumerState<CategoryManagementPage> {
  List<TransactionCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await ref.read(categoryRepositoryProvider).loadCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
      });
    }
  }

  Future<void> _saveCategories() async {
    await ref.read(categoryRepositoryProvider).saveCategories(_categories);
  }

  void _showAddEditCategoryDialog({
    TransactionCategory? category,
    TransactionCategory? parentCategory,
  }) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final theme = Theme.of(context);
    final title = category == null
        ? (parentCategory == null
            ? 'Nouvelle catégorie principale'
            : 'Nouvelle sous-catégorie')
        : 'Modifier la catégorie';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom de la catégorie',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
              ),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }

                setState(() {
                  if (category == null) {
                    final newCat = TransactionCategory(
                      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                    );
                    if (parentCategory == null) {
                      _categories.add(newCat);
                    } else {
                      parentCategory.subcategories.add(newCat);
                    }
                  } else {
                    category.name = name;
                  }
                });

                _saveCategories();
                Navigator.pop(ctx);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(TransactionCategory category, {TransactionCategory? parent}) {
    if (parent == null && category.subcategories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Impossible de supprimer une catégorie contenant des sous-catégories.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          title: Text(
            'Supprimer la catégorie ?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Les transactions liées à cette rubrique deviendront orphelines (Catégorie inconnue).',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (parent == null) {
                    _categories.removeWhere((c) => c.id == category.id);
                  } else {
                    parent.subcategories.removeWhere((c) => c.id == category.id);
                  }
                });
                _saveCategories();
                Navigator.pop(ctx);
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubcategoryTile(
    TransactionCategory sub,
    TransactionCategory parent,
    ThemeData theme,
  ) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 8, right: 4),
      leading: Icon(
        Icons.subdirectory_arrow_right_rounded,
        size: 18,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        sub.name,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () =>
                _showAddEditCategoryDialog(category: sub, parentCategory: parent),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.withValues(alpha: 0.85),
            onPressed: () => _confirmDelete(sub, parent: parent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gérer les catégories',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une catégorie principale',
            onPressed: () => _showAddEditCategoryDialog(),
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 860,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _categories.isEmpty
              ? Center(
                  key: const ValueKey('empty-categories'),
                  child: Text(
                    'Aucune catégorie disponible.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView(
                  key: const ValueKey('categories-list'),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  children: [
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.kDefaultRadius + 6),
                        side: BorderSide(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ExpansionPanelList.radio(
                        expandedHeaderPadding: EdgeInsets.zero,
                        elevation: 0,
                        animationDuration: const Duration(milliseconds: 240),
                        children: _categories.map((cat) {
                          return ExpansionPanelRadio(
                            value: cat.id,
                            canTapOnHeader: true,
                            headerBuilder: (context, isExpanded) {
                              return ListTile(
                                title: Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cat.subcategories.length} sous-catégorie(s)',
                                ),
                                trailing: Wrap(
                                  spacing: 2,
                                  children: [
                                    IconButton(
                                      tooltip: 'Ajouter une sous-catégorie',
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _showAddEditCategoryDialog(
                                        parentCategory: cat,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Modifier',
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          _showAddEditCategoryDialog(category: cat),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                      ),
                                      color: Colors.red.withValues(alpha: 0.85),
                                      onPressed: () => _confirmDelete(cat),
                                    ),
                                  ],
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                children: [
                                  if (cat.subcategories.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Pas encore de sous-catégorie.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    )
                                  else
                                    ...cat.subcategories.map(
                                      (sub) =>
                                          _buildSubcategoryTile(sub, cat, theme),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
