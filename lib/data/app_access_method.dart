enum AppAccessMethod {
  none,
  pin,
  password,
}

extension AppAccessMethodX on AppAccessMethod {
  String get storageValue => switch (this) {
    AppAccessMethod.none => 'none',
    AppAccessMethod.pin => 'pin',
    AppAccessMethod.password => 'password',
  };

  static AppAccessMethod fromStorageValue(String? raw) {
    return switch (raw) {
      'pin' => AppAccessMethod.pin,
      'password' => AppAccessMethod.password,
      _ => AppAccessMethod.none,
    };
  }
}
