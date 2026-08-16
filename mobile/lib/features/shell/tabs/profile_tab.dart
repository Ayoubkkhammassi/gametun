import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_button.dart';
import '../../../core/widgets/gt_scaffold.dart';
import '../../../core/widgets/gt_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/conversations_screen.dart';
import '../../statistics/statistics_screen.dart';
import '../../premium/premium_screen.dart';
import '../../premium/admin_premium_screen.dart';
import '../../premium/admin_users_screen.dart';
import '../../profiles/profile_edit_screen.dart';
import '../../settings/security_screen.dart';

/// Profil (réf. mockup) : avatar, pseudo, région, statut Premium, déconnexion.
/// Données réelles issues de l'utilisateur authentifié (API /users/me).
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return GtBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Center(
              child: Text(
                'PROFIL',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar + pseudo
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _push(context, const ProfileEditScreen()),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: GtAvatar(
                        avatarUrl: user?.avatarUrl,
                        pseudo: user?.pseudo ?? '?',
                        radius: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.pseudo ?? '—',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🇹🇳 ${user?.region ?? 'Tunisie'}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _InfoRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: user?.email ?? '—',
            ),
            _InfoRow(
              icon: Icons.language,
              label: 'Langue',
              value: user?.language ?? 'FR',
            ),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Tranche d\'âge',
              value: user?.ageGroup ?? '—',
            ),
            _InfoRow(
              icon: Icons.workspace_premium,
              label: 'Statut',
              value: (user?.isPremium ?? false) ? 'Premium ⭐' : 'Gratuit',
              valueColor:
                  (user?.isPremium ?? false) ? AppColors.gold : null,
            ),
            const SizedBox(height: 24),
            _MenuLink(
              icon: Icons.edit_outlined,
              label: 'Modifier mon profil (photo, jeux…)',
              onTap: () => _push(context, const ProfileEditScreen()),
            ),
            _MenuLink(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              onTap: () => _push(context, const ConversationsScreen()),
            ),
            _MenuLink(
              icon: Icons.bar_chart,
              label: 'Statistiques',
              onTap: () => _push(context, const StatisticsScreen()),
            ),
            _MenuLink(
              icon: Icons.sports_esports,
              label: 'Mini-jeux',
              onTap: () =>
                  ref.read(selectedTabProvider.notifier).state = 4,
            ),
            _MenuLink(
              icon: Icons.workspace_premium,
              label: 'Premium',
              color: AppColors.gold,
              onTap: () => _push(context, const PremiumScreen()),
            ),
            if (user?.role == 'ADMIN') ...[
              _MenuLink(
                icon: Icons.admin_panel_settings,
                label: 'Demandes Premium (Admin)',
                color: AppColors.cyan,
                onTap: () => _push(context, const AdminPremiumScreen()),
              ),
              _MenuLink(
                icon: Icons.manage_accounts,
                label: 'Gérer les comptes (Admin)',
                color: AppColors.cyan,
                onTap: () => _push(context, const AdminUsersScreen()),
              ),
            ],
            _MenuLink(
              icon: Icons.shield_outlined,
              label: 'Sécurité & confidentialité',
              onTap: () => _push(context, const SecurityScreen()),
            ),
            const SizedBox(height: 20),
            GtButton(
              label: 'DÉCONNEXION',
              icon: Icons.logout,
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
              ),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
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
            Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: color ?? AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GtCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
