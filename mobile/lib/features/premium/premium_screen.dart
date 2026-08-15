import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';

final premiumPlansProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/premium/plans');
  return data as Map<String, dynamic>;
});

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _loading = false;

  Future<void> _subscribe() async {
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).post('/premium/subscribe');
      // Le statut Premium sera reflété au prochain chargement du profil.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bienvenue Premium ⭐')),
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
    final async = ref.watch(premiumPlansProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('PREMIUM')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erreur : $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            data: (plans) {
              final premium = plans['premium'] as Map<String, dynamic>;
              final features =
                  (premium['features'] as List).map((e) => e.toString()).toList();
              final price = premium['priceTnd'];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Center(
                    child: Icon(Icons.workspace_premium,
                        color: AppColors.gold, size: 56),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('Deviens Premium',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Débloque toutes les fonctionnalités avancées',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GtCard(
                    border: Border.all(color: AppColors.gold, width: 1.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...features.map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.gold, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(f,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary)),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 28),
                        Center(
                          child: Text(
                            '$price TND / mois',
                            style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 22,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text('Annulable à tout moment',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GtButton(
                    label: 'PASSER PREMIUM',
                    icon: Icons.star,
                    gradient: AppColors.goldGradient,
                    loading: _loading,
                    onPressed: _subscribe,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GameTun ne vend jamais d\'avantage de triche en jeu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
