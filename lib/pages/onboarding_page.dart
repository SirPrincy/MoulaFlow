import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/styles.dart';
import '../widgets/app_logo.dart';
import '../home_page.dart';
import '../data/settings_repository.dart';

class OnboardingPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  const OnboardingPage({super.key, required this.themeNotifier});

  Future<void> _completeOnboarding(BuildContext context) async {
    final settingsRepo = SettingsRepository();
    await settingsRepo.saveOnboardingSeen(true);
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(themeNotifier: themeNotifier),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.kSurfaceLowest,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyles.kPrimary.withValues(alpha: 0.05),
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  AppStyles.kPrimary.withValues(alpha: 0.05),
                  BlendMode.srcOver,
                ),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppStyles.kSurfaceHigh.withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ColorFilter.mode(
                  AppStyles.kSurfaceHigh.withValues(alpha: 0.2),
                  BlendMode.srcOver,
                ),
                child: Container(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Brand Identity Component
                          const AppLogo(size: 120, borderRadius: 24, withShadow: true),
                          const SizedBox(height: 48),
                          // Editorial Headline
                          Text(
                            'Moula Flow',
                            style: GoogleFonts.newsreader(
                              textStyle: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                color: AppStyles.kOnSurface,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Quiet authority in the digital-first financial journal.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.newsreader(
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                fontStyle: FontStyle.italic,
                                color: AppStyles.kOnSurfaceVariant.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
                          // Asymmetric Detail
                          Container(
                            width: 2,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppStyles.kPrimary.withValues(alpha: 0.4),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Interactive Layer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                  child: Column(
                    children: [
                      // Primary CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _completeOnboarding(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.kOnSurface,
                            foregroundColor: AppStyles.kSurface,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'ENTER JOURNEY',
                            style: GoogleFonts.workSans(
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Secondary Navigation
                      Text(
                        'SIGN IN TO EXISTING VAULT',
                        style: GoogleFonts.workSans(
                          textStyle: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2,
                            color: AppStyles.kOnSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Minimal Legal Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFooterLink('PRIVACY'),
                          const SizedBox(width: 24),
                          _buildFooterLink('TERMS'),
                          const SizedBox(width: 24),
                          _buildFooterLink('SECURITY'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFooterLink(String label) {
    return Text(
      label,
      style: GoogleFonts.workSans(
        textStyle: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.5,
          color: AppStyles.kOnSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
