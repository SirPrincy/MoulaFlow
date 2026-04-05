enum AppAccessMethod {
  none,
  pin,
  password,
  biometric,
}

extension AppAccessMethodX on AppAccessMethod {
  String get storageValue => switch (this) {
    AppAccessMethod.none => 'none',
    AppAccessMethod.pin => 'pin',
    AppAccessMethod.password => 'password',
    AppAccessMethod.biometric => 'biometric',
  };

  static AppAccessMethod fromStorageValue(String? raw) {
    return switch (raw) {
      'pin' => AppAccessMethod.pin,
      'password' => AppAccessMethod.password,
      'biometric' => AppAccessMethod.biometric,
      _ => AppAccessMethod.none,
    };
  }
}
