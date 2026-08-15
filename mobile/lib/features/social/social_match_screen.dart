import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';
import 'social_repository.dart';

/// Social Match (spec §10) : découverte de joueurs, orientée amitié/gaming.
class SocialMatchScreen extends ConsumerStatefulWidget {
  const SocialMatchScreen({super.key});

  @override
  ConsumerState<SocialMatchScreen> createState() => _SocialMatchScreenState();
}

class _SocialMatchScreenState extends ConsumerState<SocialMatchScreen> {
  List<DiscoverProfile>? _profiles;
  int _index = 0;
  bool _loading = true;
  String? _error;
  bool _acting = false;

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
      final list = await ref.read(socialRepositoryProvider).discover();
      setState(() {
        _profiles = list;
        _index = 0;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(String type) async {
    final profiles = _profiles;
    if (profiles == null || _index >= profiles.length || _acting) return;
    final profile = profiles[_index];
    setState(() => _acting = true);
    try {
      final res = await ref.read(socialRepositoryProvider).swipe(profile.id, type);
      if (res.matched && mounted) {
        await _showMatch(profile);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _acting = false;
          _index++;
        });
      }
    }
  }

  Future<void> _showMatch(DiscoverProfile p) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: GtCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.magentaGradient.createShader(b),
                child: const Text(
                  'MATCH !',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Icon(Icons.favorite, color: AppColors.magenta, size: 56),
              const SizedBox(height: 12),
              Text(
                'Toi et ${p.pseudo} êtes connectés !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Super !'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Détail complet du profil au tap (spec §10) + actions modération.
  Future<void> _showDetail(DiscoverProfile p) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(
                    p.pseudo.isNotEmpty ? p.pseudo[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p.pseudo}, ${p.ageGroup}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    Text('🇹🇳 ${p.region} • ${p.isOnline ? '🟢 En ligne' : 'Hors ligne'}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Niveau', value: p.level),
            _DetailRow(label: 'Style', value: p.playStyle),
            if (p.bio != null && p.bio!.isNotEmpty)
              _DetailRow(label: 'À propos', value: p.bio!),
            const SizedBox(height: 8),
            const Text('Jeux',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.games
                  .map((g) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _report(p);
                    },
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Signaler'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.stroke)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _block(p);
                    },
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Bloquer'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.stroke)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _report(DiscoverProfile p) async {
    try {
      await ref.read(apiClientProvider).post('/users/report',
          body: {'reportedUserId': p.id, 'reason': 'Signalé depuis Social Match'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${p.pseudo} a été signalé.')),
        );
      }
    } catch (_) {}
  }

  Future<void> _block(DiscoverProfile p) async {
    try {
      await ref.read(apiClientProvider).post('/users/block', body: {'userId': p.id});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${p.pseudo} a été bloqué.')),
        );
        setState(() => _index++);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GtBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('SOCIAL MATCH',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
            const Text('Découvre des joueurs',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _EmptyState(
        icon: Icons.wifi_off,
        message: _error!,
        actionLabel: 'Réessayer',
        onAction: _load,
      );
    }
    final profiles = _profiles ?? [];
    if (profiles.isEmpty || _index >= profiles.length) {
      return _EmptyState(
        icon: Icons.done_all,
        message: 'Plus de profils pour l\'instant. Reviens plus tard !',
        actionLabel: 'Actualiser',
        onAction: _load,
      );
    }

    final p = profiles[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showDetail(p),
              child: _ProfileCard(profile: p),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: AppColors.danger,
                onTap: _acting ? null : () => _act('PASS'),
              ),
              _ActionButton(
                icon: Icons.star,
                color: AppColors.gold,
                onTap: _acting ? null : () => _act('FAVORITE'),
              ),
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.green,
                onTap: _acting ? null : () => _act('LIKE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final DiscoverProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surfaceAlt,
            child: Text(
              profile.pseudo.isNotEmpty ? profile.pseudo[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${profile.pseudo}, ${profile.ageGroup}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('🇹🇳 ${profile.region}  •  ${profile.isOnline ? '🟢 En ligne' : 'Hors ligne'}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('Niveau : ${profile.level}  •  ${profile.playStyle}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(profile.bio!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white)),
          ],
          const SizedBox(height: 16),
          if (profile.games.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: profile.games
                  .take(4)
                  .map((g) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(g,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
