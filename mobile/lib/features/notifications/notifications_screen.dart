import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  NotificationItem(this.id, this.type, this.title, this.body, this.isRead,
      this.createdAt);
  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        j['id'] as String,
        (j['type'] ?? 'SYSTEM') as String,
        j['title'] as String,
        j['body'] as String,
        (j['isRead'] ?? false) as bool,
        DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  final data = await ref.read(apiClientProvider).get('/notifications');
  final items = (data as Map<String, dynamic>)['items'] as List;
  return items
      .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Rafraîchit les notifications toutes seules.
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 15),
      (_) => ref.invalidate(notificationsProvider),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsProvider);
    }
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  IconData _icon(String type) {
    switch (type) {
      case 'NEW_MATCH':
        return Icons.favorite;
      case 'NEW_MESSAGE':
        return Icons.chat_bubble;
      case 'COMPATIBLE_PLAYER':
        return Icons.person_search;
      case 'SQUAD_ALMOST_FULL':
        return Icons.groups;
      case 'PREMIUM':
        return Icons.workspace_premium;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('NOTIFICATIONS')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(notificationsProvider.future),
            child: async.when(
              skipLoadingOnReload: true,
              skipLoadingOnRefresh: true,
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
                      child: Text('Aucune notification pour l\'instant.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ]);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return GtCard(
                      color: n.isRead ? AppColors.card : AppColors.surfaceAlt,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icon(n.type),
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(n.body,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                  color: AppColors.magenta,
                                  shape: BoxShape.circle),
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
