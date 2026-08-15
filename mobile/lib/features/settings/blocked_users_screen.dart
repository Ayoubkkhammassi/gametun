import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/users/me/blocked');
  return (data as List).cast<Map<String, dynamic>>();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('UTILISATEURS BLOQUÉS')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Erreur : $e',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            data: (users) {
              if (users.isEmpty) {
                return const Center(
                  child: Text('Aucun utilisateur bloqué.',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = users[i];
                  return GtCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.surfaceAlt,
                          child: Text(
                            (u['pseudo'] as String).isNotEmpty
                                ? (u['pseudo'] as String)[0].toUpperCase()
                                : '?',
                            style:
                                const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(u['pseudo'] as String,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref.read(apiClientProvider).post(
                                '/users/unblock',
                                body: {'userId': u['id']});
                            ref.invalidate(blockedUsersProvider);
                          },
                          child: const Text('Débloquer'),
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
    );
  }
}
