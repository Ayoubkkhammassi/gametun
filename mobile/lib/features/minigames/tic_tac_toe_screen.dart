import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';

/// Tic-Tac-Toe jouable contre l'app (spec §12).
/// Le joueur est 'X', l'app est 'O'.
class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String> _board = List.filled(9, '');
  bool _playerTurn = true;
  String? _status;
  final _rng = Random();

  void _reset() {
    setState(() {
      _board = List.filled(9, '');
      _playerTurn = true;
      _status = null;
    });
  }

  void _play(int i) {
    if (_board[i].isNotEmpty || _status != null || !_playerTurn) return;
    setState(() {
      _board[i] = 'X';
      _playerTurn = false;
    });
    if (_checkEnd()) return;
    // Coup de l'app après un court délai.
    Future.delayed(const Duration(milliseconds: 350), _aiMove);
  }

  void _aiMove() {
    if (_status != null) return;
    final empty = <int>[];
    for (var i = 0; i < 9; i++) {
      if (_board[i].isEmpty) empty.add(i);
    }
    if (empty.isEmpty) return;

    // Stratégie simple : gagner si possible, sinon bloquer, sinon aléatoire.
    final move =
        _findWinning('O') ?? _findWinning('X') ?? empty[_rng.nextInt(empty.length)];
    setState(() {
      _board[move] = 'O';
      _playerTurn = true;
    });
    _checkEnd();
  }

  int? _findWinning(String mark) {
    for (final line in _lines) {
      final marks = line.map((i) => _board[i]).toList();
      if (marks.where((m) => m == mark).length == 2 &&
          marks.contains('')) {
        return line[marks.indexOf('')];
      }
    }
    return null;
  }

  bool _checkEnd() {
    final winner = _winner();
    if (winner != null) {
      setState(() => _status = winner == 'X' ? 'Tu as gagné ! 🎉' : 'L\'app a gagné 🤖');
      return true;
    }
    if (!_board.contains('')) {
      setState(() => _status = 'Match nul 🤝');
      return true;
    }
    return false;
  }

  String? _winner() {
    for (final line in _lines) {
      final a = _board[line[0]];
      if (a.isNotEmpty && a == _board[line[1]] && a == _board[line[2]]) {
        return a;
      }
    }
    return null;
  }

  static const _lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // lignes
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // colonnes
    [0, 4, 8], [2, 4, 6], // diagonales
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TIC-TAC-TOE')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  _status ?? (_playerTurn ? 'À toi de jouer (X)' : 'L\'app réfléchit...'),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: 9,
                    itemBuilder: (_, i) {
                      final mark = _board[i];
                      final markColor =
                          mark == 'X' ? AppColors.cyan : AppColors.magenta;
                      return GestureDetector(
                        onTap: () => _play(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            // Effet 3D : dégradé + ombres (relief).
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF201B33), Color(0xFF120F1E)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: mark.isEmpty
                                    ? AppColors.stroke
                                    : markColor.withValues(alpha: 0.6),
                                width: 1.5),
                            boxShadow: [
                              // Ombre portée (bas-droite) → profondeur.
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              // Reflet (haut-gauche) → relief.
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.04),
                                offset: const Offset(-3, -3),
                                blurRadius: 6,
                              ),
                              if (mark.isNotEmpty)
                                BoxShadow(
                                  color: markColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              mark,
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: markColor,
                                shadows: [
                                  Shadow(
                                      color: markColor.withValues(alpha: 0.8),
                                      blurRadius: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
                if (_status != null)
                  GtButton(label: 'REJOUER', onPressed: _reset),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
