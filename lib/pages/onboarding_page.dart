import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  final Future<void> Function() onFinished;

  const OnboardingPage({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.dashboard_customize_outlined,
      title: 'Pilotez vos finances',
      description:
          'Centralisez vos comptes et visualisez votre situation en un coup d’œil.',
    ),
    _OnboardingStep(
      icon: Icons.track_changes_outlined,
      title: 'Suivez vos objectifs',
      description:
          'Créez des budgets, surveillez vos dépenses et restez aligné avec vos priorités.',
    ),
    _OnboardingStep(
      icon: Icons.insights_outlined,
      title: 'Décidez plus vite',
      description:
          'Analysez vos tendances pour prendre de meilleures décisions au quotidien.',
    ),
  ];

  int _currentIndex = 0;
  bool _isSubmitting = false;

  bool get _isLastStep => _currentIndex == _steps.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await widget.onFinished();
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _next() async {
    if (_isLastStep) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1}/${_steps.length}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : _finish,
                    child: const Text('Passer'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            child: Icon(step.icon, size: 42),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _next,
                  child: Text(_isLastStep ? 'Commencer' : 'Suivant'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
