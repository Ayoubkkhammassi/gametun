import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_avatar.dart';
import '../../core/widgets/gt_scaffold.dart';

final pendingRequestsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/premium/requests');
  return (data as List).cast<Map<String, dynamic>>();
});

/// Écran ADMIN : valider/refuser les paiements Premium D17.
class AdminPremiumScreen extends ConsumerWidget {
  const AdminPremiumScreen({super.key});

  Future<void> _act(
      BuildContext context, WidgetRef ref, String id, bool approve) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/premium/requests/$id/${approve ? 'approve' : 'reject'}');
      ref.invalidate(pendingRequestsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(approve ? 'Premium activé ✅' : 'Demande refusée')));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('DEMANDES PREMIUM')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingRequestsProvider),
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Erreur : $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ]),
              data: (items) {
                if (items.isEmpty) {
                  return ListView(children: const [
                    Padding(
                      padding: EdgeInsets.all(40),
                      child: Text('Aucune demande en attente. 🎉',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    final user = (r['user'] ?? {}) as Map<String, dynamic>;
                    return GtCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GtAvatar(
                                avatarUrl: user['avatarUrl'] as String?,
                                pseudo: (user['pseudo'] ?? '?') as String,
                                radius: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text((user['pseudo'] ?? '?') as String,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700)),
                                    Text((user['email'] ?? '') as String,
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              const Icon(Icons.receipt_long,
                                  size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Réf D17 : ${r['reference'] ?? ''}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _act(
                                      context, ref, r['id'] as String, false),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(
                                          color: AppColors.stroke)),
                                  child: const Text('Refuser'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _act(
                                      context, ref, r['id'] as String, true),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Valider'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.green),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
