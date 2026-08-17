import 'dart:math';
import 'cb_data.dart';
import 'cb_models.dart';

const int kLanes = 4;
const int kMaxEnergy = 10;
const int kHandMax = 8;

/// Un événement de jeu (pour le journal / feedback visuel).
class CbEvent {
  final String text;
  CbEvent(this.text);
}

/// Moteur du TCG : état complet d'une partie 1v1 (joueur vs IA).
///
/// side 0 = joueur, side 1 = IA.
class CbGame {
  final CbHero playerHero;
  final CbHero aiHero;
  final int difficulty; // 0 facile, 1 normal, 2 difficile
  final _rng = Random();

  final List<int> hp = [30, 30];
  final List<int> heroShield = [0, 0];
  final List<int> energy = [0, 0];
  final List<int> maxEnergy = [0, 0];
  final List<int> fatigue = [0, 0];
  final List<bool> heroUsed = [false, false]; // capacité utilisée ce tour

  final List<List<CbCard>> deck = [[], []];
  final List<List<CbCard>> hand = [[], []];
  final List<List<CbUnit?>> board = [
    List.filled(kLanes, null),
    List.filled(kLanes, null),
  ];
  final List<Set<String>> artifacts = [{}, {}];

  int turnSide = 0; // à qui de jouer
  int turnCount = 0;
  bool gameOver = false;
  int? winner; // 0 joueur, 1 IA
  final List<CbEvent> log = [];

  CbGame({
    required this.playerHero,
    required this.aiHero,
    this.difficulty = 1,
  }) {
    hp[0] = playerHero.hp;
    hp[1] = aiHero.hp;
    deck[0] = _buildDeck(playerHero);
    deck[1] = _buildDeck(aiHero);
    // Main de départ.
    for (var i = 0; i < 3; i++) {
      _drawInitial(0);
      _drawInitial(1);
    }
    // Le joueur commence.
    startTurn(0);
  }

  List<CbCard> _buildDeck(CbHero h) {
    final d = h.deck.map((id) => CbData.card(id)).toList();
    d.shuffle(_rng);
    return d;
  }

  void _drawInitial(int side) {
    if (deck[side].isNotEmpty) hand[side].add(deck[side].removeLast());
  }

  CbHero hero(int side) => side == 0 ? playerHero : aiHero;

  // ---- Coûts / jouabilité ------------------------------------------------

  int effectiveCost(int side, CbCard c) {
    var cost = c.cost;
    // Lysara : sorts Verdant -1.
    if (hero(side).id == 'lysara' &&
        c.type == CbType.spell &&
        c.element == CbElement.verdant) {
      cost -= 1;
    }
    return max(0, cost);
  }

  bool canPlay(int side, CbCard c) => energy[side] >= effectiveCost(side, c);

  bool needsTarget(CbCard c) {
    if (c.type == CbType.spell) return c.spellFx != SpellFx.damageAllEnemies;
    return false;
  }

  /// Côté ciblé par la capacité du héros (0 allié, 1 ennemi, null = aucun).
  int? heroTargetSide(int side) {
    switch (hero(side).id) {
      case 'kaelyn':
      case 'zayden':
      case 'morvan':
        return 1 - side; // unité ennemie
      case 'orion':
        return side; // unité alliée
      default:
        return null; // nerek, lysara : pas de cible
    }
  }

  bool get canUseHero => !heroUsed[turnSide] && energy[turnSide] >= hero(turnSide).activeCost;

  /// Attaque effective d'une unité (auras passives + artefacts).
  int atkOf(int side, CbUnit u) {
    var a = u.attack;
    if (artifacts[side].contains('amulette_braise')) a += 1;
    if (hero(side).id == 'kaelyn' &&
        u.def.element == CbElement.braise &&
        u.def.type == CbType.creature) {
      a += 1;
    }
    final rushBonus = hero(side).id == 'zayden' ||
        artifacts[side].contains('coeur_tonnerre');
    if (rushBonus && u.has(Kw.rush)) a += 1;
    return max(0, a);
  }

  bool laneFree(int side, int lane) => board[side][lane] == null;
  int? firstFreeLane(int side) {
    for (var i = 0; i < kLanes; i++) {
      if (board[side][i] == null) return i;
    }
    return null;
  }

  // ---- Actions du joueur -------------------------------------------------

  bool playUnit(int side, int handIndex, int lane) {
    final c = hand[side][handIndex];
    if (c.type != CbType.creature && c.type != CbType.structure) return false;
    if (!canPlay(side, c) || !laneFree(side, lane)) return false;
    energy[side] -= effectiveCost(side, c);
    hand[side].removeAt(handIndex);
    final u = CbUnit(c);
    board[side][lane] = u;
    _emit('${_who(side)} invoque ${c.name}');
    return true;
  }

  bool playArtifact(int side, int handIndex) {
    final c = hand[side][handIndex];
    if (c.type != CbType.artifact || !canPlay(side, c)) return false;
    energy[side] -= effectiveCost(side, c);
    hand[side].removeAt(handIndex);
    artifacts[side].add(c.id);
    _emit('${_who(side)} active ${c.name}');
    return true;
  }

  /// Joue un sort. [tSide]/[tLane] = cible unité, ou tLane=-1 pour le héros.
  bool playSpell(int side, int handIndex, int tSide, int tLane) {
    final c = hand[side][handIndex];
    if (c.type != CbType.spell || !canPlay(side, c)) return false;
    energy[side] -= effectiveCost(side, c);
    hand[side].removeAt(handIndex);
    _emit('${_who(side)} lance ${c.name}');
    // Perle des Flots : soigne 2 PV quand on joue un sort.
    if (artifacts[side].contains('perle_flots')) _healHero(side, 2);
    _applySpell(side, c, tSide, tLane);
    _checkDeaths();
    return true;
  }

  void _applySpell(int side, CbCard c, int tSide, int tLane) {
    switch (c.spellFx!) {
      case SpellFx.damageOne:
        final u = _unitAt(tSide, tLane);
        if (u != null) _damageUnit(side, tSide, tLane, c.spellValue);
        break;
      case SpellFx.damageAllEnemies:
        final enemy = 1 - side;
        for (var i = 0; i < kLanes; i++) {
          if (board[enemy][i] != null) {
            _damageUnit(side, enemy, i, c.spellValue);
          }
        }
        break;
      case SpellFx.freezeOne:
        final u = _unitAt(tSide, tLane);
        if (u != null) {
          u.frozen = c.spellValue;
          _emit('${u.def.name} est immobilisé');
        }
        break;
      case SpellFx.chain:
        if (_unitAt(tSide, tLane) != null) {
          _damageUnit(side, tSide, tLane, c.spellValue);
          for (final adj in [tLane - 1, tLane + 1]) {
            if (adj >= 0 && adj < kLanes && board[tSide][adj] != null) {
              _damageUnit(side, tSide, adj, 1);
            }
          }
        }
        break;
    }
  }

  /// Capacité active du héros. targetSide/targetLane comme pour les sorts.
  bool heroActive(int side, int tSide, int tLane) {
    final h = hero(side);
    if (heroUsed[side] || energy[side] < h.activeCost) return false;
    switch (h.id) {
      case 'kaelyn':
        final u = _unitAt(tSide, tLane);
        if (u == null) return false;
        _damageUnit(side, tSide, tLane, 3);
        if (board[tSide][tLane] != null) board[tSide][tLane]!.burn = 2;
        break;
      case 'nerek':
        final lane = firstFreeLane(side);
        if (lane == null) return false;
        board[side][lane] = CbUnit(CbData.card('marqueur'));
        break;
      case 'lysara':
        _healHero(side, 4);
        _draw(side);
        break;
      case 'zayden':
        final u = _unitAt(tSide, tLane);
        if (u == null) return false;
        u.canAttack = true;
        _damageUnit(side, tSide, tLane, 2);
        break;
      case 'morvan':
        final u = _unitAt(tSide, tLane);
        if (u == null || u.health > 3) return false;
        _emit('${u.def.name} est détruit');
        board[tSide][tLane] = null;
        _onUnitDeath(tSide);
        break;
      case 'orion':
        final u = _unitAt(tSide, tLane);
        if (u == null || tSide != side) return false;
        u.shield += 4;
        break;
      default:
        return false;
    }
    energy[side] -= h.activeCost;
    heroUsed[side] = true;
    _emit('${h.name} utilise sa capacité');
    _checkDeaths();
    return true;
  }

  // ---- Cycle de tour -----------------------------------------------------

  void startTurn(int side) {
    turnSide = side;
    turnCount++;
    maxEnergy[side] = min(kMaxEnergy, maxEnergy[side] + 1);
    energy[side] = maxEnergy[side];
    heroUsed[side] = false;
    // Orion : +1 bouclier héros / Tour de Garde.
    if (hero(side).id == 'orion') heroShield[side] += 1;
    for (var i = 0; i < kLanes; i++) {
      final u = board[side][i];
      if (u == null) continue;
      if (u.has(Kw.heroShieldEot)) heroShield[side] += 1;
      // Brûlure : tic en début de tour du propriétaire.
      if (u.burn > 0) {
        u.burn -= 1;
        _damageUnit(1 - side, side, i, 1, fromBurn: true);
      }
      if (u.frozen > 0) {
        u.frozen -= 1;
        u.canAttack = false;
      } else {
        u.canAttack = true;
      }
    }
    _draw(side);
    _checkDeaths();
  }

  /// Termine le tour du camp actif : phase d'attaque + effets de fin de tour.
  void finishTurn(int side) {
    _attackPhase(side);
    _endOfTurn(side);
    _checkWin();
  }

  void _attackPhase(int side) {
    final enemy = 1 - side;
    for (var lane = 0; lane < kLanes; lane++) {
      final u = board[side][lane];
      if (u == null || u.isStructure) continue;
      if (!u.canAttack || u.frozen > 0) continue;
      final dmg = atkOf(side, u);
      if (dmg <= 0) continue;

      // Provocation : cible prioritaire s'il y en a une.
      CbUnit? defender = board[enemy][lane];
      int defLane = lane;
      if (defender == null) {
        final tauntLane = _findTaunt(enemy);
        if (tauntLane != null) {
          defender = board[enemy][tauntLane];
          defLane = tauntLane;
        }
      }

      if (u.has(Kw.summonOnAttack)) {
        final free = firstFreeLane(side);
        if (free != null) board[side][free] = CbUnit(CbData.card('eclat_orage'));
      }
      if (u.has(Kw.healHeroOnAttack)) _healHero(side, 1);

      if (defender != null) {
        final killed = _damageUnit(side, enemy, defLane, dmg);
        // Riposte de la créature défenseur.
        if (!defender.isStructure && defender.health > 0) {
          _damageUnit(enemy, side, lane, atkOf(enemy, defender));
        }
        if (killed && u.has(Kw.growOnKill) && board[side][lane] != null) {
          u.attack += 1;
          u.health += 1;
          u.maxHealth += 1;
          _emit('${u.def.name} grandit (+1/+1)');
        }
      } else {
        _damageHero(enemy, dmg);
      }
      _checkDeaths();
      if (gameOver) return;
    }
  }

  void _endOfTurn(int side) {
    // Soin des unités alliées (Druide / Sanctuaire).
    var healAllies = false;
    for (var i = 0; i < kLanes; i++) {
      final u = board[side][i];
      if (u != null && u.has(Kw.healAlliesEot)) healAllies = true;
    }
    if (healAllies) {
      for (final u in board[side]) {
        if (u != null && u.health < u.maxHealth) u.health += 1;
      }
    }
    // Nerek : soigne les unités Flots.
    if (hero(side).id == 'nerek') {
      for (final u in board[side]) {
        if (u != null &&
            u.def.element == CbElement.flots &&
            u.health < u.maxHealth) {
          u.health += 1;
        }
      }
    }
    // Pylône Orageux : 1 dégât à une unité ennemie aléatoire.
    for (final u in board[side]) {
      if (u != null && u.has(Kw.pingEot)) {
        final targets = <int>[];
        for (var i = 0; i < kLanes; i++) {
          if (board[1 - side][i] != null) targets.add(i);
        }
        if (targets.isNotEmpty) {
          _damageUnit(side, 1 - side, targets[_rng.nextInt(targets.length)], 1);
        }
      }
    }
    _checkDeaths();
  }

  // ---- Dégâts / soins / morts -------------------------------------------

  /// Renvoie true si l'unité est morte.
  bool _damageUnit(int fromSide, int tSide, int lane, int amount,
      {bool fromBurn = false}) {
    final u = board[tSide][lane];
    if (u == null || amount <= 0) return false;
    var dmg = amount;
    if (u.shield > 0) {
      final absorbed = min(u.shield, dmg);
      u.shield -= absorbed;
      dmg -= absorbed;
    }
    if (dmg <= 0) return false;
    u.health -= dmg;
    if (u.health > 0) {
      if (u.has(Kw.drawOnSurvive)) _draw(tSide);
    }
    return u.health <= 0;
  }

  void _damageHero(int side, int amount) {
    var dmg = amount;
    if (heroShield[side] > 0) {
      final absorbed = min(heroShield[side], dmg);
      heroShield[side] -= absorbed;
      dmg -= absorbed;
    }
    hp[side] -= dmg;
    if (hp[side] <= 0) _checkWin();
  }

  void _healHero(int side, int amount) {
    hp[side] = min(hero(side).hp, hp[side] + amount);
  }

  void _checkDeaths() {
    for (var side = 0; side < 2; side++) {
      for (var i = 0; i < kLanes; i++) {
        final u = board[side][i];
        if (u != null && u.isDead) {
          _emit('${u.def.name} meurt');
          board[side][i] = null;
          _onUnitDeath(side);
        }
      }
    }
  }

  void _onUnitDeath(int side) {
    // Morvan : pioche quand une unité alliée meurt.
    if (hero(side).id == 'morvan') _draw(side);
    // Autel du Vide (non déployé par défaut) : +1 énergie — ignoré ici.
  }

  int? _findTaunt(int side) {
    for (var i = 0; i < kLanes; i++) {
      final u = board[side][i];
      if (u != null && u.has(Kw.taunt)) return i;
    }
    return null;
  }

  CbUnit? _unitAt(int side, int lane) {
    if (lane < 0 || lane >= kLanes) return null;
    return board[side][lane];
  }

  void _draw(int side) {
    if (deck[side].isEmpty) {
      fatigue[side] += 1;
      _damageHero(side, fatigue[side]);
      return;
    }
    if (hand[side].length >= kHandMax) {
      deck[side].removeLast(); // carte brûlée (main pleine)
      return;
    }
    hand[side].add(deck[side].removeLast());
  }

  void _checkWin() {
    if (gameOver) return;
    if (hp[1] <= 0) {
      gameOver = true;
      winner = 0;
    } else if (hp[0] <= 0) {
      gameOver = true;
      winner = 1;
    }
  }

  void _emit(String t) {
    log.add(CbEvent(t));
    if (log.length > 40) log.removeAt(0);
  }

  String _who(int side) => side == 0 ? 'Toi' : hero(1).name;

  // ---- IA ----------------------------------------------------------------

  /// L'IA joue ses cartes (une action). Renvoie false si plus rien à faire.
  bool aiStep() {
    const side = 1;
    // 1) Sorts de dégâts sur la plus grosse menace du joueur.
    for (var i = 0; i < hand[side].length; i++) {
      final c = hand[side][i];
      if (c.type == CbType.spell && canPlay(side, c)) {
        final t = _aiSpellTarget(c);
        if (t != null) {
          playSpell(side, i, t[0], t[1]);
          return true;
        }
      }
    }
    // 2) Artefact si abordable.
    for (var i = 0; i < hand[side].length; i++) {
      final c = hand[side][i];
      if (c.type == CbType.artifact && canPlay(side, c)) {
        playArtifact(side, i);
        return true;
      }
    }
    // 3) Poser une unité (la plus chère jouable) dans une ligne libre.
    var bestIdx = -1;
    var bestCost = -1;
    for (var i = 0; i < hand[side].length; i++) {
      final c = hand[side][i];
      final isUnit = c.type == CbType.creature || c.type == CbType.structure;
      if (isUnit && canPlay(side, c) && effectiveCost(side, c) > bestCost) {
        bestCost = effectiveCost(side, c);
        bestIdx = i;
      }
    }
    if (bestIdx >= 0) {
      final lane = _aiBestLane();
      if (lane != null) {
        playUnit(side, bestIdx, lane);
        return true;
      }
    }
    // 4) Capacité de héros si utile.
    if (energy[side] >= aiHero.activeCost && _aiUseHero()) return true;
    return false;
  }

  List<int>? _aiSpellTarget(CbCard c) {
    if (c.spellFx == SpellFx.damageAllEnemies) {
      final count = board[0].where((u) => u != null).length;
      return count >= 2 ? [0, -1] : null;
    }
    // Cible la plus grosse unité du joueur.
    int? bestLane;
    var bestHp = -1;
    for (var i = 0; i < kLanes; i++) {
      final u = board[0][i];
      if (u != null && u.health > bestHp) {
        bestHp = u.health;
        bestLane = i;
      }
    }
    if (bestLane == null) return null;
    return [0, bestLane];
  }

  int? _aiBestLane() {
    // Préfère une ligne face à une créature ennemie menaçante, sinon libre.
    int? free;
    for (var i = 0; i < kLanes; i++) {
      if (board[1][i] == null) {
        if (board[0][i] != null) return i; // bloque une menace
        free ??= i;
      }
    }
    return free;
  }

  bool _aiUseHero() {
    switch (aiHero.id) {
      case 'nerek':
      case 'lysara':
        return heroActive(1, 1, -1);
      case 'kaelyn':
      case 'zayden':
      case 'morvan':
        for (var i = 0; i < kLanes; i++) {
          if (board[0][i] != null) return heroActive(1, 0, i);
        }
        return false;
      case 'orion':
        for (var i = 0; i < kLanes; i++) {
          if (board[1][i] != null) return heroActive(1, 1, i);
        }
        return false;
    }
    return false;
  }
}
