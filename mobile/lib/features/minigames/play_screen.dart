import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_scaffold.dart';
import 'tic_tac_toe_screen.dart';
import 'memory_screen.dart';
import 'quiz_screen.dart';
import 'rps_screen.dart';
import 'reaction_screen.dart';

/// Onglet/écran PLAY (spec §12) : liste des mini-jeux.
class PlayScreen extends StatelessWidget {
  const PlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = <_MiniGame>[
      _MiniGame('Tic-Tac-Toe 3D', 'Solo ou à 2 avec un ami', Icons.grid_3x3,
          AppColors.primaryGradient, () => const TicTacToeScreen()),
      _MiniGame('Jeu de Mémoire', 'Retrouve les paires', Icons.style,
          AppColors.magentaGradient, () => const MemoryScreen()),
      _MiniGame('Quiz Game', 'Teste tes connaissances', Icons.quiz,
          const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)]),
          () => const QuizScreen()),
      _MiniGame('Pierre-Papier-Ciseaux', 'Le classique', Icons.back_hand,
          const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
          () => const RpsScreen()),
      _MiniGame('Reaction Time', 'Teste tes réflexes', Icons.bolt,
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          () => const ReactionScreen()),
    ];

    return GtBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Center(
              child: Text('PLAY',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
            const Center(
              child: Text('Joue à des mini-jeux',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 20),
            ...games.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GtCard(
                    onTap: g.builder == null
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => g.builder!()),
                            ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: g.gradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(g.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text(g.subtitle,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        if (g.builder != null)
                          const Icon(Icons.chevron_right,
                              color: AppColors.textMuted),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MiniGame {
  final String name;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Widget Function()? builder;
  _MiniGame(
      this.name, this.subtitle, this.icon, this.gradient, this.builder);
}
