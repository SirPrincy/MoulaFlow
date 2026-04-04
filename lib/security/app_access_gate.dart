import 'package:flutter/material.dart';
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

class AppAccessGateFactory {
  const AppAccessGateFactory();

  AppAccessGate create(AppAccessMethod method) {
    return switch (method) {
      AppAccessMethod.none => const NoSecurityGate(),
      AppAccessMethod.pin => const PinSecurityGate(),
      AppAccessMethod.password => const PasswordSecurityGate(),
    };
  }
}
