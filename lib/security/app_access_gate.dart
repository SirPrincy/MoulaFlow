import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../data/app_access_method.dart';

abstract class AppAccessGate {
  const AppAccessGate();

  Future<bool> authorize(BuildContext context);
}

class NoSecurityGate extends AppAccessGate {
  const NoSecurityGate();

  @override
  Future<bool> authorize(BuildContext context) async => true;
}

class PinSecurityGate extends AppAccessGate {
  const PinSecurityGate();

  @override
  Future<bool> authorize(BuildContext context) async {
    // Placeholder for future dedicated PIN screen.
    return true;
  }
}

class PasswordSecurityGate extends AppAccessGate {
  const PasswordSecurityGate();

  @override
  Future<bool> authorize(BuildContext context) async {
    // Placeholder for future dedicated password screen.
    return true;
  }
}

class BiometricSecurityGate extends AppAccessGate {
  const BiometricSecurityGate();

  @override
  Future<bool> authorize(BuildContext context) async {
    final auth = LocalAuthentication();
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) return true; // Fallback if no biometrics available

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à Moula Flow',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      return didAuthenticate;
    } on Exception catch (e) {
      debugPrint('Biometric auth error (likely unsupported platform): $e');
      // If biometrics is requested but fails due to platform (like Linux MissingPluginException),
      // we allow entry as a fallback to avoid blocking the user.
      return true;
    }
  }
}

class AppAccessGateFactory {
  const AppAccessGateFactory();

  AppAccessGate create(AppAccessMethod method) {
    return switch (method) {
      AppAccessMethod.none => const NoSecurityGate(),
      AppAccessMethod.pin => const PinSecurityGate(),
      AppAccessMethod.password => const PasswordSecurityGate(),
      AppAccessMethod.biometric => const BiometricSecurityGate(),
    };
  }
}
