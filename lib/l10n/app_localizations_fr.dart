// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Paramètres';

  @override
  String get darkMode => 'Mode Sombre';

  @override
  String get darkModeSubtitle => 'Activer le thème sombre';

  @override
  String get manageCategories => 'Gérer les Catégories';

  @override
  String get manageCategoriesSubtitle =>
      'Ajouter, modifier ou supprimer des rubriques';

  @override
  String get exportBackup => 'Exporter la Sauvegarde';

  @override
  String get exportBackupSubtitle => 'Générer un code de sauvegarde (Binaire)';

  @override
  String get importBackup => 'Restaurer une Sauvegarde';

  @override
  String get importBackupSubtitle => 'Restaurer depuis un code de sauvegarde';

  @override
  String get dangerZone => 'Zone de Danger';

  @override
  String get resetData => 'Réinitialiser les données';

  @override
  String get resetDataSubtitle => 'Supprime toutes les transactions et wallets';

  @override
  String get confirmReset => 'Confirmation critique';

  @override
  String get confirmResetMessage =>
      'Êtes-vous certain de vouloir supprimer l\'intégralité de vos données ? Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get deleteAll => 'TOUT SUPPRIMER';

  @override
  String get dataReset => 'Données réinitialisées';

  @override
  String get biometrics => 'Sécurité Biométrique';

  @override
  String get biometricsSubtitle => 'Déverrouiller avec FaceID ou Empreinte';

  @override
  String get accentColor => 'Couleur d\'Accent';

  @override
  String get currency => 'Devise & Formatage';

  @override
  String get currencySymbol => 'Symbole';

  @override
  String get decimalDigits => 'Décimales';

  @override
  String get userProfile => 'Mon Profil';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get userName => 'Nom d\'utilisateur';

  @override
  String get exportCSV => 'Exporter en CSV';

  @override
  String get exportCSVSubtitle => 'Extraire les transactions pour Excel';
}
