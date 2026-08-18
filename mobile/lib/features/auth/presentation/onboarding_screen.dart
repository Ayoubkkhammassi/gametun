import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_anim.dart';
import '../../../core/widgets/gt_button.dart';
import '../../../core/widgets/gt_logo.dart';
import '../../../core/widgets/gt_scaffold.dart';
import '../application/auth_controller.dart';

/// Écran 1 (spec §4) : logo néon + slogan + Créer un compte / Se connecter / Google.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                // Logo avec halo néon pulsant (LED).
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) {
                    final g = 0.4 + 0.35 * _pulse.value;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: g),
                            blurRadius: 50 + 30 * _pulse.value,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: AppColors.magenta.withValues(alpha: g * 0.6),
                            blurRadius: 70 + 30 * _pulse.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: const GtLogo(size: 104),
                ),
                const SizedBox(height: 28),
                // Wordmark néon.
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [
                    AppColors.cyan,
                    AppColors.primary,
                    AppColors.magenta,
                  ]).createShader(b),
                  child: const Text(
                    'GAMETUN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'La communauté gaming tunisienne 🇹🇳',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const _NeonDivider(),
                const SizedBox(height: 8),
                const Text(
                  'Trouve tes joueurs. Crée ton équipe. Joue ensemble.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const Spacer(flex: 4),
                // Panneau en verre avec les actions.
                GTFadeIn(
                  delay: const Duration(milliseconds: 220),
                  child: GtCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GtButton(
                        label: 'CRÉER UN COMPTE',
                        icon: Icons.person_add_alt_1,
                        onPressed: () => context.push('/register'),
                      ),
                      const SizedBox(height: 12),
                      GtOutlineButton(
                        label: 'SE CONNECTER',
                        icon: Icons.login,
                        onPressed: () => context.push('/login'),
                      ),
                      const SizedBox(height: 12),
                      _GoogleButton(
                        loading: state.loading,
                        onTap: () => ref
                            .read(authControllerProvider.notifier)
                            .loginWithGoogle(),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(state.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.danger, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
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

/// Fin liseré néon dégradé (accent LED).
class _NeonDivider extends StatelessWidget {
  const _NeonDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 2,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Colors.transparent,
          AppColors.primary,
          AppColors.magenta,
          Colors.transparent,
        ]),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 8),
        ],
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
      borderRadius: BorderRadius.circular(GT.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(GT.rMd),
        onTap: loading ? null : onTap,
        child: Container(
          height: 52,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}
