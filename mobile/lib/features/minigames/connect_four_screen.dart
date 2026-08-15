import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';

/// Puissance 4 jouable contre l'app (spec §12).
/// Grille 7 colonnes × 6 lignes. Joueur = 1 (rouge), App = 2 (jaune).
class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const _cols = 7;
  static const _rows = 6;
  late List<List<int>> _grid;
  bool _playerTurn = true;
  String? _status;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _grid = List.generate(_rows, (_) => List.filled(_cols, 0));
      _playerTurn = true;
      _status = null;
    });
  }

  int? _drop(int col, int player) {
    for (var r = _rows - 1; r >= 0; r--) {
      if (_grid[r][col] == 0) {
        _grid[r][col] = player;
        return r;
      }
    }
    return null; // colonne pleine
  }

  void _play(int col) {
    if (_status != null || !_playerTurn) return;
    final row = _drop(col, 1);
    if (row == null) return;
    setState(() => _playerTurn = false);
    if (_checkEnd(1)) return;
    Future.delayed(const Duration(milliseconds: 350), _aiMove);
  }

  void _aiMove() {
    if (_status != null) return;
    final valid = <int>[];
    for (var c = 0; c < _cols; c++) {
      if (_grid[0][c] == 0) valid.add(c);
    }
    if (valid.isEmpty) return;

    // Gagner si possible, sinon bloquer le joueur, sinon aléatoire.
    int? col = _findWinningCol(2) ?? _findWinningCol(1);
    col ??= valid[_rng.nextInt(valid.length)];

    _drop(col, 2);
    setState(() => _playerTurn = true);
    _checkEnd(2);
  }

  /// Cherche une colonne où `player` gagne (ou doit être bloqué) au prochain coup.
  int? _findWinningCol(int player) {
    for (var c = 0; c < _cols; c++) {
      if (_grid[0][c] != 0) continue;
      // Simule le coup.
      int? row;
      for (var r = _rows - 1; r >= 0; r--) {
        if (_grid[r][c] == 0) {
          row = r;
          break;
        }
      }
      if (row == null) continue;
      _grid[row][c] = player;
      final win = _isWin(player);
      _grid[row][c] = 0; // annule
      if (win) return c;
    }
    return null;
  }

  bool _checkEnd(int player) {
    if (_isWin(player)) {
      setState(() =>
          _status = player == 1 ? 'Tu as gagné ! 🎉' : 'L\'app a gagné 🤖');
      return true;
    }
    final full = _grid[0].every((c) => c != 0);
    if (full) {
      setState(() => _status = 'Match nul 🤝');
      return true;
    }
    return false;
  }

  bool _isWin(int p) {
    // Horizontales, verticales, diagonales.
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        if (_grid[r][c] != p) continue;
        if (c + 3 < _cols &&
            _grid[r][c + 1] == p &&
            _grid[r][c + 2] == p &&
            _grid[r][c + 3] == p) {
          return true;
        }
        if (r + 3 < _rows &&
            _grid[r + 1][c] == p &&
            _grid[r + 2][c] == p &&
            _grid[r + 3][c] == p) {
          return true;
        }
        if (r + 3 < _rows &&
            c + 3 < _cols &&
            _grid[r + 1][c + 1] == p &&
            _grid[r + 2][c + 2] == p &&
            _grid[r + 3][c + 3] == p) {
          return true;
        }
        if (r + 3 < _rows &&
            c - 3 >= 0 &&
            _grid[r + 1][c - 1] == p &&
            _grid[r + 2][c - 2] == p &&
            _grid[r + 3][c - 3] == p) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PUISSANCE 4')),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  _status ??
                      (_playerTurn ? 'À toi (🔴)' : 'L\'app joue... (🟡)'),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      children: [
                        for (var r = 0; r < _rows; r++)
                          Expanded(
                            child: Row(
                              children: [
                                for (var c = 0; c < _cols; c++)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _play(c),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _cellColor(_grid[r][c]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_status != null)
                  GtButton(label: 'REJOUER', onPressed: _reset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _cellColor(int v) {
    switch (v) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.gold;
      default:
        return AppColors.surfaceAlt;
    }
  }
}
