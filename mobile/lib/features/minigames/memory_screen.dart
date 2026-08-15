import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';

/// Jeu de Mémoire (remplace Puissance 4) : retrouve les paires d'emojis gaming.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  static const _icons = ['🎮', '🕹️', '👾', '🎯', '🏆', '⚡', '🔥', '💎'];
  late List<String> _cards;
  late List<bool> _revealed;
  late List<bool> _matched;
  int? _first;
  int _moves = 0;
  int _pairs = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final deck = [..._icons, ..._icons]..shuffle();
    setState(() {
      _cards = deck;
      _revealed = List.filled(deck.length, false);
      _matched = List.filled(deck.length, false);
      _first = null;
      _moves = 0;
      _pairs = 0;
      _busy = false;
    });
  }

  void _flip(int i) {
    if (_busy || _revealed[i] || _matched[i]) return;
    setState(() => _revealed[i] = true);

    if (_first == null) {
      _first = i;
      return;
    }

    _moves++;
    final first = _first!;
    if (_cards[first] == _cards[i]) {
      // Paire trouvée.
      setState(() {
        _matched[first] = true;
        _matched[i] = true;
        _pairs++;
        _first = null;
      });
    } else {
      // Mauvaise paire : on retourne après un court délai.
      _busy = true;
      Timer(const Duration(milliseconds: 800), () {
        setState(() {
          _revealed[first] = false;
          _revealed[i] = false;
          _first = null;
          _busy = false;
        });
      });
    }
  }

  bool get _won => _pairs == _icons.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JEU DE MÉMOIRE')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _stat('Coups', '$_moves', AppColors.cyan),
                    _stat('Paires', '$_pairs/${_icons.length}',
                        AppColors.green),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _won
                      ? _buildWin()
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: _cards.length,
                          itemBuilder: (_, i) => _buildCard(i),
                        ),
                ),
                if (!_won) ...[
                  const SizedBox(height: 12),
                  GtOutlineButton(
                      label: 'RECOMMENCER', onPressed: _newGame),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 26, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildCard(int i) {
    final show = _revealed[i] || _matched[i];
    return GestureDetector(
      onTap: () => _flip(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: show ? null : AppColors.primaryGradient,
          color: show
              ? (_matched[i]
                  ? AppColors.green.withValues(alpha: 0.18)
                  : AppColors.surfaceAlt)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _matched[i] ? AppColors.green : AppColors.stroke),
        ),
        child: Center(
          child: Text(
            show ? _cards[i] : '',
            style: const TextStyle(fontSize: 34),
          ),
        ),
      ),
    );
  }

  Widget _buildWin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: AppColors.gold, size: 72),
          const SizedBox(height: 16),
          const Text('Bravo ! 🎉',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Terminé en $_moves coups',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: GtButton(label: 'REJOUER', onPressed: _newGame),
          ),
        ],
      ),
    );
  }
}
