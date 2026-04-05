import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../providers.dart';
import '../utils/styles.dart';
import '../utils/app_icons.dart';
import 'dialogs.dart';

class TagEditDialog extends ConsumerStatefulWidget {
  final TagDefinition? tag;
  final TagType initialType;

  const TagEditDialog({super.key, this.tag, this.initialType = TagType.custom});

  static Future<void> show(BuildContext context, {TagDefinition? tag, TagType initialType = TagType.custom}) {
    return showDialog(
      context: context,
      builder: (context) => TagEditDialog(tag: tag, initialType: initialType),
    );
  }

  @override
  ConsumerState<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<TagEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TagType _type;
  String? _selectedIcon;
  String? _selectedColor;
  bool _isProject = false;

  final List<String> _colors = [
    '#5C6BC0', '#3F51B5', '#673AB7', '#9C27B0', '#E91E63', '#EF5350',
    '#FF7043', '#FFB300', '#FDD835', '#CDDC39', '#8BC34A', '#4CAF50',
    '#009688', '#00BCD4', '#03A9F4', '#26C6DA', '#2196F3', '#78909C'
  ];

  final List<int> _icons = [
    0xf015a, // rocket_launch_rounded
    0xf0071, // person_rounded
    0xf004e, // face_rounded
    0xf55f,  // auto_awesome_rounded
    0xf0083, // pets_rounded
    0xf001d, // favorite_rounded
    0xf01c3, // local_offer_outlined
    0xe11d,  // category
    0xe897,  // label_outline
    0xe8b6,  // search (adding some standard ones)
    0xe88a,  // home
    0xe52f,  // restaurant
    0xe532,  // flight
    0xe332,  // movie
    0xe30a,  // brush
    0xeb41,  // sports_esports
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _goalController = TextEditingController(text: widget.tag?.goalAmount?.toString() ?? '');
    _type = widget.tag?.type ?? widget.initialType;
    _selectedIcon = widget.tag?.icon ?? _icons[0].toString();
    _selectedColor = widget.tag?.color ?? _colors[0];
    _isProject = _type == TagType.project || (widget.tag?.goalAmount != null && widget.tag!.goalAmount! > 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom')),
      );
      return;
    }

    final repo = ref.read(tagRepositoryProvider);
    final goal = double.tryParse(_goalController.text.trim());

    final newTag = TagDefinition(
      id: widget.tag?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _isProject ? TagType.project : TagType.custom,
      icon: _selectedIcon,
      color: _selectedColor,
      goalAmount: goal,
      createdAt: widget.tag?.createdAt ?? DateTime.now(),
    );

    if (widget.tag == null) {
      await repo.insertTag(newTag);
    } else {
      await repo.updateTag(newTag);
    }

    if (mounted) Navigator.pop(context);
  }

  void _delete() async {
    if (widget.tag == null) return;
    
    final confirm = await showDeleteConfirmDialog(
      context, 
      'Voulez-vous vraiment supprimer "${widget.tag!.name}" ? Toutes les transactions liées perdront ce tag.'
    );
    
    if (confirm == true) {
      await ref.read(tagRepositoryProvider).deleteTag(widget.tag!.id);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        // If we are on TagProjectPage, we might want to pop that too, but that's handled by observer or manual check in the page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
      title: Text(
        widget.tag == null ? 'Nouveau Projet / Tag' : 'Modifier ${widget.tag!.name}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: AppStyles.kInputDecoration(context, 'Nom').copyWith(
                prefixIcon: Icon(AppIcons.getIconFromStr(_selectedIcon)),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Est un Projet', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Les projets ont un budget et apparaissent sur le tableau de bord.'),
              value: _isProject,
              onChanged: (val) => setState(() => _isProject = val),
              activeTrackColor: theme.colorScheme.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_isProject) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _goalController,
                decoration: AppStyles.kInputDecoration(context, 'Budget Objectif (Optionnel)').copyWith(
                  suffixText: '€',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 24),
            const Text('Couleur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((c) {
                final color = Color(int.parse(c.replaceAll('#', '0xFF')));
                final isSelected = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 2) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Icône', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              width: double.maxFinite,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _icons.length,
                itemBuilder: (context, index) {
                  final code = _icons[index].toString();
                  final isSelected = _selectedIcon == code;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = code),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AppIcons.getIconData(_icons[index]),
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.tag != null)
          TextButton(
            onPressed: _delete,
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kButtonRadius)),
          ),
          child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
