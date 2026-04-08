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
  late TagType _selectedType;
  String? _selectedIcon;
  String? _selectedColor;

  final List<String> _colors = [
    '#3B82F6', '#2563EB', '#5C6BC0', '#7C3AED', '#9C27B0', '#EC4899',
    '#EF5350', '#F97316', '#FFB300', '#EAB308', '#84CC16', '#22C55E',
    '#10B981', '#14B8A6', '#06B6D4', '#0EA5E9', '#6366F1', '#64748B'
  ];

  final List<int> _icons = [
    0xf01c3, // local_offer_outlined
    0xf0071, // person_rounded
    0xe55f, // place_outlined
    0xe8f9, // schedule_rounded
    0xe850, // account_balance_wallet
    0xe227, // savings
    0xe263, // trending_up
    0xe549, // local_hospital
    0xe80c, // school
    0xe530, // directions_car
    0xe88a, // home
    0xe56c, // restaurant
    0xe59c, // sports_esports
    0xe8cc, // shopping_bag
    0xe539, // flight_takeoff
    0xe0af, // work_outline
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _goalController = TextEditingController(text: widget.tag?.goalAmount?.toString() ?? '');
    _selectedType = widget.tag?.type ?? widget.initialType;
    _selectedIcon = widget.tag?.icon ?? _icons[0].toString();
    _selectedColor = widget.tag?.color ?? _colors[0];
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
    final isProject = widget.initialType == TagType.project || _selectedType == TagType.project;

    final newTag = TagDefinition(
      id: widget.tag?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      type: isProject ? TagType.project : _selectedType,
      icon: _selectedIcon,
      color: _selectedColor,
      goalAmount: isProject ? goal : null,
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
    final isProjectMode = widget.initialType == TagType.project || widget.tag?.type == TagType.project;
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius)),
      title: Text(
        widget.tag == null ? 'Tags' : 'Modifier ${widget.tag!.name}',
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
            DropdownButtonFormField<TagType>(
              initialValue: isProjectMode ? TagType.project : _selectedType,
              items: (isProjectMode
                      ? [TagType.project]
                      : [
                          TagType.custom,
                          TagType.person,
                          TagType.place,
                          TagType.expense,
                          TagType.income,
                          TagType.food,
                          TagType.transport,
                          TagType.housing,
                          TagType.shopping,
                          TagType.leisure,
                          TagType.travel,
                          TagType.health,
                          TagType.education,
                          TagType.business,
                          TagType.debt,
                          TagType.saving,
                          TagType.investment,
                          TagType.recurring,
                        ])
                  .map(
                    (type) => DropdownMenuItem<TagType>(
                      value: type,
                      child: Text(type.labelFr),
                    ),
                  )
                  .toList(),
              decoration: AppStyles.kInputDecoration(context, 'Type de tag'),
              onChanged: isProjectMode
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
            ),
            if (isProjectMode) ...[
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
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => _ColorPickerSheet(
                    colors: _colors,
                    selectedColor: _selectedColor,
                  ),
                );
                if (result != null) {
                  setState(() => _selectedColor = result);
                }
              },
              icon: Icon(
                Icons.palette_outlined,
                color: _selectedColor != null
                    ? Color(int.parse(_selectedColor!.replaceAll('#', '0xFF')))
                    : null,
              ),
              label: const Text('Choisir une couleur'),
            ),
            const SizedBox(height: 24),
            const Text('Icône', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx) => _IconPickerSheet(
                    icons: _icons,
                    selectedIcon: _selectedIcon,
                  ),
                );
                if (result != null) {
                  setState(() => _selectedIcon = result);
                }
              },
              icon: Icon(AppIcons.getIconFromStr(_selectedIcon, fallback: Icons.local_offer_outlined)),
              label: const Text('Choisir une icône'),
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

class _ColorPickerSheet extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;

  const _ColorPickerSheet({required this.colors, this.selectedColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir une couleur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: colors.map((c) {
                final color = Color(int.parse(c.replaceAll('#', '0xFF')));
                final isSelected = selectedColor == c;
                return InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => Navigator.pop(context, c),
                  child: Container(
                    width: 38,
                    height: 38,
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
          ],
        ),
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  final List<int> icons;
  final String? selectedIcon;

  const _IconPickerSheet({required this.icons, this.selectedIcon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choisir une icône', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final code = icons[index].toString();
                final isSelected = selectedIcon == code;
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.pop(context, code),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIcons.getIconData(icons[index]),
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
