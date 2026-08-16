import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_avatar.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../../core/widgets/premium_badge.dart';

/// Profil public d'un joueur (ouvert depuis le chat, une squad, etc.).
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await ref.read(apiClientProvider).get('/users/${widget.userId}');
      setState(() => _user = data as Map<String, dynamic>);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROFIL')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppColors.textSecondary)))
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final u = _user!;
    final profile = (u['profile'] ?? {}) as Map<String, dynamic>;
    final stats = (u['statistics'] ?? {}) as Map<String, dynamic>;
    final games = (u['games'] ?? []) as List;
    final matches = stats['matchesPlayed'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final winRate = matches > 0 ? ((wins / matches) * 100).round() : 0;
    final rep = (profile['reputationScore'] ?? 0).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              GtAvatar(
                avatarUrl: u['avatarUrl'] as String?,
                pseudo: (u['pseudo'] ?? '?') as String,
                radius: 48,
                online: u['isOnline'] == true,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text((u['pseudo'] ?? '—') as String,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (u['isPremium'] == true) ...[
                    const SizedBox(width: 6),
                    const PremiumBadge(size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('🇹🇳 ${u['region'] ?? 'Tunisie'} • ${u['ageGroup'] ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                  '${profile['level'] ?? 'BEGINNER'} • ${profile['playStyle'] ?? 'CASUAL'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _stat('$matches', 'Matchs', AppColors.primary),
            _stat('$winRate%', 'Win Rate', AppColors.green),
            _stat('$rep ★', 'Réputation', AppColors.gold),
          ],
        ),
        if ((profile['bio'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('À propos',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 8),
          GtCard(
              child: Text(profile['bio'] as String,
                  style: const TextStyle(color: AppColors.textSecondary))),
        ],
        if (games.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Jeux favoris',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: games.map((g) {
              final name = (g as Map<String, dynamic>)['name'] ?? '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Text('$name',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
              );
            }).toList(),
          ),
        ],
        ..._buildPlayerCard(profile),
      ],
    );
  }

  /// Sections « carte joueur » : galerie, infos, genres, langues, prompts.
  List<Widget> _buildPlayerCard(Map<String, dynamic> profile) {
    final photos =
        ((profile['photoUrls'] ?? []) as List).map((e) => e.toString()).toList();
    final genres = ((profile['favoriteGenres'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    final languages = ((profile['spokenLanguages'] ?? []) as List)
        .map((e) => e.toString())
        .toList();
    final funFacts = (profile['funFacts'] ?? []) as List;
    final platform = profile['platform']?.toString();
    final rank = profile['rank']?.toString();
    final playerType = profile['playerType']?.toString();
    final hasMic = profile['hasMic'] == true;
    final years = (profile['yearsExperience'] ?? 0) as int;

    final infoChips = <Widget>[
      if (platform != null && platform.isNotEmpty)
        _infoChip(Icons.videogame_asset, platform),
      if (rank != null && rank.isNotEmpty) _infoChip(Icons.military_tech, rank),
      if (playerType != null && playerType.isNotEmpty)
        _infoChip(Icons.person, playerType),
      if (hasMic) _infoChip(Icons.mic, 'Micro'),
      if (years > 0) _infoChip(Icons.timeline, '$years an${years > 1 ? 's' : ''}'),
    ];

    return [
      if (photos.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('Photos'),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(photos[i],
                  width: 110, height: 110, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                        width: 110,
                        height: 110,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.broken_image,
                            color: AppColors.textMuted),
                      )),
            ),
          ),
        ),
      ],
      if (infoChips.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('Infos joueur'),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: infoChips),
      ],
      if (genres.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('Genres préférés'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((g) => _tag(g)).toList(),
        ),
      ],
      if (languages.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('Langues'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((l) => _tag(l)).toList(),
        ),
      ],
      if (funFacts.isNotEmpty) ...[
        const SizedBox(height: 20),
        _sectionTitle('À propos en plus'),
        const SizedBox(height: 10),
        ...funFacts.map((f) {
          final m = f as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GtCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['question']?.toString() ?? '',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(m['answer']?.toString() ?? '',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }),
      ],
    ];
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15));

  Widget _tag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Text(text,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
      );

  Widget _infoChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.cyan),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      );

  Widget _stat(String value, String label, Color color) {
    return Expanded(
      child: GtCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
