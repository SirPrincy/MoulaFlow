import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moula_flow/providers.dart';

import '../data/app_access_method.dart';
import '../home_page.dart';
import '../security/app_access_gate.dart';
import 'onboarding_page.dart';

class AppLaunchFlowPage extends ConsumerStatefulWidget {
  const AppLaunchFlowPage({super.key});

  @override
  ConsumerState<AppLaunchFlowPage> createState() => _AppLaunchFlowPageState();
}

class _AppLaunchFlowPageState extends ConsumerState<AppLaunchFlowPage> {
  final AppAccessGateFactory _gateFactory = const AppAccessGateFactory();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(onboardingSeenProvider)) {
        _attemptAccess();
      }
    });
  }

  Future<void> _handleOnboardingCompleted() async {
    await ref.read(settingsRepositoryProvider).saveOnboardingSeen(true);
    ref.read(onboardingSeenProvider.notifier).state = true;

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

  @override
  Widget build(BuildContext context) {
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    
    if (!onboardingSeen) {
      return OnboardingPage(onFinished: _handleOnboardingCompleted);
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
