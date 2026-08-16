import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_avatar.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../../core/widgets/premium_badge.dart';
import '../profiles/user_profile_screen.dart';
import 'social_repository.dart';

/// « Qui m'a liké » : le compte est toujours visible, mais les identités
/// ne sont dévoilées qu'aux abonnés Premium.
class LikedMeScreen extends ConsumerStatefulWidget {
  const LikedMeScreen({super.key});

  @override
  ConsumerState<LikedMeScreen> createState() => _LikedMeScreenState();
}

class _LikedMeScreenState extends ConsumerState<LikedMeScreen> {
  LikedMeResult? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(socialRepositoryProvider).likedMe();
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUI T\'A LIKÉ 💚')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _centered(_error!)
                    : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    if (d.count == 0) {
      return _centered(
          'Personne ne t\'a liké pour l\'instant. Continue à jouer et à matcher !');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          d.count == 1
              ? '1 personne t\'a liké'
              : '${d.count} personnes t\'ont liké',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (!d.isPremium)
          _buildBlurredTeaser(d.count)
        else
          ...d.users.map(_buildUserTile),
      ],
    );
  }

  /// Version gratuite : avatars floutés + incitation à passer Premium.
  Widget _buildBlurredTeaser(int count) {
    return Column(
      children: [
        // Faux aperçu flouté.
        ...List.generate(count.clamp(1, 4), (_) => _blurredRow()),
        const SizedBox(height: 16),
        GtCard(
          child: Column(
            children: [
              const PremiumBadge(size: 26),
              const SizedBox(height: 10),
              const Text('Débloque qui t\'a liké',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Passe Premium pour voir toutes les personnes qui t\'ont liké et leur profil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => showPremiumUpsell(context,
                      title: 'Voir qui t\'a liké',
                      message:
                          'Réservé au Premium 💎 — découvre qui craque pour toi.'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Débloquer'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blurredRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  width: 70,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6)),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildUserTile(DiscoverProfileLite u) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GtCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: u.id)),
        ),
        child: Row(
          children: [
            GtAvatar(
                avatarUrl: u.avatarUrl,
                pseudo: u.pseudo,
                radius: 24,
                online: u.isOnline),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(u.pseudo,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700)),
                  ),
                  if (u.isPremium) ...[
                    const SizedBox(width: 6),
                    const PremiumBadge(size: 14),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _centered(String text) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      );
}
