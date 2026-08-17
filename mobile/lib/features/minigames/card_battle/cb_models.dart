import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Éléments / factions du TCG GameTun.
enum CbElement { braise, flots, verdant, orage, vide, lumiere }

enum CbType { creature, spell, structure, artifact }

enum CbRarity { common, uncommon, rare, epic, legendary }

/// Mots-clés (capacités data-driven) des créatures et structures.
enum Kw {
  rush, // Ruée : peut attaquer le tour où elle est jouée
  taunt, // Provocation : doit être attaquée en priorité
  shield, // Bouclier : absorbe des dégâts (valeur = shieldValue)
  growOnKill, // Vol de vie : gagne +1/+1 quand elle tue
  drawOnSurvive, // survit à des dégâts -> piocher
  healHeroOnAttack, // quand elle attaque -> soigne 1 PV au héros
  summonOnAttack, // à l'attaque -> invoque un jeton 1/1
  healAlliesEot, // fin de tour -> soigne +1 PV aux unités alliées
  heroShieldEot, // début de tour -> +1 bouclier au héros
  pingEot, // fin de tour -> 1 dégât à une unité ennemie aléatoire
}

/// Effet d'un sort.
enum SpellFx {
  damageOne, // dégâts à une unité (value)
  damageAllEnemies, // dégâts à toutes les unités ennemies (value)
  freezeOne, // immobilise une unité (value = tours)
  chain, // dégâts à une cible + moitié aux adjacentes
}

extension CbElementX on CbElement {
  String get label => switch (this) {
        CbElement.braise => 'Braise',
        CbElement.flots => 'Flots',
        CbElement.verdant => 'Verdant',
        CbElement.orage => 'Orage',
        CbElement.vide => 'Vide',
        CbElement.lumiere => 'Lumière',
      };

  String get emoji => switch (this) {
        CbElement.braise => '🔥',
        CbElement.flots => '🌊',
        CbElement.verdant => '🌿',
        CbElement.orage => '⚡',
        CbElement.vide => '🌑',
        CbElement.lumiere => '✨',
      };

  Color get color => switch (this) {
        CbElement.braise => const Color(0xFFEF4444),
        CbElement.flots => const Color(0xFF38BDF8),
        CbElement.verdant => const Color(0xFF4ADE80),
        CbElement.orage => const Color(0xFFFACC15),
        CbElement.vide => const Color(0xFFA855F7),
        CbElement.lumiere => const Color(0xFFFCD34D),
      };

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.45)],
      );
}

extension CbRarityX on CbRarity {
  Color get color => switch (this) {
        CbRarity.common => const Color(0xFF9CA3AF),
        CbRarity.uncommon => AppColors.green,
        CbRarity.rare => AppColors.cyan,
        CbRarity.epic => AppColors.primary,
        CbRarity.legendary => AppColors.gold,
      };
  String get label => switch (this) {
        CbRarity.common => 'Commune',
        CbRarity.uncommon => 'Peu commune',
        CbRarity.rare => 'Rare',
        CbRarity.epic => 'Épique',
        CbRarity.legendary => 'Légendaire',
      };
}

/// Définition immuable d'une carte (template).
class CbCard {
  final String id;
  final String name;
  final CbElement element;
  final CbType type;
  final CbRarity rarity;
  final int cost;
  final int attack;
  final int health;
  final String text;
  final Set<Kw> keywords;
  final int shieldValue; // pour Bouclier
  final SpellFx? spellFx;
  final int spellValue;
  final IconData icon;

  const CbCard({
    required this.id,
    required this.name,
    required this.element,
    required this.type,
    required this.rarity,
    required this.cost,
    this.attack = 0,
    this.health = 0,
    required this.text,
    this.keywords = const {},
    this.shieldValue = 0,
    this.spellFx,
    this.spellValue = 0,
    this.icon = Icons.auto_awesome,
  });
}

/// Définition d'un héros.
class CbHero {
  final String id;
  final String name;
  final String faction;
  final CbElement element;
  final int hp;
  final String passiveText;
  final String activeText;
  final int activeCost;
  final List<String> deck; // ids de cartes (avec doublons)
  final IconData icon;

  const CbHero({
    required this.id,
    required this.name,
    required this.faction,
    required this.element,
    this.hp = 30,
    required this.passiveText,
    required this.activeText,
    this.activeCost = 2,
    required this.deck,
    this.icon = Icons.shield,
  });
}

/// Instance runtime d'une unité (créature ou structure) sur le plateau.
class CbUnit {
  final CbCard def;
  int attack;
  int health;
  int maxHealth;
  int shield;
  int burn; // tours de brûlure restants
  int frozen; // tours d'immobilisation restants
  bool canAttack;

  CbUnit(this.def)
      : attack = def.attack,
        health = def.health,
        maxHealth = def.health,
        shield = def.keywords.contains(Kw.shield) ? def.shieldValue : 0,
        burn = 0,
        frozen = 0,
        canAttack = def.keywords.contains(Kw.rush);

  bool get isStructure => def.type == CbType.structure;
  bool get isDead => health <= 0;
  bool has(Kw k) => def.keywords.contains(k);
}
