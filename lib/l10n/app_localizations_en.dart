// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Enable dark theme';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get manageCategoriesSubtitle => 'Add, edit or delete categories';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get exportBackupSubtitle => 'Generate a binary backup code';

  @override
  String get importBackup => 'Restore Backup';

  @override
  String get importBackupSubtitle => 'Restore from a backup code';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetData => 'Reset Data';

  @override
  String get resetDataSubtitle => 'Delete all transactions and wallets';

  @override
  String get confirmReset => 'Critical Confirmation';

  @override
  String get confirmResetMessage =>
      'Are you sure you want to delete all your data? This action is irreversible.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAll => 'DELETE ALL';

  @override
  String get dataReset => 'Data Reset';

  @override
  String get biometrics => 'Biometric Security';

  @override
  String get biometricsSubtitle => 'Unlock with FaceID or Fingerprint';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get currency => 'Currency & Formatting';

  @override
  String get currencySymbol => 'Symbol';

  @override
  String get decimalDigits => 'Decimals';

  @override
  String get userProfile => 'My Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get userName => 'Username';

  @override
  String get exportCSV => 'Export CSV';

  @override
  String get exportCSVSubtitle => 'Extract transactions for Excel';
}
