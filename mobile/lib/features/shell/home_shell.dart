import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import 'tabs/home_tab.dart';
import 'tabs/social_tab.dart';
import 'tabs/search_tab.dart';
import 'tabs/squad_tab.dart';
import 'tabs/profile_tab.dart';
import '../minigames/play_screen.dart';

/// Coquille principale avec navigation inférieure (spec §3) :
/// Accueil · Social · Recherche · Squad · Play · Profil.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeTab(),
    SocialTab(),
    SearchTab(),
    SquadTab(),
    PlayScreen(),
    ProfileTab(),
  ];

  static const _items = [
    (icon: Icons.home_rounded, label: 'Accueil'),
    (icon: Icons.favorite_rounded, label: 'Social'),
    (icon: Icons.search_rounded, label: 'Recherche'),
    (icon: Icons.groups_rounded, label: 'Squad'),
    (icon: Icons.sports_esports_rounded, label: 'Play'),
    (icon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == index;
                final item = _items[i];
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        ref.read(selectedTabProvider.notifier).state = i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 23,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
