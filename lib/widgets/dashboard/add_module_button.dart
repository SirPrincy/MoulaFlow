import 'package:flutter/material.dart';
import '../../data/dashboard_repository.dart';
import '../../utils/styles.dart';

class AddDashboardModuleButton extends StatelessWidget {
  final bool isEditMode;
  final Set<DashboardWidgetType> visibleModules;
  final ValueChanged<DashboardWidgetType> onAddModule;

  const AddDashboardModuleButton({
    super.key,
    required this.isEditMode,
    required this.visibleModules,
    required this.onAddModule,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditMode) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => ListView(
              children: DashboardWidgetType.values
                  .where((type) => !visibleModules.contains(type))
                  .map(
                    (type) => ListTile(
                      title: Text(type.name),
                      trailing: const Icon(
                        Icons.add_circle,
                        color: Colors.green,
                      ),
                      onTap: () {
                        onAddModule(type);
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un module'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.kDefaultRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
