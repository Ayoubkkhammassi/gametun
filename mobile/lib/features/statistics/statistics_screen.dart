import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';

final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/statistics');
  return data as Map<String, dynamic>;
});

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statisticsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('STATISTIQUES')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erreur : $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            data: (s) {
              final rep = (s['reputation'] ?? {}) as Map<String, dynamic>;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatTile(
                          label: 'Matchs joués',
                          value: '${s['matchesPlayed'] ?? 0}',
                          color: AppColors.primary),
                      _StatTile(
                          label: 'Win Rate',
                          value: '${s['winRate'] ?? 0}%',
                          color: AppColors.green),
                      _StatTile(
                          label: 'Connexions',
                          value: '${s['connections'] ?? 0}',
                          color: AppColors.cyan),
                      _StatTile(
                          label: 'Squads',
                          value: '${s['squadsJoined'] ?? 0}',
                          color: AppColors.magenta),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GtCard(
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.gold),
                        const SizedBox(width: 12),
                        const Text('Réputation',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const Spacer(),
                        Text(
                          '${(rep['score'] ?? 0).toStringAsFixed(1)} ★  (${rep['count'] ?? 0})',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GtCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
