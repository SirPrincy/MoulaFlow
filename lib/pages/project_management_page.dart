import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';
import '../utils/app_icons.dart';
import 'tag_project_page.dart';

class ProjectManagementPage extends ConsumerStatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  ConsumerState<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends ConsumerState<ProjectManagementPage> {
  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gestion des Projets', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: tagsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(child: Text('Aucun tag créé pour le moment.\nAjoutez des tags dans vos transactions !', textAlign: TextAlign.center));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final isProject = tag.type == TagType.project || tag.goalAmount != null;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
                elevation: 0,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tag.color != null 
                        ? Color(int.parse(tag.color!.replaceAll('#', '0xFF'))).withValues(alpha: 0.2) 
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tag.icon != null 
                        ? AppIcons.getIconFromStr(tag.icon!) 
                        : (isProject ? Icons.rocket_launch : Icons.local_offer_outlined),
                      color: tag.color != null 
                        ? Color(int.parse(tag.color!.replaceAll('#', '0xFF'))) 
                        : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(tag.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    tag.goalAmount != null 
                      ? 'Budget: ${formatAmount(tag.goalAmount!)}' 
                      : (isProject ? 'Projet actif' : 'Tag simple'),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isProject) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TagProjectPage(tag: tag)));
                    } else {
                      _showEditTagDialog(tag);
                    }
                  },
                  onLongPress: () => _showEditTagDialog(tag),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditTagDialog(null),
        label: const Text('Nouveau Projet'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showEditTagDialog(TagDefinition? tag) {
    final nameController = TextEditingController(text: tag?.name);
    final goalController = TextEditingController(text: tag?.goalAmount?.toString() ?? '');
    TagType selectedType = tag?.type ?? TagType.project;
    String? selectedIcon = tag?.icon;
    String? selectedColor = tag?.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tag == null ? 'Nouveau Projet' : 'Modifier ${tag.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du projet/tag'),
                  enabled: tag == null, // Name is primary key equivalent for now in sync logic
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(labelText: 'Budget limite (Optionnel)', hintText: '0.00'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TagType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: TagType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                const SizedBox(height: 16),
                // Simple color picker mock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var color in [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple])
                      GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = '#${color.toARGB32().toRadixString(16).substring(2)}'),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selectedColor == '#${color.toARGB32().toRadixString(16).substring(2)}' 
                              ? Border.all(color: Colors.black, width: 2) 
                              : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                
                final newTag = (tag ?? TagDefinition(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name)).copyWith(
                  name: name,
                  type: selectedType,
                  goalAmount: double.tryParse(goalController.text),
                  color: selectedColor,
                  icon: selectedIcon,
                );

                if (tag == null) {
                  ref.read(tagRepositoryProvider).insertTag(newTag);
                } else {
                  ref.read(tagRepositoryProvider).updateTag(newTag);
                }
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
