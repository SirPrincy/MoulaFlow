import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moula_flow/widgets/app_logo.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/utils/app_constants.dart';

class WelcomePage extends ConsumerStatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const WelcomePage({
    super.key,
    required this.onStart,
    required this.onLogin,
  });

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  bool _isTransitioning = false;

  void _handleStart() {
    setState(() => _isTransitioning = true);
    // Add a tiny delay to ensure the UI has time to show the loader 
    // before the potentially heavy SetupWizardPage starts building.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) widget.onStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingSeen = ref.watch(onboardingSeenProvider);
    final userName = ref.watch(userNameProvider);
    final userColor = ref.watch(userColorProvider);
    final userAvatar = ref.watch(userAvatarProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(userColor);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
              : [const Color(0xFFFBFBFF), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Loading Bar at the top
              if (_isTransitioning)
                LinearProgressIndicator(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  color: primaryColor,
                  minHeight: 4,
                )
              else
                const SizedBox(height: 4),
                
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      
                      // Hero Section
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: onboardingSeen 
                          ? CircleAvatar(
                              radius: 50,
                              backgroundColor: primaryColor.withValues(alpha: 0.2),
                              child: Icon(IconData(userAvatar, fontFamily: 'MaterialIcons'), size: 50, color: primaryColor),
                            )
                          : const AppLogo(size: 100, borderRadius: 24, withShadow: true),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        onboardingSeen ? 'Bonsoir ${userName ?? AppConstants.defaultUserName}' : 'Moula Flow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.newsreader(
                          fontSize: onboardingSeen ? 36 : 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        onboardingSeen ? 'Prêt à optimiser vos flux ?' : 'Pilotez vos finances\ndevient un art.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.workSans(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      
                      const Spacer(flex: 3),
                      
                      // Status Text when loading
                      if (_isTransitioning) ...[
                        Text(
                          'Préparation de votre espace...',
                          style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Call to Action
                      if (!onboardingSeen) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isTransitioning ? null : _handleStart,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isTransitioning 
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  'C\'est parti !',
                                  style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: widget.onLogin,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'Accéder à Moula Flow',
                              style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Maybe a "Not me?" action later
                          },
                          child: Text('Ce n\'est pas vous ?', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
