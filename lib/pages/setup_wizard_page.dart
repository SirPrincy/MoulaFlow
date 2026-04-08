import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/utils/app_constants.dart';
import 'package:moula_flow/utils/currency_utils.dart';
import 'package:moula_flow/utils/app_icons.dart';
import 'package:moula_flow/widgets/app_logo.dart';
import 'package:moula_flow/widgets/wallet_form.dart';
import 'package:uuid/uuid.dart';

class SetupWizardPage extends ConsumerStatefulWidget {
  final Future<void> Function() onFinished;

  const SetupWizardPage({super.key, required this.onFinished});

  @override
  ConsumerState<SetupWizardPage> createState() => _SetupWizardPageState();
}

class _SetupWizardPageState extends ConsumerState<SetupWizardPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // State collected during wizard
  String _userName = '';
  int _userColor = 0xFF6366F1; // Default to Indigo
  int _userAvatar = Icons.person_rounded.codePoint;
  
  Wallet? _setupWallet;
  String _setupCurrencyCode = 'MGA';

  final List<int> _availableColors = [
    0xFF6366F1, // Indigo
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Violet
  ];

  final List<IconData> _availableIcons = [
    Icons.person_rounded,
    Icons.face_rounded,
    Icons.auto_awesome_rounded,
    Icons.rocket_launch_rounded,
    Icons.pets_rounded,
    Icons.favorite_rounded,
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finalize();
    }
  }

  void _previous() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finalize() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final settings = ref.read(settingsRepositoryProvider);
      
      // 1. Save Profile
      await settings.saveUserName(_userName.isEmpty ? AppConstants.defaultUserName : _userName);
      ref.read(userNameProvider.notifier).update(_userName.isEmpty ? AppConstants.defaultUserName : _userName);
      
      await settings.saveUserColor(_userColor);
      ref.read(userColorProvider.notifier).update(_userColor);
      
      await settings.saveUserAvatar(_userAvatar);
      ref.read(userAvatarProvider.notifier).update(_userAvatar);

      ref.read(currencySymbolProvider.notifier).update(
            symbolFromCurrencyCode(_setupCurrencyCode),
          );
      ref.read(baseCurrencyCodeProvider.notifier).update(_setupCurrencyCode);

      // 2. Create Wallet
      if (_setupWallet != null) {
        await ref.read(walletRepositoryProvider).insertWallet(_setupWallet!);
      } else {
        // Fallback just in case
        final wallet = Wallet(
          id: const Uuid().v4(),
          name: 'Compte Principal',
          initialBalance: 0.0,
          type: WalletType.current,
        );
        await ref.read(walletRepositoryProvider).insertWallet(wallet);
      }

      // 3. Mark Onboarding as seen
      await widget.onFinished();
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erreur: $e')),
         );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 6,
                    width: (MediaQuery.of(context).size.width - 48) * ((_currentStep + 1) / 4),
                    decoration: BoxDecoration(
                      color: Color(_userColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildIntroStep(),
                  _buildNameStep(),
                  _buildWalletStep(),
                  _buildSuccessStep(),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                   if (_currentStep > 0 && _currentStep < 3)
                    IconButton(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                  const Spacer(),
                  if (_currentStep != 2) // Hide Next button on Wallet step, form handles it
                    SizedBox(
                      width: 160,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _next,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Color(_userColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(_currentStep == 3 ? 'C\'est parti' : 'Suivant'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
    return _WizardStepContainer(
      icon: Icons.auto_awesome_rounded,
      title: 'Bienvenue sur Moula Flow',
      child: Column(
        children: [
          const AppLogo(size: 80, borderRadius: 20),
          const SizedBox(height: 32),
          _buildInfoRow(Icons.security_rounded, 'Local-first', 'Vos données restent sur votre appareil.'),
          _buildInfoRow(Icons.speed_rounded, 'Réactivité', 'Un suivi en temps réel de votre patrimoine.'),
          _buildInfoRow(Icons.palette_rounded, 'Premium UI', 'Une expérience conçue pour le confort.'),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    final theme = Theme.of(context);
    return _WizardStepContainer(
      icon: Icons.face_rounded,
      title: 'Identité & Style',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            onChanged: (val) => setState(() => _userName = val),
            decoration: InputDecoration(
              hintText: 'Ton prénom ou pseudo',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 32),
          const Text('CHOISIS TA COULEUR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _availableColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final colorVal = _availableColors[index];
                return GestureDetector(
                  onTap: () => setState(() => _userColor = colorVal),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: _userColor == colorVal ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text('CHOISIS TON AVATAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableIcons.map((icon) => GestureDetector(
              onTap: () => setState(() => _userAvatar = icon.codePoint),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _userAvatar == icon.codePoint ? Color(_userColor).withValues(alpha: 0.2) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: _userAvatar == icon.codePoint ? Border.all(color: Color(_userColor), width: 2) : null,
                ),
                child: Icon(icon, color: _userAvatar == icon.codePoint ? Color(_userColor) : theme.colorScheme.onSurface),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletStep() {
    return _WizardStepContainer(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Créez votre\npremier compte',
      child: WalletForm(
        initialCurrencyCode: _setupCurrencyCode,
        onSave: (wallet) {
          setState(() {
            _setupWallet = wallet;
            _setupCurrencyCode = wallet.currencyCode;
          });
          _next();
        },
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.getIconData(_userAvatar), size: 100, color: Color(_userColor)),
          const SizedBox(height: 24),
          Text(
            'Parfait, ${_userName.isEmpty ? AppConstants.defaultUserName : _userName} !',
            style: GoogleFonts.newsreader(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Votre environnement est prêt.\nBienvenue dans Moula Flow.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Color(_userColor)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStepContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _WizardStepContainer({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.newsreader(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 48),
          child,
        ],
      ),
    );
  }
}
