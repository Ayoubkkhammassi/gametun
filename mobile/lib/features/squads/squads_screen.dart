import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_anim.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import 'squad_repository.dart';
import 'create_squad_screen.dart';
import 'squad_detail_screen.dart';

class SquadsScreen extends ConsumerStatefulWidget {
  const SquadsScreen({super.key});

  @override
  ConsumerState<SquadsScreen> createState() => _SquadsScreenState();
}

class _SquadsScreenState extends ConsumerState<SquadsScreen> {
  bool _discover = false;
  Future<List<Squad>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = ref.read(squadRepositoryProvider).list(discover: _discover);
    });
  }

  Future<void> _join(Squad s) async {
    try {
      await ref.read(squadRepositoryProvider).join(s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tu as rejoint "${s.name}"')),
        );
      }
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GtBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('SQUAD',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
            const Text('Crée ou rejoins une équipe',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            _Tabs(
              discover: _discover,
              onChanged: (v) {
                setState(() => _discover = v);
                _reload();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _reload(),
                child: FutureBuilder<List<Squad>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: GTLoader());
                    }
                    if (snap.hasError) {
                      return GTErrorState(
                        message:
                            'Impossible de charger les squads. Vérifie ta connexion.',
                        onRetry: _reload,
                      );
                    }
                    final squads = snap.data ?? [];
                    if (squads.isEmpty) {
                      return GTEmptyState(
                        icon: Icons.groups_rounded,
                        message: _discover
                            ? 'Aucune squad ouverte pour l\'instant.'
                            : 'Tu n\'as pas encore de squad.\nCrée la tienne !',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: squads.length,
                      itemBuilder: (_, i) => GTFadeIn(
                        delay: Duration(milliseconds: 60 * i),
                        child: _SquadCard(
                          squad: squads[i],
                          showJoin: _discover,
                          onJoin: () => _join(squads[i]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GtButton(
                label: 'CRÉER UNE SQUAD',
                icon: Icons.add,
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => const CreateSquadScreen()),
                  );
                  if (created == true) {
                    setState(() => _discover = false);
                    _reload();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _Tabs extends StatelessWidget {
  final bool discover;
  final ValueChanged<bool> onChanged;
  const _Tabs({required this.discover, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab('MES SQUADS', !discover, () => onChanged(false)),
          _tab('DÉCOUVRIR', discover, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : AppColors.stroke,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  final Squad squad;
  final bool showJoin;
  final VoidCallback onJoin;
  const _SquadCard({
    required this.squad,
    required this.showJoin,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final full = squad.memberCount >= squad.maxPlayers;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GtCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SquadDetailScreen(squadId: squad.id),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.groups, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(squad.name,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    '${squad.gameName} • ${squad.memberCount}/${squad.maxPlayers} joueurs',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  Text(
                    '${squad.mode} • ${squad.requiredLevel}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (showJoin)
              TextButton(
                onPressed: full ? null : onJoin,
                child: Text(full ? 'Complète' : 'Rejoindre'),
              ),
          ],
        ),
      ),
    );
  }
}
