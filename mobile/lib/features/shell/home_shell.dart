import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      bottomNavigationBar: _GlassNavBar(
        index: index,
        items: _items,
        onTap: (i) {
          HapticFeedback.selectionClick();
          ref.read(selectedTabProvider.notifier).state = i;
        },
      ),
    );
  }
}

/// Barre de navigation « glass » flottante : blur, transparence, indicateur
/// animé et icônes qui pulsent à la sélection.
class _GlassNavBar extends StatelessWidget {
  final int index;
  final List<({IconData icon, String label})> items;
  final ValueChanged<int> onTap;
  const _GlassNavBar({
    required this.index,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GT.rXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: GT.blurLg, sigmaY: GT.blurLg),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GT.rXl),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                border: Border.all(color: GT.glassStroke),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final selected = i == index;
                  final item = items[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: GT.normal,
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(GT.rMd),
                          gradient: selected
                              ? LinearGradient(colors: [
                                  AppColors.primary.withValues(alpha: 0.35),
                                  AppColors.magenta.withValues(alpha: 0.22),
                                ])
                              : null,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.5),
                                    blurRadius: 16,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: selected ? 1.18 : 1,
                              duration: GT.normal,
                              curve: Curves.easeOutBack,
                              child: Icon(
                                item.icon,
                                size: 23,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: selected
                                    ? Colors.white
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
      ),
    );
  }
}
