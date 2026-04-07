import 'package:flutter/material.dart';
import '../models.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  final double currentSavings;

  const ProjectDetailPage({
    Key? key,
    required this.project,
    required this.currentSavings,
  }) : super(key: key);

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _toggleItemStatus(int index) {
    setState(() {
      final item = _project.items[index];
      final newItems = List<ProjectItem>.from(_project.items);
      newItems[index] = item.copyWith(isPurchased: !item.isPurchased);
      _project = _project.copyWith(items: newItems);
    });
    // À intégrer avec StateManagement plus tard
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _project.getProgress(widget.currentSavings);
    
    final amountSpent = _project.items
        .where((item) => item.isPurchased)
        .fold(0.0, (sum, item) => sum + item.price);
        
    final availableAffordableSavings = widget.currentSavings - amountSpent;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _project.icon,
                      style: const TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _project.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Épargne actuelle',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatAmount(widget.currentSavings),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatAmount(0),
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              Text(
                                formatAmount(_project.targetAmount),
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'Liste des articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _project.items[index];
                    
                    final isAffordable = !item.isPurchased && item.price <= availableAffordableSavings;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: item.isPurchased 
                              ? theme.colorScheme.surface.withOpacity(0.6) 
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: isAffordable 
                            ? Border.all(color: Colors.green.withOpacity(0.5), width: 1.5)
                            : Border.all(color: Colors.transparent),
                          boxShadow: [
                            if (!item.isPurchased)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            unselectedWidgetColor: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          child: CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            controlAffinity: ListTileControlAffinity.leading,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            activeColor: theme.colorScheme.primary,
                            value: item.isPurchased,
                            onChanged: (bool? value) => _toggleItemStatus(index),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                                color: item.isPurchased ? theme.colorScheme.onSurface.withOpacity(0.4) : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Text(
                                    formatAmount(item.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.isPurchased 
                                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                                        : theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  if (isAffordable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Abordable !',
                                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _project.items.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }
}
