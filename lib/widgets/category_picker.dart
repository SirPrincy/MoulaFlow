import 'package:flutter/material.dart';
import '../models.dart';
import '../responsive_layout.dart';
import '../utils/styles.dart';

class CategoryPickerModal extends StatefulWidget {
  final List<TransactionCategory> categories;
  final TransactionType transactionType;

  const CategoryPickerModal({
    super.key, 
    required this.categories,
    required this.transactionType,
  });

  @override
  State<CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends State<CategoryPickerModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    List<TransactionCategory> sortedCategories = List.from(widget.categories);
    
    // Sort categories based on transaction type
    final revenusIndex = sortedCategories.indexWhere((c) => c.id == 'cat_revenus');
    if (revenusIndex != -1) {
      final revenus = sortedCategories.removeAt(revenusIndex);
      if (widget.transactionType == TransactionType.income) {
        sortedCategories.insert(0, revenus);
      } else {
        sortedCategories.add(revenus);
      }
    }

    Widget _buildCategoryList() {
      if (_searchQuery.isEmpty) {
        return ListView.builder(
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final cat = sortedCategories[index];
            if (cat.subcategories.isEmpty) {
              return ListTile(
                title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                onTap: () => Navigator.pop(context, cat.id),
              );
            }
            return ExpansionTile(
              title: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              iconColor: theme.colorScheme.onSurface,
              collapsedIconColor: theme.colorScheme.onSurface,
              children: cat.subcategories.map((sub) {
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 16),
                  title: Text(sub.name, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                  onTap: () => Navigator.pop(context, sub.id),
                );
              }).toList(),
            );
          },
        );
      } else {
        final q = _searchQuery.toLowerCase();
        final List<(TransactionCategory, TransactionCategory?)> flatResults = [];
        
        for (var mainCat in sortedCategories) {
          if (mainCat.name.toLowerCase().contains(q)) {
            flatResults.add((mainCat, null));
          }
          for (var subCat in mainCat.subcategories) {
            if (subCat.name.toLowerCase().contains(q)) {
              flatResults.add((mainCat, subCat));
            }
          }
        }

        return ListView.builder(
          itemCount: flatResults.length,
          itemBuilder: (context, index) {
            final (main, sub) = flatResults[index];
            final isSub = sub != null;
            
            return ListTile(
              title: Text(
                isSub ? sub.name : main.name, 
                style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)
              ),
              subtitle: isSub ? Text(main.name, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))) : null,
              onTap: () => Navigator.pop(context, isSub ? sub.id : main.id),
              trailing: isSub ? null : Icon(Icons.folder_open, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            );
          },
        );
      }
    }

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: ResponsiveCenter(
        maxWidth: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Sélectionner une Catégorie', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildCategoryList(),
            ),
          ],
        ),
      ),
    );
  }
}
