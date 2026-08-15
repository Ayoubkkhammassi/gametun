import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_button.dart';
import '../../../core/widgets/gt_logo.dart';
import '../../../core/widgets/gt_scaffold.dart';

/// Écran 1 (spec §4) : logo + slogan + Créer un compte / Se connecter.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const GtLogo(size: 96),
                const SizedBox(height: 20),
                const Text(
                  'La communauté gaming tunisienne',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Trouve tes joueurs. Crée ton équipe. Joue ensemble.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const Spacer(flex: 4),
                GtButton(
                  label: 'CRÉER UN COMPTE',
                  icon: Icons.person_add_alt_1,
                  onPressed: () => context.push('/register'),
                ),
                const SizedBox(height: 14),
                GtOutlineButton(
                  label: 'SE CONNECTER',
                  icon: Icons.login,
                  onPressed: () => context.push('/login'),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
