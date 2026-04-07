import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Projets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text('Aucun projet séparé pour le moment.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              final target = project.targetAmount;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Text(project.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Objectif: ${formatAmount(target)}'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await ref.read(projectRepositoryProvider).deleteProject(project.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('NOUVEAU PROJET'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final walletCtrl = TextEditingController(text: 'project-wallet');
    final itemNameCtrl = TextEditingController();
    final itemPriceCtrl = TextEditingController();
    final items = <ProjectItem>[];
    String icon = '🚀';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Créer un projet séparé'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Nom du projet')),
                    TextField(controller: walletCtrl, decoration: const InputDecoration(labelText: 'Wallet lié (id)')),
                    TextField(
                      decoration: InputDecoration(labelText: 'Emoji projet (actuel: $icon)'),
                      onChanged: (v) {
                        if (v.isNotEmpty) icon = v;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: itemNameCtrl, decoration: const InputDecoration(labelText: 'Article')),
                    TextField(
                      controller: itemPriceCtrl,
                      decoration: const InputDecoration(labelText: 'Prix'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter article'),
                        onPressed: () {
                          final name = itemNameCtrl.text.trim();
                          final price = double.tryParse(itemPriceCtrl.text.trim());
                          if (name.isEmpty || price == null) return;
                          setLocalState(() {
                            items.add(
                              ProjectItem(
                                id: DateTime.now().microsecondsSinceEpoch.toString(),
                                name: name,
                                price: price,
                              ),
                            );
                            itemNameCtrl.clear();
                            itemPriceCtrl.clear();
                          });
                        },
                      ),
                    ),
                    if (items.isNotEmpty)
                      Column(
                        children: items
                            .map((item) => ListTile(
                                  dense: true,
                                  title: Text(item.name),
                                  trailing: Text(formatAmount(item.price)),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final walletId = walletCtrl.text.trim();
                    if (title.isEmpty || walletId.isEmpty) return;
                    await ref.read(projectRepositoryProvider).insertProject(
                          Project(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            title: title,
                            icon: icon,
                            linkedWalletId: walletId,
                            items: items,
                          ),
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
