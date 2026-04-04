import 'package:flutter/material.dart';

import '../data/app_access_method.dart';
import '../data/settings_repository.dart';
import '../home_page.dart';
import '../security/app_access_gate.dart';
import 'onboarding_page.dart';

class AppLaunchFlowPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final bool onboardingSeenInitial;
  final AppAccessMethod accessMethodInitial;

  const AppLaunchFlowPage({
    super.key,
    required this.themeNotifier,
    required this.onboardingSeenInitial,
    required this.accessMethodInitial,
  });

  @override
  State<AppLaunchFlowPage> createState() => _AppLaunchFlowPageState();
}

class _AppLaunchFlowPageState extends State<AppLaunchFlowPage> {
  late bool _onboardingSeen;
  late AppAccessMethod _accessMethod;
  final AppAccessGateFactory _gateFactory = const AppAccessGateFactory();

  @override
  void initState() {
    super.initState();
    _onboardingSeen = widget.onboardingSeenInitial;
    _accessMethod = widget.accessMethodInitial;
    if (_onboardingSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _attemptAccess());
    }
  }

  Future<void> _handleOnboardingCompleted() async {
    final settingsRepo = SettingsRepository();
    await settingsRepo.saveOnboardingSeen(true);

    if (!mounted) return;

    setState(() => _onboardingSeen = true);
    await _attemptAccess();
  }

  Future<void> _attemptAccess() async {
    final gate = _gateFactory.create(_accessMethod);
    final granted = await gate.authorize(context);
    if (!mounted || !granted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(themeNotifier: widget.themeNotifier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingSeen) {
      return OnboardingPage(onFinished: _handleOnboardingCompleted);
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
