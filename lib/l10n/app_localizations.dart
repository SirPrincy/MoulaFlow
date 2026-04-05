import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Sombre'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activer le thème sombre'**
  String get darkModeSubtitle;

  /// No description provided for @manageCategories.
  ///
  /// In fr, this message translates to:
  /// **'Gérer les Catégories'**
  String get manageCategories;

  /// No description provided for @manageCategoriesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter, modifier ou supprimer des rubriques'**
  String get manageCategoriesSubtitle;

  /// No description provided for @exportBackup.
  ///
  /// In fr, this message translates to:
  /// **'Exporter la Sauvegarde'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Générer un code de sauvegarde (Binaire)'**
  String get exportBackupSubtitle;

  /// No description provided for @importBackup.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer une Sauvegarde'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer depuis un code de sauvegarde'**
  String get importBackupSubtitle;

  /// No description provided for @dangerZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone de Danger'**
  String get dangerZone;

  /// No description provided for @resetData.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les données'**
  String get resetData;

  /// No description provided for @resetDataSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprime toutes les transactions et wallets'**
  String get resetDataSubtitle;

  /// No description provided for @confirmReset.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation critique'**
  String get confirmReset;

  /// No description provided for @confirmResetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous certain de vouloir supprimer l\'intégralité de vos données ? Cette action est irréversible.'**
  String get confirmResetMessage;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @deleteAll.
  ///
  /// In fr, this message translates to:
  /// **'TOUT SUPPRIMER'**
  String get deleteAll;

  /// No description provided for @dataReset.
  ///
  /// In fr, this message translates to:
  /// **'Données réinitialisées'**
  String get dataReset;

  /// No description provided for @biometrics.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité Biométrique'**
  String get biometrics;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Déverrouiller avec FaceID ou Empreinte'**
  String get biometricsSubtitle;

  /// No description provided for @accentColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur d\'Accent'**
  String get accentColor;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'Devise & Formatage'**
  String get currency;

  /// No description provided for @currencySymbol.
  ///
  /// In fr, this message translates to:
  /// **'Symbole'**
  String get currencySymbol;

  /// No description provided for @decimalDigits.
  ///
  /// In fr, this message translates to:
  /// **'Décimales'**
  String get decimalDigits;

  /// No description provided for @userProfile.
  ///
  /// In fr, this message translates to:
  /// **'Mon Profil'**
  String get userProfile;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @userName.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get userName;

  /// No description provided for @exportCSV.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get exportCSV;

  /// No description provided for @exportCSVSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Extraire les transactions pour Excel'**
  String get exportCSVSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
