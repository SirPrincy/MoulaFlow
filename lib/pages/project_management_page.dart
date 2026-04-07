import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';
import '../utils/app_icons.dart';
import '../widgets/tag_edit_dialog.dart';
import 'tag_project_page.dart';

class ProjectManagementPage extends ConsumerStatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  ConsumerState<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends ConsumerState<ProjectManagementPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: AppStyles.kInputDecoration(context, 'Rechercher...').copyWith(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      }
                    ) 
                  : null,
              ),
            ),
          ),
          Expanded(
            child: tagsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Erreur: $err')),
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_off_outlined, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text('Aucun tag défini.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Créez-en un pour organiser vos transactions.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  );
                }

                final filteredTags = tags.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
                
                filteredTags.sort((a, b) => a.name.compareTo(b.name));

                return transactionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Erreur: $err')),
                  data: (transactions) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: filteredTags.length,
                      itemBuilder: (context, index) {
                        final tag = filteredTags[index];
                        
                        // Calculate spent for this tag
                        double spent = 0;
                        final tagTxs = transactions.where((tx) => tx.tags.contains(tag.name));
                        for (var tx in tagTxs) {
                          if (tx.type == TransactionType.expense) spent += tx.amount;
                          if (tx.type == TransactionType.income) spent -= tx.amount;
                        }

                        return _TagListItem(
                          tag: tag, 
                          spent: spent, 
                          isProject: false,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => TagProjectPage(tag: tag)));
                          },
                          onEdit: () {
                            TagEditDialog.show(context, tag: tag);
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TagEditDialog.show(context),
        label: const Text('AJOUTER', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}

class _TagListItem extends StatelessWidget {
  final TagDefinition tag;
  final double spent;
  final bool isProject;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _TagListItem({
    required this.tag,
    required this.spent,
    required this.isProject,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tag.color != null ? Color(int.parse(tag.color!.replaceAll('#', '0xFF'))) : theme.colorScheme.primary;
    final limit = tag.goalAmount ?? 0;
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = limit > 0 && spent > limit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tag.icon != null ? AppIcons.getIconFromStr(tag.icon!) : (isProject ? Icons.rocket_launch : Icons.local_offer),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          isProject ? 'Projet' : 'Tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatAmount(spent),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isOverBudget ? Colors.red : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ],
              ),
              if (isProject && limit > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: ${formatAmount(limit)}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(isOverBudget ? Colors.red : color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
