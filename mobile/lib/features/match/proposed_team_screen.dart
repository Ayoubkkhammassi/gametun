import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import 'match_repository.dart';

/// Écran « ÉQUIPE TROUVÉE » (réf. mockup) : l'équipe proposée par Smart Match.
class ProposedTeamScreen extends ConsumerStatefulWidget {
  final List<RankedPlayer> team;
  final int averageCompatibility;
  const ProposedTeamScreen({
    super.key,
    required this.team,
    required this.averageCompatibility,
  });

  @override
  ConsumerState<ProposedTeamScreen> createState() => _ProposedTeamScreenState();
}

class _ProposedTeamScreenState extends ConsumerState<ProposedTeamScreen> {
  final Set<String> _invited = {};
  bool _loading = false;

  Future<void> _joinGroup() async {
    setState(() => _loading = true);
    try {
      // Envoie une demande de coéquipier à chaque membre proposé.
      for (final p in widget.team) {
        await ref.read(matchRepositoryProvider).accept(p.id);
        _invited.add(p.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitations envoyées à l\'équipe ! 🎉')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ÉQUIPE TROUVÉE 🎉')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                '${widget.averageCompatibility}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('Compatibilité de l\'équipe',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: widget.team.length,
                  itemBuilder: (_, i) {
                    final p = widget.team[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GtCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.surfaceAlt,
                              child: Text(
                                p.pseudo.isNotEmpty
                                    ? p.pseudo[0].toUpperCase()
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
                                  Text(p.pseudo,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700)),
                                  Text('Niveau : ${p.level}',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('${p.compatibility}%',
                                style: const TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GtButton(
                  label: 'REJOINDRE LE GROUPE',
                  icon: Icons.group_add,
                  loading: _loading,
                  onPressed: _joinGroup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
