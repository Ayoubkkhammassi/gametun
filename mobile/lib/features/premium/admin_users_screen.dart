import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_exception.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_avatar.dart';
import '../../core/widgets/gt_scaffold.dart';

/// Écran ADMIN : gérer tous les comptes (statut, premium).
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(apiClientProvider).get('/admin/users',
          query: _search.isEmpty ? null : {'search': _search});
      _users = (data as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/admin/users/$id/status', body: {'status': status});
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _togglePremium(String id, bool value) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/admin/users/$id/premium', body: {'isPremium': value});
      await _load();
    } catch (_) {}
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':
        return AppColors.green;
      case 'SUSPENDED':
        return AppColors.gold;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GÉRER LES COMPTES')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un pseudo ou email...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  ),
                  onSubmitted: (v) {
                    _search = v.trim();
                    _load();
                  },
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: _users.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final u = _users[i];
                            final status = (u['status'] ?? 'ACTIVE') as String;
                            final isPremium = u['isPremium'] == true;
                            final isAdmin = u['role'] == 'ADMIN';
                            return GtCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GtAvatar(
                                        avatarUrl: u['avatarUrl'] as String?,
                                        pseudo: (u['pseudo'] ?? '?') as String,
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Flexible(
                                                child: Text(
                                                    (u['pseudo'] ?? '?')
                                                        as String,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: AppColors
                                                            .textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                              if (isPremium)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 6),
                                                  child: Icon(Icons.star,
                                                      color: AppColors.gold,
                                                      size: 14),
                                                ),
                                              if (isAdmin)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                      left: 6),
                                                  child: Icon(
                                                      Icons.shield,
                                                      color: AppColors.cyan,
                                                      size: 14),
                                                ),
                                            ]),
                                            Text((u['email'] ?? '') as String,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(status,
                                            style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  if (!isAdmin) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        if (status == 'ACTIVE') ...[
                                          _ActionChip(
                                            label: 'Suspendre',
                                            color: AppColors.gold,
                                            onTap: () => _setStatus(
                                                u['id'] as String,
                                                'SUSPENDED'),
                                          ),
                                          _ActionChip(
                                            label: 'Bannir',
                                            color: AppColors.danger,
                                            onTap: () => _setStatus(
                                                u['id'] as String, 'BANNED'),
                                          ),
                                        ] else
                                          _ActionChip(
                                            label: 'Réactiver',
                                            color: AppColors.green,
                                            onTap: () => _setStatus(
                                                u['id'] as String, 'ACTIVE'),
                                          ),
                                        _ActionChip(
                                          label: isPremium
                                              ? 'Retirer Premium'
                                              : 'Offrir Premium',
                                          color: AppColors.primary,
                                          onTap: () => _togglePremium(
                                              u['id'] as String, !isPremium),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
