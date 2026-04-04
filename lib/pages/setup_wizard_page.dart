import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moula_flow/models.dart';
import 'package:moula_flow/providers.dart';
import 'package:moula_flow/widgets/app_logo.dart';
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
  
  String _walletName = '';
  double _walletBalance = 0.0;
  WalletType _walletType = WalletType.current;
  
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

  

  final List<({String label, IconData icon, WalletType type})> _walletTypes = [
    (label: 'Compte Bancaire', icon: Icons.account_balance_rounded, type: WalletType.bank),
    (label: 'Livret Épargne', icon: Icons.savings_rounded, type: WalletType.savings),
    (label: 'Espèces', icon: Icons.payments_rounded, type: WalletType.cash),
    (label: 'Mobile Money', icon: Icons.phone_android_rounded, type: WalletType.mobileMoney),
  ];

  final TextEditingController _walletNameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _walletNameController.dispose();
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
      await settings.saveUserName(_userName.isEmpty ? 'Utilisateur' : _userName);
      ref.read(userNameProvider.notifier).update(_userName);
      
      await settings.saveUserColor(_userColor);
      ref.read(userColorProvider.notifier).update(_userColor);
      
      await settings.saveUserAvatar(_userAvatar);
      ref.read(userAvatarProvider.notifier).update(_userAvatar);

      // 2. Create Wallet
      final finalWalletName = _walletName.isEmpty ? 'Compte Principal' : _walletName;
      final wallet = Wallet(
        id: const Uuid().v4(),
        name: finalWalletName,
        initialBalance: _walletBalance,
        type: _walletType,
      );
      await ref.read(walletRepositoryProvider).insertWallet(wallet);

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
    final theme = Theme.of(context);
    final primaryColor = Color(_userColor);

    return _WizardStepContainer(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Créez votre\npremier compte',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _walletNameController,
            onChanged: (val) => _walletName = val,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'NOM DU COMPTE',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              hintText: 'ex: Compte Principal',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 32),
          const Text('TYPE DE COMPTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _walletTypes.map((item) {
              final isSelected = _walletType == item.type;
              return GestureDetector(
                onTap: () => setState(() => _walletType = item.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected ? Border.all(color: primaryColor, width: 2) : Border.all(color: Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 20, color: isSelected ? primaryColor : theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(item.label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? primaryColor : theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => _walletBalance = double.tryParse(val.replaceAll(',', '.')) ?? 0.0,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'SOLDE INITIAL',
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              suffixText: '€',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconData(_userAvatar, fontFamily: 'MaterialIcons'), size: 100, color: Color(_userColor)),
          const SizedBox(height: 24),
          Text(
            'Parfait, ${_userName.isEmpty ? 'Moula' : _userName} !',
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
