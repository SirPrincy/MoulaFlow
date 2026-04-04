import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';

import '../home_page.dart';
import '../security/app_access_gate.dart';
import 'setup_wizard_page.dart';
import 'welcome_page.dart';

class AppLaunchFlowPage extends ConsumerStatefulWidget {
  const AppLaunchFlowPage({super.key});

  @override
  ConsumerState<AppLaunchFlowPage> createState() => _AppLaunchFlowPageState();
}

class _AppLaunchFlowPageState extends ConsumerState<AppLaunchFlowPage> {
  final AppAccessGateFactory _gateFactory = const AppAccessGateFactory();
  bool _showWelcome = true;

  Future<void> _handleOnboardingCompleted() async {
    await ref.read(settingsRepositoryProvider).saveOnboardingSeen(true);
    ref.read(onboardingSeenProvider.notifier).update(true);

    if (!mounted) return;
    await _attemptAccess();
  }

  Future<void> _attemptAccess() async {
    final accessMethod = ref.read(appAccessMethodProvider);
    final gate = _gateFactory.create(accessMethod);
    final granted = await gate.authorize(context);
    if (!mounted || !granted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
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
