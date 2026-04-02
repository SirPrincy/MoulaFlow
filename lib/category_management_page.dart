import 'package:flutter/material.dart';
import 'responsive_layout.dart';
import 'models.dart';
import 'data/category_repository.dart';
import 'utils/styles.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<TransactionCategory> _categories = [];
  final _categoryRepo = CategoryRepository();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryRepo.loadCategories();
    setState(() {
      _categories = cats;
    });
  }

  Future<void> _saveCategories() async {
    await _categoryRepo.saveCategories(_categories);
  }

  void _showAddEditCategoryDialog({TransactionCategory? category, TransactionCategory? parentCategory}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final theme = Theme.of(context);
    final title = category == null 
        ? (parentCategory == null ? 'Nouvelle Catégorie Principale' : 'Nouvelle Sous-Catégorie') 
        : 'Modifier Catégorie';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nom de la catégorie',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
            ),
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (category == null) {
                      // ADD
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
                      // EDIT
                      category.name = name;
                    }
                  });
                  _saveCategories();
                  Navigator.pop(ctx);
                }
              },
              child: Text('Valider', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(TransactionCategory category, {TransactionCategory? parent}) {
    // Blocage si c'est une catégorie principale qui contient des sous-catégories
    if (parent == null && category.subcategories.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de supprimer une catégorie contenant des sous-catégories.'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
          title: Text('Supprimer la catégorie ?', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          content: Text("Les transactions liées à cette rubrique deviendront orphelines (Catégorie inconnue).", style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
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
              child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les Catégories', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter une catégorie principale',
            onPressed: () => _showAddEditCategoryDialog(),
          )
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 800,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          
          return ExpansionTile(
            title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: theme.colorScheme.onSurface)),
            childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
            iconColor: theme.colorScheme.primary,
            collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _showAddEditCategoryDialog(category: cat),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _confirmDelete(cat),
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 24),
              onPressed: () => _showAddEditCategoryDialog(parentCategory: cat),
              color: theme.colorScheme.primary,
            ),
            children: cat.subcategories.map((sub) {
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 64, right: 16),
                title: Text(sub.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showAddEditCategoryDialog(category: sub, parentCategory: cat),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      onPressed: () => _confirmDelete(sub, parent: cat),
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    ),
  );
}
}
