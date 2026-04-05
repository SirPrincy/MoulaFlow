import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moula_flow/data/settings_repository.dart';
import 'package:moula_flow/pages/app_launch_flow_page.dart';
import 'package:moula_flow/utils/styles.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/utils/app_provider_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsRepo = SettingsRepository();
  final isDark = await settingsRepo.loadIsDarkMode();
  final onboardingSeen = await settingsRepo.loadOnboardingSeen();
  final accessMethod = await settingsRepo.loadAppAccessMethod();
  final userName = await settingsRepo.loadUserName();
  final userColor = await settingsRepo.loadUserColor();
  final userAvatar = await settingsRepo.loadUserAvatar();
  final accentColor = await settingsRepo.loadAccentColor();
  final currencySymbol = await settingsRepo.loadCurrencySymbol();
  final decimalDigits = await settingsRepo.loadDecimalDigits();
  final biometricsEnabled = await settingsRepo.loadBiometricsEnabled();

  runApp(ProviderScope(
    observers: const [AppProviderObserver()],
    overrides: [
      themeModeProvider.overrideWith(() => ThemeModeNotifier(isDark ? ThemeMode.dark : ThemeMode.light)),
      onboardingSeenProvider.overrideWith(() => OnboardingSeenNotifier(onboardingSeen)),
      appAccessMethodProvider.overrideWith(() => AppAccessMethodNotifier(accessMethod)),
      userNameProvider.overrideWith(() => UserNameNotifier(userName)),
      userColorProvider.overrideWith(() => UserColorNotifier(userColor)),
      userAvatarProvider.overrideWith(() => UserAvatarNotifier(userAvatar)),
      accentColorProvider.overrideWith(() => AccentColorNotifier(accentColor)),
      currencySymbolProvider.overrideWith(() => CurrencySymbolNotifier(currencySymbol)),
      decimalDigitsProvider.overrideWith(() => DecimalDigitsNotifier(decimalDigits)),
      biometricsEnabledProvider.overrideWith(() => BiometricsEnabledNotifier(biometricsEnabled)),
    ],
    child: const MoulaFlowApp(),
  ));
}

class MoulaFlowApp extends ConsumerWidget {
  const MoulaFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    final lightColorScheme = ColorScheme.light(
      primary: accentColor,
      secondary: accentColor,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A1A),
    );

    final darkColorScheme = ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      surface: AppStyles.kSurface,
      onSurface: AppStyles.kOnSurface,
    );

    return MaterialApp(
      title: 'Moula Flow',
      debugShowCheckedModeBanner: false,
      themeMode: currentMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: lightColorScheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black12, width: 1),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: lightColorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.workSansTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.newsreader(
            fontWeight: FontWeight.w900, 
            letterSpacing: -1.5,
            color: lightColorScheme.onSurface,
          ),
          headlineMedium: GoogleFonts.newsreader(
            fontWeight: FontWeight.w800, 
            letterSpacing: -0.5,
            color: lightColorScheme.onSurface,
          ),
          titleLarge: GoogleFonts.newsreader(
            fontWeight: FontWeight.w700, 
            letterSpacing: -0.2,
            color: lightColorScheme.onSurface,
          ),
          bodyLarge: GoogleFonts.workSans(
            fontSize: 16, 
            fontWeight: FontWeight.w500,
            color: lightColorScheme.onSurface,
          ),
          bodyMedium: GoogleFonts.workSans(
            fontSize: 14, 
            fontWeight: FontWeight.w500,
            color: lightColorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: darkColorScheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white10, width: 1),
          ),
          color: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkColorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.newsreader(
            fontWeight: FontWeight.w900, 
            letterSpacing: -1.5,
            color: darkColorScheme.onSurface,
          ),
          headlineMedium: GoogleFonts.newsreader(
            fontWeight: FontWeight.w800, 
            letterSpacing: -0.5,
            color: darkColorScheme.onSurface,
          ),
          titleLarge: GoogleFonts.newsreader(
            fontWeight: FontWeight.w700, 
            letterSpacing: -0.2,
            color: darkColorScheme.onSurface,
          ),
          bodyLarge: GoogleFonts.workSans(
            fontSize: 16, 
            fontWeight: FontWeight.w500,
            color: darkColorScheme.onSurface,
          ),
          bodyMedium: GoogleFonts.workSans(
            fontSize: 14, 
            fontWeight: FontWeight.w500,
            color: AppStyles.kOnSurfaceVariant,
          ),
        ),
      ),
      home: const AppLaunchFlowPage(),
    );
  }
}
