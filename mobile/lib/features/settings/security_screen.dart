import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../auth/application/auth_controller.dart';
import 'blocked_users_screen.dart';

/// Sécurité & confidentialité (spec §17).
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('SÉCURITÉ')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Row(
                icon: Icons.block,
                label: 'Utilisateurs bloqués',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const BlockedUsersScreen()),
                ),
              ),
              _Row(
                icon: Icons.privacy_tip_outlined,
                label: 'Paramètres de confidentialité',
                trailing: 'Ta date de naissance reste privée',
                onTap: () {},
              ),
              _Row(
                icon: Icons.verified_user_outlined,
                label: 'Vérification d\'âge',
                trailing: 'Activée',
                onTap: () {},
              ),
              _Row(
                icon: Icons.rule,
                label: 'Règles de la communauté',
                onTap: () => _showRules(context),
              ),
              _Row(
                icon: Icons.help_outline,
                label: 'Aide & Support',
                onTap: () {},
              ),
              const SizedBox(height: 24),
              GtCard(
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
                color: AppColors.danger.withValues(alpha: 0.12),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.4)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: AppColors.danger),
                    SizedBox(width: 10),
                    Text('DÉCONNEXION',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Règles de la communauté',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'GameTun est un espace gaming bienveillant :\n\n'
          '• Respecte les autres joueurs\n'
          '• Pas de harcèlement ni de haine\n'
          '• Orienté amitié et jeu, pas rencontres\n'
          '• Signale tout comportement abusif\n'
          '• Protection renforcée des mineurs',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GtCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textPrimary)),
            ),
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(
                      color: AppColors.green, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
