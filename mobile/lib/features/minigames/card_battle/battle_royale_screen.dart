import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_scaffold.dart';
import 'cb_data.dart';
import 'cb_models.dart';

/// GameTun Battle Royale — jeu de cartes en arène circulaire : 6 joueurs,
/// chacun avec des PV, jouent des cartes pour s'attaquer. Dernier survivant gagne.
class BattleRoyaleScreen extends StatefulWidget {
  const BattleRoyaleScreen({super.key});

  @override
  State<BattleRoyaleScreen> createState() => _BattleRoyaleScreenState();
}

class _BattleRoyaleScreenState extends State<BattleRoyaleScreen>
    with TickerProviderStateMixin {
  static const int _startHp = 800;
  static const int _handSize = 6;
  static const List<String> _botNames = [
    'Rakan', 'Nyxia', 'Vesper', 'Koda', 'Zara', 'Milo', 'Aria', 'Draven',
    'Senna', 'Orin',
  ];

  final _rng = Random();
  late List<_BrPlayer> _players;
  late List<CbCard> _deck;
  final List<CbCard> _hand = [];
  int _energy = 3;
  int _round = 1;
  int? _selectedCard;
  bool _busy = false;
  bool _started = false;
  String? _turnLabel;
  final Map<int, String> _floating = {};
  final Set<int> _pulsing = {}; // nœuds en train d'encaisser un coup

  // Animations.
  late final AnimationController _projCtrl;
  late final AnimationController _shakeCtrl;
  double _arena = 0;
  Offset? _projFrom, _projTo;
  Color _projColor = AppColors.danger;

  _BrPlayer get _me => _players.firstWhere((p) => p.isHuman);
  List<_BrPlayer> get _alive => _players.where((p) => p.alive).toList();

  @override
  void initState() {
    super.initState();
    _projCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360))
      ..addListener(() => setState(() {}));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _projCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final names = [..._botNames]..shuffle(_rng);
    final elements = [...CbElement.values]..shuffle(_rng);
    _players = [
      _BrPlayer(0, 'Toi', CbElement.lumiere, isHuman: true, hp: _startHp),
      for (var i = 0; i < 5; i++)
        _BrPlayer(i + 1, names[i], elements[i % elements.length], hp: _startHp),
    ];
    _deck = _buildDeck();
    _hand.clear();
    for (var i = 0; i < _handSize; i++) {
      _hand.add(_draw());
    }
    _energy = 3;
    _round = 1;
    _selectedCard = null;
    _busy = false;
    _turnLabel = 'À toi de jouer';
    setState(() => _started = true);
  }

  List<CbCard> _buildDeck() {
    final pool = CbData.cards
        .where((c) => c.type == CbType.creature || c.type == CbType.spell)
        .toList();
    final deck = <CbCard>[];
    for (var i = 0; i < 3; i++) {
      deck.addAll(pool);
    }
    deck.shuffle(_rng);
    return deck;
  }

  CbCard _draw() {
    if (_deck.isEmpty) _deck = _buildDeck();
    return _deck.removeLast();
  }

  // ---- Sémantique d'une carte --------------------------------------------

  _BrKind _kind(CbCard c) {
    if (c.type == CbType.spell) {
      if (c.spellFx == SpellFx.damageAllEnemies) return _BrKind.aoe;
      if (c.spellFx == SpellFx.freezeOne) return _BrKind.stun;
      return _BrKind.attack;
    }
    if (c.keywords.contains(Kw.shield)) return _BrKind.shield;
    if (c.keywords.contains(Kw.healHeroOnAttack) ||
        c.keywords.contains(Kw.healAlliesEot)) {
      return _BrKind.heal;
    }
    return _BrKind.attack;
  }

  int _power(CbCard c) {
    final base = c.attack > 0 ? c.attack : c.spellValue;
    return base * 50;
  }

  bool _needsTarget(CbCard c) {
    final k = _kind(c);
    return k == _BrKind.attack || k == _BrKind.stun;
  }

  // ---- Interactions ------------------------------------------------------

  void _tapCard(int i) {
    if (_busy) return;
    final c = _hand[i];
    if (c.cost > _energy) {
      _snack('Pas assez d\'énergie');
      return;
    }
    if (_needsTarget(c)) {
      setState(() => _selectedCard = (_selectedCard == i) ? null : i);
    } else {
      _playCard(i, _me);
    }
  }

  void _tapPlayer(_BrPlayer target) {
    if (_busy || _selectedCard == null) return;
    if (!target.alive || target.isHuman) return;
    _playCard(_selectedCard!, target);
  }

  Future<void> _playCard(int handIndex, _BrPlayer target) async {
    final c = _hand[handIndex];
    if (c.cost > _energy || _busy) return;
    setState(() {
      _busy = true;
      _energy -= c.cost;
      _hand.removeAt(handIndex);
      _selectedCard = null;
    });
    await _animateAndResolve(_me, c, target);
    _hand.add(_draw());
    if (mounted) setState(() => _busy = false);
    _checkEnd();
  }

  Future<void> _animateAndResolve(
      _BrPlayer src, CbCard c, _BrPlayer target) async {
    final k = _kind(c);
    switch (k) {
      case _BrKind.attack:
      case _BrKind.stun:
        await _projectile(src.id, target.id,
            k == _BrKind.stun ? AppColors.cyan : src.element.color);
        _resolve(src, c, target);
        _hit(target.id);
        break;
      case _BrKind.aoe:
        await _shake();
        _resolve(src, c, src);
        for (final p in _players) {
          if (p.alive && p.id != src.id) _hit(p.id);
        }
        break;
      case _BrKind.shield:
      case _BrKind.heal:
        _resolve(src, c, src);
        _hit(src.id);
        break;
    }
    if (mounted) setState(() {});
  }

  void _resolve(_BrPlayer src, CbCard c, _BrPlayer target) {
    switch (_kind(c)) {
      case _BrKind.attack:
        _dealDamage(target, _power(c));
        break;
      case _BrKind.aoe:
        for (final p in _players) {
          if (p.alive && p.id != src.id) _dealDamage(p, _power(c));
        }
        break;
      case _BrKind.stun:
        target.stunned = true;
        _float(target.id, '💤');
        break;
      case _BrKind.shield:
        src.shield += _power(c);
        _float(src.id, '+🛡${_power(c)}');
        break;
      case _BrKind.heal:
        src.hp = min(_startHp, src.hp + _power(c));
        _float(src.id, '+${_power(c)}');
        break;
    }
  }

  void _dealDamage(_BrPlayer p, int amount) {
    var dmg = amount;
    if (p.shield > 0) {
      final a = min(p.shield, dmg);
      p.shield -= a;
      dmg -= a;
    }
    p.hp -= dmg;
    _float(p.id, '-$amount');
    if (p.hp <= 0) {
      p.hp = 0;
      p.alive = false;
    }
  }

  void _float(int pid, String txt) {
    _floating[pid] = txt;
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted && _floating[pid] == txt) {
        setState(() => _floating.remove(pid));
      }
    });
  }

  void _hit(int pid) {
    _pulsing.add(pid);
    Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _pulsing.remove(pid));
    });
  }

  Future<void> _projectile(int fromPid, int toPid, Color color) async {
    if (_arena <= 0) return;
    _projFrom = _posOf(fromPid);
    _projTo = _posOf(toPid);
    _projColor = color;
    _projCtrl.reset();
    await _projCtrl.forward();
    _projFrom = null;
    _projTo = null;
    await _shake();
  }

  Future<void> _shake() async {
    _shakeCtrl.reset();
    await _shakeCtrl.forward();
  }

  // ---- Fin de tour + IA --------------------------------------------------

  Future<void> _endTurn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _selectedCard = null;
    });
    for (final bot in _players.where((p) => !p.isHuman)) {
      if (!bot.alive) continue;
      if (bot.stunned) {
        bot.stunned = false;
        setState(() => _turnLabel = '${bot.name} est immobilisé');
        await Future.delayed(const Duration(milliseconds: 350));
        continue;
      }
      if (_alive.length <= 1) break;
      setState(() => _turnLabel = 'Tour de ${bot.name}');
      await Future.delayed(const Duration(milliseconds: 350));
      await _botPlay(bot);
      _checkEnd();
      if (_gameEnded) return;
      await Future.delayed(const Duration(milliseconds: 250));
    }
    _round++;
    _energy = min(10, 2 + _round);
    if (_hand.length < _handSize) _hand.add(_draw());
    if (mounted) {
      setState(() {
        _busy = false;
        _turnLabel = 'À toi de jouer';
      });
    }
  }

  Future<void> _botPlay(_BrPlayer bot) async {
    var botEnergy = min(10, 2 + _round);
    final plays = 1 + _rng.nextInt(2);
    for (var n = 0; n < plays; n++) {
      final card = CbData.cards[_rng.nextInt(CbData.cards.length)];
      final playable = (card.type == CbType.creature ||
              card.type == CbType.spell) &&
          card.cost <= botEnergy;
      if (!playable) continue;
      botEnergy -= card.cost;
      final k = _kind(card);
      if (k == _BrKind.attack || k == _BrKind.stun) {
        final targets = _players
            .where((p) => p.alive && p.id != bot.id)
            .toList()
          ..sort((a, b) => a.hp.compareTo(b.hp));
        if (targets.isEmpty) return;
        final target = _rng.nextDouble() < 0.55
            ? targets.first
            : targets[_rng.nextInt(targets.length)];
        await _animateAndResolve(bot, card, target);
      } else {
        await _animateAndResolve(bot, card, bot);
      }
      if (_alive.length <= 1) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  bool get _gameEnded => _alive.length <= 1;

  void _checkEnd() {
    if (!_gameEnded) return;
    final winner = _alive.isNotEmpty ? _alive.first : null;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted) _showEnd(winner);
    });
  }

  void _showEnd(_BrPlayer? winner) {
    final iWon = winner != null && winner.isHuman;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(iWon ? '👑' : '☠', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(iWon ? 'VICTOIRE ROYALE !' : 'ÉLIMINÉ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: iWon ? AppColors.gold : AppColors.danger,
                      fontSize: 24,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                iWon
                    ? 'Tu es le dernier survivant !'
                    : 'Vainqueur : ${winner?.name ?? '—'}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _start();
                },
                child: const Text('Rejouer'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Quitter',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t), duration: const Duration(milliseconds: 800)),
      );

  // ---- Géométrie de l'arène ----------------------------------------------

  /// Position (centre du nœud) d'un joueur dans l'arène carrée [_arena].
  Offset _posOf(int pid) {
    final s = _arena;
    final center = Offset(s / 2, s / 2);
    final radius = s * 0.36;
    // 6 emplacements, "Toi" (pid 0) en bas.
    final slot = pid; // pid 0..5 -> slot 0..5
    final angle = pi / 2 + slot * (2 * pi / 6);
    return center + Offset(cos(angle) * radius, sin(angle) * radius);
  }

  // ---- Rendu -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BATTLE ROYALE'),
        actions: [
          if (_started)
            IconButton(onPressed: _start, icon: const Icon(Icons.refresh)),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(child: _started ? _buildGame() : _buildIntro()),
      ),
    );
  }

  Widget _buildIntro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('GameTun Battle Royale',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text(
              '6 joueurs entrent dans l\'arène. Joue tes cartes pour attaquer '
              'les autres, protège-toi, et sois le dernier survivant.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ENTRER DANS L\'ARÈNE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Manche $_round · ${_turnLabel ?? ''}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(child: _arenaView()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _pill(Icons.bolt, 'Énergie $_energy', AppColors.cyan),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _endTurn,
                icon: const Icon(Icons.skip_next, size: 18),
                label: Text(_busy ? 'IA…' : 'Fin du tour'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            itemCount: _hand.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _handCard(i),
          ),
        ),
      ],
    );
  }

  Widget _arenaView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final s = min(constraints.maxWidth, constraints.maxHeight);
        _arena = s;
        // Décalage de tremblement.
        final shakeT = _shakeCtrl.value;
        final dx = shakeT > 0 && shakeT < 1
            ? sin(shakeT * pi * 6) * 6 * (1 - shakeT)
            : 0.0;
        const node = 66.0;
        return Center(
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: SizedBox(
              width: s,
              height: s,
              child: Stack(
                children: [
                  // Anneau central (arène).
                  Center(
                    child: Container(
                      width: s * 0.5,
                      height: s * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.primary.withValues(alpha: 0.18),
                          Colors.transparent,
                        ]),
                        border: Border.all(
                            color: AppColors.stroke, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.emoji_events,
                            color: AppColors.gold, size: 30),
                      ),
                    ),
                  ),
                  // Nœuds joueurs.
                  for (final p in _players)
                    Positioned(
                      left: _posOf(p.id).dx - node / 2,
                      top: _posOf(p.id).dy - node / 2,
                      width: node,
                      child: _playerNode(p),
                    ),
                  // Projectile.
                  if (_projFrom != null && _projTo != null)
                    _buildProjectile(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectile() {
    final t = _projCtrl.value;
    final pos = Offset.lerp(_projFrom!, _projTo!, Curves.easeIn.transform(t))!;
    return Positioned(
      left: pos.dx - 10,
      top: pos.dy - 10,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _projColor,
          boxShadow: [
            BoxShadow(color: _projColor, blurRadius: 14, spreadRadius: 2),
          ],
        ),
      ),
    );
  }

  Widget _playerNode(_BrPlayer p) {
    final selecting = _selectedCard != null && p.alive && !p.isHuman;
    final hpPct = (p.hp / _startHp).clamp(0.0, 1.0);
    final pulsing = _pulsing.contains(p.id);
    return GestureDetector(
      onTap: () => _tapPlayer(p),
      child: Opacity(
        opacity: p.alive ? 1 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: p.isHuman ? AppColors.gold : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            const SizedBox(height: 2),
            AnimatedScale(
              scale: pulsing ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 130),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: p.element.gradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selecting
                            ? AppColors.gold
                            : (p.isHuman ? Colors.white : p.element.color),
                        width: selecting ? 3 : 2,
                      ),
                      boxShadow: [
                        if (selecting)
                          BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.6),
                              blurRadius: 12),
                        if (pulsing)
                          BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.8),
                              blurRadius: 16),
                      ],
                    ),
                    child: Icon(p.alive ? Icons.person : Icons.close,
                        color: Colors.white, size: 24),
                  ),
                  if (_floating[p.id] != null)
                    Positioned(
                      top: -18,
                      child: Text(_floating[p.id]!,
                          style: TextStyle(
                              color: _floating[p.id]!.startsWith('-')
                                  ? AppColors.danger
                                  : AppColors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4)
                              ])),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hpPct,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation(
                    hpPct > 0.5
                        ? AppColors.green
                        : hpPct > 0.25
                            ? AppColors.gold
                            : AppColors.danger,
                  ),
                ),
              ),
            ),
            Text(p.shield > 0 ? '${p.hp} 🛡${p.shield}' : '${p.hp}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String txt, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(txt,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _handCard(int i) {
    final c = _hand[i];
    final k = _kind(c);
    final selected = _selectedCard == i;
    final affordable = c.cost <= _energy && !_busy;
    return GestureDetector(
      onTap: () => _tapCard(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 112,
        transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
        decoration: BoxDecoration(
          gradient: c.element.gradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.gold : c.rarity.color,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: affordable ? AppColors.cyan : AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${c.cost}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12)),
                ),
                const Spacer(),
                Icon(c.icon, color: Colors.white, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(c.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    height: 1.05)),
            const Spacer(),
            _kindBadge(k, c),
          ],
        ),
      ),
    );
  }

  Widget _kindBadge(_BrKind k, CbCard c) {
    final (label, icon, color) = switch (k) {
      _BrKind.attack => ('DÉGÂTS ${_power(c)}', Icons.gps_fixed, AppColors.danger),
      _BrKind.aoe => ('ZONE ${_power(c)}', Icons.blur_on, AppColors.magenta),
      _BrKind.stun => ('STUN', Icons.ac_unit, AppColors.cyan),
      _BrKind.shield => ('BOUCLIER ${_power(c)}', Icons.shield, AppColors.gold),
      _BrKind.heal => ('SOIN ${_power(c)}', Icons.healing, AppColors.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 8.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

enum _BrKind { attack, aoe, stun, shield, heal }

class _BrPlayer {
  final int id;
  final String name;
  final CbElement element;
  final bool isHuman;
  int hp;
  int shield = 0;
  bool alive = true;
  bool stunned = false;

  _BrPlayer(this.id, this.name, this.element,
      {this.isHuman = false, required this.hp});
}
