import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gt_scaffold.dart';
import 'cb_card_art.dart';
import 'cb_data.dart';
import 'cb_engine.dart';
import 'cb_models.dart';

/// TCG GameTun — bataille de cartes en lignes, joueur contre IA.
class CardBattleScreen extends StatefulWidget {
  const CardBattleScreen({super.key});

  @override
  State<CardBattleScreen> createState() => _CardBattleScreenState();
}

class _CardBattleScreenState extends State<CardBattleScreen> {
  CbGame? _game;
  int _difficulty = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAMETUN TCG'),
        actions: [
          if (_game != null)
            IconButton(
              tooltip: 'Nouvelle partie',
              onPressed: () => setState(() => _game = null),
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GtBackground(
        child: SafeArea(
          child: _game == null ? _buildHeroSelect() : _CbBattle(game: _game!),
        ),
      ),
    );
  }

  Widget _buildHeroSelect() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text('Choisis ton héros',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Chaque héros a un deck et des pouvoirs uniques',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        _difficultySelector(),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: CbData.heroes.map(_heroCard).toList(),
        ),
      ],
    );
  }

  Widget _difficultySelector() {
    const labels = ['Facile', 'Normal', 'Difficile'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final sel = _difficulty == i;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: sel,
            onSelected: (_) => setState(() => _difficulty = i),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surfaceAlt,
            labelStyle: TextStyle(
                color: sel ? Colors.white : AppColors.textSecondary),
          ),
        );
      }),
    );
  }

  Widget _heroCard(CbHero h) {
    return GestureDetector(
      onTap: () => _startGame(h),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: h.element.color, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: h.element.color.withValues(alpha: 0.35), blurRadius: 16),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: HeroArt(hero: h)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(h.icon, color: Colors.white, size: 22),
                        const Spacer(),
                        Text('${h.element.emoji} ${h.hp}❤',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const Spacer(),
                    Text(h.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    Text(h.faction,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 8),
                    _tag('PASSIF', h.passiveText),
                    const SizedBox(height: 6),
                    _tag('ACTIF (${h.activeCost})', h.activeText),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
          Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 10.5)),
        ],
      ),
    );
  }

  void _startGame(CbHero player) {
    final others = CbData.heroes.where((h) => h.id != player.id).toList();
    final ai = others[Random().nextInt(others.length)];
    setState(() {
      _game = CbGame(playerHero: player, aiHero: ai, difficulty: _difficulty);
    });
  }
}

// ===========================================================================
// Écran de bataille
// ===========================================================================

class _CbBattle extends StatefulWidget {
  final CbGame game;
  const _CbBattle({required this.game});

  @override
  State<_CbBattle> createState() => _CbBattleState();
}

class _CbBattleState extends State<_CbBattle> {
  CbGame get g => widget.game;

  int? _selectedHand; // carte sélectionnée dans la main
  bool _targeting = false; // en attente d'une cible (sort)
  bool _heroTargeting = false; // en attente d'une cible (pouvoir héros)
  bool _aiThinking = false;

  bool get _myTurn => g.turnSide == 0 && !g.gameOver && !_aiThinking;

  // ---- Interactions ------------------------------------------------------

  void _onHandTap(int index) {
    if (!_myTurn) return;
    final c = g.hand[0][index];
    if (!g.canPlay(0, c)) {
      _flash('Pas assez d\'énergie');
      return;
    }
    if (c.type == CbType.artifact) {
      setState(() {
        g.playArtifact(0, index);
        _clearSelection();
      });
      return;
    }
    if (c.type == CbType.spell) {
      if (g.needsTarget(c)) {
        setState(() {
          _selectedHand = index;
          _targeting = true;
          _heroTargeting = false;
        });
      } else {
        setState(() {
          g.playSpell(0, index, 1, -1);
          _clearSelection();
          _afterPlayerAction();
        });
      }
      return;
    }
    // Créature / structure : sélection puis choix de ligne.
    setState(() {
      _selectedHand = (_selectedHand == index) ? null : index;
      _targeting = false;
      _heroTargeting = false;
    });
  }

  void _onLaneTap(int side, int lane) {
    if (!_myTurn) return;
    // Cibler avec un sort (unités ennemies uniquement).
    if (_targeting && _selectedHand != null) {
      if (side != 1 || g.board[side][lane] == null) return;
      setState(() {
        g.playSpell(0, _selectedHand!, side, lane);
        _clearSelection();
        _afterPlayerAction();
      });
      return;
    }
    // Cibler avec le pouvoir du héros.
    if (_heroTargeting) {
      final tSide = g.heroTargetSide(0);
      if (tSide == null || tSide != side || g.board[side][lane] == null) return;
      setState(() {
        g.heroActive(0, side, lane);
        _clearSelection();
        _afterPlayerAction();
      });
      return;
    }
    // Poser une unité sur MA ligne libre.
    if (_selectedHand != null && side == 0) {
      setState(() {
        g.playUnit(0, _selectedHand!, lane);
        _clearSelection();
      });
    }
  }

  void _onHeroPower() {
    if (!_myTurn || !g.canUseHero) return;
    final tSide = g.heroTargetSide(0);
    if (tSide == null) {
      // Sans cible (Nerek, Lysara).
      setState(() {
        g.heroActive(0, 0, -1);
        _clearSelection();
        _afterPlayerAction();
      });
    } else {
      setState(() {
        _heroTargeting = true;
        _targeting = false;
        _selectedHand = null;
      });
    }
  }

  void _clearSelection() {
    _selectedHand = null;
    _targeting = false;
    _heroTargeting = false;
  }

  void _afterPlayerAction() {
    if (g.gameOver) _showEnd();
  }

  Future<void> _endTurn() async {
    if (!_myTurn) return;
    setState(_clearSelection);
    g.finishTurn(0);
    setState(() {});
    if (g.gameOver) return _showEnd();
    setState(() => _aiThinking = true);
    g.startTurn(1);
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    // L'IA joue ses cartes une par une.
    var guard = 0;
    while (!g.gameOver && g.aiStep() && guard++ < 30) {
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 620));
    }
    if (!g.gameOver) {
      await Future.delayed(const Duration(milliseconds: 300));
      g.finishTurn(1);
      if (mounted) setState(() {});
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!g.gameOver) g.startTurn(0);
    if (!mounted) return;
    setState(() => _aiThinking = false);
    if (g.gameOver) _showEnd();
  }

  void _flash(String t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t), duration: const Duration(milliseconds: 900)),
    );
  }

  void _showEnd() {
    final won = g.winner == 0;
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
              Text(won ? '🏆' : '💀', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(won ? 'VICTOIRE !' : 'DÉFAITE',
                  style: TextStyle(
                      color: won ? AppColors.gold : AppColors.danger,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                won
                    ? 'Tu as vaincu ${g.aiHero.name} !'
                    : '${g.aiHero.name} t\'a battu. Réessaie !',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // retour à la sélection
                },
                child: const Text('Rejouer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Rendu -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _heroBar(1), // IA en haut
        const SizedBox(height: 6),
        _boardRow(1),
        const SizedBox(height: 6),
        _turnBanner(),
        const SizedBox(height: 6),
        _boardRow(0),
        const SizedBox(height: 6),
        _heroBar(0),
        const Divider(height: 12, color: AppColors.stroke),
        Expanded(child: _hand()),
      ],
    );
  }

  Widget _turnBanner() {
    final txt = _aiThinking
        ? '${g.aiHero.name} réfléchit…'
        : (_targeting || _heroTargeting)
            ? 'Choisis une cible'
            : _myTurn
                ? 'À toi de jouer'
                : '…';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(txt,
          style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _heroBar(int side) {
    final h = g.hero(side);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: h.element.gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: g.turnSide == side ? Colors.white : Colors.transparent,
            width: 2),
      ),
      child: Row(
        children: [
          Icon(h.icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(h.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              Text(h.faction,
                  style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
          const Spacer(),
          _pill(Icons.favorite, '${g.hp[side]}', Colors.white),
          if (g.heroShield[side] > 0) ...[
            const SizedBox(width: 6),
            _pill(Icons.shield, '${g.heroShield[side]}', Colors.white),
          ],
          const SizedBox(width: 6),
          _pill(Icons.bolt, '${g.energy[side]}/${g.maxEnergy[side]}',
              Colors.white),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String txt, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(txt,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _boardRow(int side) {
    // Cible possible ? (sort ou pouvoir héros en attente).
    final canTarget = (_targeting && side == 1) ||
        (_heroTargeting && g.heroTargetSide(0) == side);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(kLanes, (lane) {
          final u = g.board[side][lane];
          final placeable = side == 0 &&
              _selectedHand != null &&
              !_targeting &&
              !_heroTargeting &&
              u == null &&
              (g.hand[0][_selectedHand!].type == CbType.creature ||
                  g.hand[0][_selectedHand!].type == CbType.structure);
          final highlight =
              placeable || (canTarget && u != null);
          return Expanded(
            child: GestureDetector(
              onTap: () => _onLaneTap(side, lane),
              child: Container(
                height: 96,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: highlight
                        ? AppColors.gold
                        : AppColors.stroke,
                    width: highlight ? 2 : 1,
                  ),
                ),
                child: u == null
                    ? Center(
                        child: Icon(
                          placeable ? Icons.add : Icons.circle_outlined,
                          color: placeable
                              ? AppColors.gold
                              : AppColors.stroke,
                          size: placeable ? 22 : 12,
                        ),
                      )
                    : _unitWidget(side, u),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _unitWidget(int side, CbUnit u) {
    final atk = g.atkOf(side, u);
    final canAtk = !u.isStructure && u.canAttack && u.frozen == 0;
    return Container(
      decoration: BoxDecoration(
        gradient: u.def.element.gradient,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: canAtk && side == 0
              ? Colors.white
              : u.def.element.color,
          width: canAtk && side == 0 ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(u.def.icon, color: Colors.white, size: 15),
              const Spacer(),
              if (u.shield > 0)
                _mini(Icons.shield, '${u.shield}', Colors.white),
              if (u.frozen > 0)
                const Icon(Icons.ac_unit, color: Colors.white, size: 13),
              if (u.burn > 0)
                const Icon(Icons.local_fire_department,
                    color: Colors.orangeAccent, size: 13),
            ],
          ),
          Text(u.def.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  height: 1.05)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!u.isStructure)
                _statBadge('$atk', AppColors.gold)
              else
                const SizedBox(width: 18),
              _statBadge('${u.health}', AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String v, Color c) {
    return Container(
      width: 20,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c, width: 1),
      ),
      child: Text(v,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }

  Widget _mini(IconData i, String v, Color c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(i, size: 11, color: c),
          Text(v, style: TextStyle(color: c, fontSize: 10)),
        ],
      );

  Widget _hand() {
    return Column(
      children: [
        // Barre d'action.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _actionButton(
                icon: g.hero(0).icon,
                label: 'Pouvoir (${g.hero(0).activeCost})',
                color: AppColors.primary,
                enabled: _myTurn && g.canUseHero,
                onTap: _onHeroPower,
              ),
              const SizedBox(width: 8),
              if (_targeting || _heroTargeting)
                _actionButton(
                  icon: Icons.close,
                  label: 'Annuler',
                  color: AppColors.danger,
                  enabled: true,
                  onTap: () => setState(_clearSelection),
                )
              else
                _actionButton(
                  icon: Icons.skip_next,
                  label: _aiThinking ? 'IA…' : 'Fin du tour',
                  color: AppColors.green,
                  enabled: _myTurn,
                  onTap: _endTurn,
                ),
            ],
          ),
        ),
        Expanded(
          child: g.hand[0].isEmpty
              ? const Center(
                  child: Text('Main vide',
                      style: TextStyle(color: AppColors.textMuted)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  itemCount: g.hand[0].length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _handCard(i),
                ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _handCard(int index) {
    final c = g.hand[0][index];
    final selected = _selectedHand == index;
    final affordable = g.canPlay(0, c);
    final cost = g.effectiveCost(0, c);
    return GestureDetector(
      onTap: () => _onHandTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 118,
        transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.gold : c.rarity.color,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 14),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: CardArt(card: c)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
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
                            color:
                                affordable ? AppColors.cyan : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: Text('$cost',
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
                    const SizedBox(height: 2),
                    Expanded(
                      child: Text(c.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                    Row(
                      children: [
                        Text(_typeLabel(c.type),
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (c.type == CbType.creature ||
                            c.type == CbType.structure) ...[
                          if (c.type == CbType.creature)
                            _statBadge('${c.attack}', AppColors.gold),
                          const SizedBox(width: 3),
                          _statBadge('${c.health}', AppColors.danger),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(CbType t) => switch (t) {
        CbType.creature => 'CRÉATURE',
        CbType.spell => 'SORT',
        CbType.structure => 'STRUCTURE',
        CbType.artifact => 'ARTEFACT',
      };
}
