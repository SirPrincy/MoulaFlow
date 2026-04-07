import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';

import '../home_page.dart';
import '../security/app_access_gate.dart';
import 'setup_wizard_page.dart';
import 'welcome_page.dart';
import '../domain/recurring_payment_service.dart';

class AppLaunchFlowPage extends ConsumerStatefulWidget {
  const AppLaunchFlowPage({super.key});

  @override
  ConsumerState<AppLaunchFlowPage> createState() => _AppLaunchFlowPageState();
}

class _AppLaunchFlowPageState extends ConsumerState<AppLaunchFlowPage> {
  final AppAccessGateFactory _gateFactory = const AppAccessGateFactory();
  bool _showWelcome = true;
  bool _showRecoveryHint = false;

  Future<void> _handleOnboardingCompleted() async {
    await ref.read(settingsRepositoryProvider).saveOnboardingSeen(true);
    ref.read(onboardingSeenProvider.notifier).update(true);

    if (!mounted) return;
    await _processRecurring();
    await _attemptAccess();
  }

  Future<void> _attemptAccess() async {
    final accessMethod = ref.read(appAccessMethodProvider);
    final gate = _gateFactory.create(accessMethod);
    final granted = await gate.authorize(context);
    if (!mounted || !granted) return;

    await _processRecurring();
    _showRecoveryHint = await ref.read(settingsRepositoryProvider).shouldShowRecoveryHint();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(showRecoveryHint: _showRecoveryHint),
      ),
    );
  }

  Future<void> _processRecurring() async {
    try {
      final processed = await ref.read(recurringPaymentServiceProvider).checkAndProcessPayments();
      // Wait a bit to ensure the SnackBar can be seen or let the HomePage handle it
      if (processed > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$processed paiement(s) récurrent(s) traité(s) automatiquement.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing recurring: $e');
    }
  }

  void _startSetup() {
    setState(() => _showWelcome = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showWelcome) {
      return WelcomePage(
        onStart: _startSetup,
        onLogin: _attemptAccess,
      );
    }

    final onboardingSeen = ref.watch(onboardingSeenProvider);
    if (!onboardingSeen) {
      return SetupWizardPage(onFinished: _handleOnboardingCompleted);
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
