import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../games/games_repository.dart';
import 'match_repository.dart';
import 'proposed_team_screen.dart';

/// Écran Game Match (spec §6-7) : filtres + Smart Match + équipe proposée.
class GameMatchScreen extends ConsumerStatefulWidget {
  const GameMatchScreen({super.key});

  @override
  ConsumerState<GameMatchScreen> createState() => _GameMatchScreenState();
}

class _GameMatchScreenState extends ConsumerState<GameMatchScreen> {
  String? _gameSlug;
  String _mode = 'RANKED';
  String _level = 'INTERMEDIATE';
  String _language = 'FR';
  int _players = 4;

  bool _loading = false;
  String? _error;
  MatchSearchResult? _result;
  final Set<String> _handled = {}; // joueurs déjà acceptés/passés

  static const _modes = {
    'RANKED': 'Classé',
    'CASUAL': 'Décontracté',
    'COMPETITIVE': 'Compétitif',
    'CO_OP': 'Coopératif',
  };
  static const _levels = {
    'BEGINNER': 'Débutant',
    'INTERMEDIATE': 'Intermédiaire',
    'ADVANCED': 'Avancé',
    'EXPERT': 'Expert',
  };
  static const _languages = {'FR': 'Français', 'AR': 'العربية', 'EN': 'English'};

  Future<void> _search() async {
    if (_gameSlug == null) {
      setState(() => _error = 'Choisis un jeu.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(matchRepositoryProvider).search(
            gameSlugs: [_gameSlug!],
            mode: _mode,
            level: _level,
            language: _language,
            players: _players,
          );
      setState(() {
        _result = res;
        _handled.clear();
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(RankedPlayer p) async {
    setState(() => _handled.add(p.id));
    try {
      await ref.read(matchRepositoryProvider).accept(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demande envoyée à ${p.pseudo} ✅')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _handled.remove(p.id));
    }
  }

  Future<void> _pass(RankedPlayer p) async {
    setState(() => _handled.add(p.id));
    try {
      await ref.read(matchRepositoryProvider).pass(p.id);
    } catch (_) {
      if (mounted) setState(() => _handled.remove(p.id));
    }
  }

  void _viewTeam() {
    final res = _result;
    if (res == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProposedTeamScreen(
        team: res.proposedTeam,
        averageCompatibility: res.averageCompatibility,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(gamesCatalogProvider);

    return GtBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Center(
              child: Text(
                'GAME MATCH',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Trouve tes coéquipiers compatibles',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
            catalog.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                'Impossible de charger les jeux : $e',
                style: const TextStyle(color: AppColors.danger),
              ),
              data: (games) => _GameDropdown(
                games: games,
                value: _gameSlug,
                onChanged: (v) => setState(() => _gameSlug = v),
              ),
            ),
            const SizedBox(height: 14),
            _Selector(
              label: 'Mode',
              value: _mode,
              options: _modes,
              onChanged: (v) => setState(() => _mode = v),
            ),
            const SizedBox(height: 14),
            _Selector(
              label: 'Niveau',
              value: _level,
              options: _levels,
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 14),
            _Selector(
              label: 'Langue',
              value: _language,
              options: _languages,
              onChanged: (v) => setState(() => _language = v),
            ),
            const SizedBox(height: 14),
            _PlayersStepper(
              value: _players,
              onChanged: (v) => setState(() => _players = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 22),
            GtButton(
              label: 'LANCER LA RECHERCHE',
              icon: Icons.search,
              loading: _loading,
              onPressed: _search,
            ),
            if (_result != null) ...[
              const SizedBox(height: 28),
              _ResultsSection(
                result: _result!,
                handled: _handled,
                onAccept: _accept,
                onPass: _pass,
                onViewTeam: _viewTeam,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameDropdown extends StatelessWidget {
  final List<GameItem> games;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _GameDropdown({
    required this.games,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jeu',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: const Text('Choisir un jeu',
                  style: TextStyle(color: AppColors.textMuted)),
              dropdownColor: AppColors.surfaceAlt,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textMuted),
              style: const TextStyle(color: AppColors.textPrimary),
              items: games
                  .map((g) =>
                      DropdownMenuItem(value: g.slug, child: Text(g.name)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const _Selector({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((e) {
            final selected = e.key == value;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(e.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? Colors.transparent : AppColors.stroke),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PlayersStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _PlayersStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nombre de joueurs',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: value > 2 ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Center(
                  child: Text('$value',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: value < 10 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon,
            color: onTap == null ? AppColors.textMuted : AppColors.primary),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final MatchSearchResult result;
  final Set<String> handled;
  final void Function(RankedPlayer) onAccept;
  final void Function(RankedPlayer) onPass;
  final VoidCallback onViewTeam;

  const _ResultsSection({
    required this.result,
    required this.handled,
    required this.onAccept,
    required this.onPass,
    required this.onViewTeam,
  });

  @override
  Widget build(BuildContext context) {
    if (result.totalFound == 0) {
      return const GtCard(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Aucun joueur compatible pour l\'instant. Reviens plus tard ou '
            'élargis tes critères.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    final remaining =
        result.results.where((p) => !handled.contains(p.id)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '${result.averageCompatibility}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('Compatibilité de l\'équipe',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (result.proposedTeam.isNotEmpty) ...[
          GtButton(
            label: 'VOIR L\'ÉQUIPE PROPOSÉE',
            icon: Icons.groups,
            gradient: AppColors.magentaGradient,
            onPressed: onViewTeam,
          ),
          const SizedBox(height: 20),
        ],
        Text('${result.totalFound} joueurs trouvés',
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...remaining.map((p) => _PlayerRow(
              player: p,
              onAccept: () => onAccept(p),
              onPass: () => onPass(p),
            )),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final RankedPlayer player;
  final VoidCallback onAccept;
  final VoidCallback onPass;
  const _PlayerRow({
    required this.player,
    required this.onAccept,
    required this.onPass,
  });

  Color get _scoreColor {
    if (player.compatibility >= 90) return AppColors.green;
    if (player.compatibility >= 75) return AppColors.cyan;
    if (player.compatibility >= 50) return AppColors.gold;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GtCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.surfaceAlt,
                  child: Text(
                    player.pseudo.isNotEmpty
                        ? player.pseudo[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.pseudo,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Niveau : ${player.level}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  '${player.compatibility}%',
                  style: TextStyle(
                    color: _scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPass,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Passer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.stroke),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
