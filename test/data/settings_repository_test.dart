import 'package:flutter_test/flutter_test.dart';
import 'package:moula_flow/data/app_access_method.dart';
import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/data/storage_keys.dart';
import 'package:moula_flow/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadAppSettings returns persisted values when valid', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.isDarkMode: true,
      StorageKeys.onboardingSeen: true,
      StorageKeys.appAccessMethod: AppAccessMethod.pin.storageValue,
      StorageKeys.userName: 'Alex',
      StorageKeys.userColor: 123,
      StorageKeys.userAvatar: 456,
      StorageKeys.accentColor: 789,
      StorageKeys.currencySymbol: r'$',
      StorageKeys.decimalDigits: 3,
      StorageKeys.biometricsEnabled: true,
      StorageKeys.languageCode: 'en',
    });

    final repo = SettingsRepository();
    final state = await repo.loadAppSettings();

    expect(state.isDarkMode, isTrue);
    expect(state.onboardingSeen, isTrue);
    expect(state.accessMethod, AppAccessMethod.pin);
    expect(state.userName, 'Alex');
    expect(state.userColor, 123);
    expect(state.userAvatar, 456);
    expect(state.accentColor, 789);
    expect(state.currencySymbol, r'$');
    expect(state.decimalDigits, 3);
    expect(state.biometricsEnabled, isTrue);
    expect(state.languageCode, 'en');
  });

  test('loadAppSettings falls back when values are corrupted', () async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.isDarkMode: 'true',
      StorageKeys.onboardingSeen: 1,
      StorageKeys.appAccessMethod: 'not-valid',
      StorageKeys.userName: 19,
      StorageKeys.userColor: 'invalid',
      StorageKeys.userAvatar: 'invalid',
      StorageKeys.accentColor: 'invalid',
      StorageKeys.currencySymbol: 77,
      StorageKeys.decimalDigits: 'invalid',
      StorageKeys.biometricsEnabled: 'yes',
      StorageKeys.languageCode: false,
    });

    final repo = SettingsRepository();
    final state = await repo.loadAppSettings();

    expect(state.isDarkMode, isFalse);
    expect(state.onboardingSeen, isFalse);
    expect(state.accessMethod, AppAccessMethod.none);
    expect(state.userName, AppConstants.defaultUserName);
    expect(state.userColor, 0xFF6200EE);
    expect(state.userAvatar, AppConstants.defaultUserAvatar);
    expect(state.accentColor, 0xFFBCC2FF);
    expect(state.currencySymbol, 'Ar');
    expect(state.decimalDigits, 2);
    expect(state.biometricsEnabled, isFalse);
    expect(state.languageCode, isNull);
  });
}
