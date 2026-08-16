import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_button.dart';
import '../../../core/widgets/gt_logo.dart';
import '../../../core/widgets/gt_scaffold.dart';
import '../application/auth_controller.dart';

/// Écran 1 (spec §4) : logo + slogan + Créer un compte / Se connecter / Google.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
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
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                const SizedBox(height: 14),
                // Connexion Google réelle.
                _GoogleButton(
                  loading: state.loading,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).loginWithGoogle(),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "G" coloré Google (sans logo copyrighté).
                    const Text('G',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4285F4),
                        )),
                    const SizedBox(width: 12),
                    Text('Continuer avec Google',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}
