import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_scaffold.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/conversations_screen.dart';
import '../../notifications/notifications_screen.dart';
import '../../update/app_update.dart';

// Empêche d'afficher la popup de mise à jour plusieurs fois par session.
bool _updatePromptShown = false;

/// Accueil (réf. mockup) : salutation, carte héro, menu principal.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _goToTab(WidgetRef ref, int index) {
    ref.read(selectedTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final pseudo = user?.pseudo ?? 'joueur';

    // Vérifie s'il existe une mise à jour et propose de la télécharger.
    ref.listen(appUpdateProvider, (_, next) {
      next.whenData((info) {
        if (info != null && !_updatePromptShown) {
          _updatePromptShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) showUpdateDialog(context, info);
          });
        }
      });
    });

    return GtBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // En-tête marque GameTun (réf. mockup).
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 14),
                    ],
                  ),
                  child: const Icon(Icons.sports_esports,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.magentaGradient.createShader(b),
                  child: const Text('GameTun',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
                const Spacer(),
                _CircleIcon(
                  icon: Icons.chat_bubble_outline,
                  onTap: () => _push(context, const ConversationsScreen()),
                ),
                const SizedBox(width: 10),
                _CircleIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => _push(context, const NotificationsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Salut $pseudo ! 👋',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Prêt à jouer ?',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            GtCard(
              gradient: AppColors.heroGradient,
              padding: const EdgeInsets.all(22),
              onTap: () => _goToTab(ref, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trouve tes coéquipiers compatibles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Smart Match',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.bolt, color: AppColors.cyan, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Que veux-tu faire ?',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            _MenuTile(
              icon: Icons.person_search,
              title: 'GAME MATCH',
              subtitle: 'Trouver des joueurs',
              gradient: AppColors.primaryGradient,
              onTap: () => _goToTab(ref, 2),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.favorite,
              title: 'SOCIAL MATCH',
              subtitle: 'Découvrir des joueurs',
              gradient: AppColors.magentaGradient,
              onTap: () => _goToTab(ref, 1),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.groups,
              title: 'SQUAD',
              subtitle: 'Créer ou rejoindre une équipe',
              gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              onTap: () => _goToTab(ref, 3),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.sports_esports,
              title: 'PLAY',
              subtitle: 'Jouer à des mini-jeux',
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)]),
              onTap: () => _goToTab(ref, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GtCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
