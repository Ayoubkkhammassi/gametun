import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/gt_button.dart';
import '../../core/widgets/gt_scaffold.dart';
import '../auth/application/auth_controller.dart';
import 'game_socket.dart';

/// Mini-jeu à 2 en temps réel (Tic-Tac-Toe ou Puissance 4) partagé via WebSocket.
/// roomId = id de la conversation (les deux amis rejoignent la même room).
class MultiplayerGameScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String game; // 'tic-tac-toe' | 'connect-four'
  final String title;
  const MultiplayerGameScreen({
    super.key,
    required this.roomId,
    required this.game,
    required this.title,
  });

  @override
  ConsumerState<MultiplayerGameScreen> createState() =>
      _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState
    extends ConsumerState<MultiplayerGameScreen> {
  final _socket = GameSocket();
  List<int> _board = [];
  int _turn = 1;
  int _winner = 0;
  List<Map<String, dynamic>> _players = [];
  bool _connected = false;

  bool get _isC4 => widget.game == 'connect-four';
  bool get _isRps => widget.game == 'rock-paper-scissors';
  int get _cols => _isC4 ? 7 : 3;

  int? get _mySymbol {
    final myId = ref.read(authControllerProvider).user?.id;
    for (final p in _players) {
      if (p['userId'] == myId) return p['symbol'] as int;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final token = await ref.read(tokenStorageProvider).accessToken;
    if (token == null) return;
    _socket.connect(token);
    _socket.onState((data) {
      final state = data['state'] as Map<String, dynamic>;
      setState(() {
        _board = (state['board'] as List).map((e) => e as int).toList();
        _turn = state['turn'] as int;
        _winner = state['winner'] as int;
        _players = ((data['players'] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _connected = true;
      });
    });
    // Petit délai pour laisser la connexion s'établir avant de rejoindre.
    await Future.delayed(const Duration(milliseconds: 400));
    _socket.join(widget.roomId, widget.game);
  }

  void _play(int index) {
    final mine = _mySymbol;
    if (mine == null || _winner != 0 || _turn != mine) return;
    _socket.move(widget.roomId, widget.game, index);
  }

  void _reset() => _socket.reset(widget.roomId, widget.game);

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: !_connected || _board.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatus(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Center(
                          child: _isRps
                              ? _buildRps()
                              : _isC4
                                  ? _buildConnectFour()
                                  : _buildTicTacToe(),
                        ),
                      ),
                      if (_winner != 0) ...[
                        const SizedBox(height: 12),
                        GtButton(label: 'REJOUER', onPressed: _reset),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final mine = _mySymbol;
    String text;
    if (_players.length < 2) {
      text = 'En attente d\'un 2ᵉ joueur...';
    } else if (_winner == 3) {
      text = 'Match nul 🤝';
    } else if (_winner != 0) {
      text = _winner == mine ? 'Tu as gagné ! 🎉' : 'Tu as perdu 🤖';
    } else if (mine == null) {
      text = 'Spectateur';
    } else {
      text = _turn == mine ? 'À toi de jouer !' : 'Au tour de l\'adversaire...';
    }
    return Column(
      children: [
        // Joueurs
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _players.map((p) {
            final sym = p['symbol'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _symbolColor(sym),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(p['pseudo'] as String,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Text(text,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Color _symbolColor(int v) {
    if (_isC4) {
      return v == 1 ? AppColors.danger : AppColors.gold;
    }
    return v == 1 ? AppColors.cyan : AppColors.magenta;
  }

  // ---- Tic-Tac-Toe -------------------------------------------------------

  Widget _buildTicTacToe() {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (_, i) {
          final v = _board[i];
          final markColor = _symbolColor(v);
          return GestureDetector(
            onTap: () => _play(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF201B33), Color(0xFF120F1E)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: v == 0
                        ? AppColors.stroke
                        : markColor.withValues(alpha: 0.6),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.04),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                  if (v != 0)
                    BoxShadow(
                        color: markColor.withValues(alpha: 0.35),
                        blurRadius: 16),
                ],
              ),
              child: Center(
                child: Text(
                  v == 0 ? '' : (v == 1 ? 'X' : 'O'),
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
    );
  }

  // ---- Pierre-Papier-Ciseaux --------------------------------------------

  Widget _buildRps() {
    const emojis = ['✊', '✋', '✌️'];
    const labels = ['Pierre', 'Papier', 'Ciseaux'];
    final me = _mySymbol ?? 1;
    final myChoice = me == 1 ? _board[0] : _board[1];
    final lastMine = me == 1 ? _board[4] : _board[5];
    final lastOpp = me == 1 ? _board[5] : _board[4];
    final scoreMine = me == 1 ? _board[2] : _board[3];
    final scoreOpp = me == 1 ? _board[3] : _board[2];
    final waiting = myChoice != -1 && _winner == 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _rpsScore('Toi', scoreMine, AppColors.green),
            const Text('VS',
                style: TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w800)),
            _rpsScore('Adversaire', scoreOpp, AppColors.magenta),
          ],
        ),
        const SizedBox(height: 30),
        // Dernier round révélé.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(lastMine >= 0 ? emojis[lastMine] : '❓',
                style: const TextStyle(fontSize: 56)),
            Text(lastOpp >= 0 ? emojis[lastOpp] : '❓',
                style: const TextStyle(fontSize: 56)),
          ],
        ),
        const SizedBox(height: 24),
        if (waiting)
          const Text('En attente de l\'adversaire...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16))
        else if (_winner == 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              return GestureDetector(
                onTap: () => _socket.move(widget.roomId, widget.game, i),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Center(
                          child: Text(emojis[i],
                              style: const TextStyle(fontSize: 38))),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i],
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _rpsScore(String label, int score, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('$score',
            style: TextStyle(
                color: color, fontSize: 34, fontWeight: FontWeight.w900)),
      ],
    );
  }

  // ---- Puissance 4 -------------------------------------------------------

  Widget _buildConnectFour() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < 6; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < _cols; c++)
                  GestureDetector(
                    onTap: () => _play(c),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cellColor(_board[r * 7 + c]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Color _cellColor(int v) {
    if (v == 0) return AppColors.surfaceAlt;
    return _symbolColor(v);
  }
}
