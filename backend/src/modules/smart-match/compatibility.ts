import { SkillLevel } from '@prisma/client';

/** Profil minimal utilisé pour le calcul de compatibilité. */
export interface MatchProfile {
  gameSlugs: string[];
  level: SkillLevel;
  language: string;
  region: string;
  availabilityFrom?: string | null; // "HH:MM"
  availabilityTo?: string | null;
}

/** Critères de recherche fournis par l'utilisateur (Game Match). */
export interface MatchCriteria {
  gameSlugs: string[];
  level?: SkillLevel;
  language?: string;
  availabilityFrom?: string | null;
  availabilityTo?: string | null;
}

const LEVEL_ORDER: Record<SkillLevel, number> = {
  BEGINNER: 0,
  INTERMEDIATE: 1,
  ADVANCED: 2,
  EXPERT: 3,
};

/** Convertit "HH:MM" en minutes depuis minuit (ou null). */
function toMinutes(hhmm?: string | null): number | null {
  if (!hhmm) return null;
  const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(hhmm);
  if (!m) return null;
  return Number(m[1]) * 60 + Number(m[2]);
}

/** Chevauchement (0..1) de deux plages horaires. */
function availabilityOverlap(
  aFrom?: string | null,
  aTo?: string | null,
  bFrom?: string | null,
  bTo?: string | null,
): number {
  const a1 = toMinutes(aFrom);
  const a2 = toMinutes(aTo);
  const b1 = toMinutes(bFrom);
  const b2 = toMinutes(bTo);
  if (a1 == null || a2 == null || b1 == null || b2 == null) return 0.5; // inconnu = neutre
  const start = Math.max(a1, b1);
  const end = Math.min(a2, b2);
  const overlap = Math.max(0, end - start);
  const span = Math.max(a2 - a1, b2 - b1, 1);
  return Math.min(1, overlap / span);
}

/**
 * Poids des critères (total 100). Basé sur la spec §7.
 */
export const WEIGHTS = {
  commonGames: 35,
  level: 15,
  language: 15,
  availability: 15,
  region: 10,
  activity: 10, // bonus si profil complet / actif
} as const;

/**
 * Score de compatibilité (0..100) entre des critères et un profil candidat.
 * Fonction PURE → facilement testable.
 */
export function compatibilityScore(
  criteria: MatchCriteria,
  candidate: MatchProfile,
): number {
  // 1) Jeux communs — proportion des jeux recherchés que le candidat possède.
  const wanted = new Set(criteria.gameSlugs);
  const has = candidate.gameSlugs.filter((g) => wanted.has(g)).length;
  const gamesRatio = wanted.size === 0 ? 0 : has / wanted.size;
  let score = gamesRatio * WEIGHTS.commonGames;

  // 2) Niveau — proche = mieux.
  if (criteria.level) {
    const diff = Math.abs(
      LEVEL_ORDER[criteria.level] - LEVEL_ORDER[candidate.level],
    );
    const levelScore = Math.max(0, 1 - diff / 3);
    score += levelScore * WEIGHTS.level;
  } else {
    score += WEIGHTS.level * 0.5;
  }

  // 3) Langue.
  if (criteria.language) {
    score += (criteria.language === candidate.language ? 1 : 0) *
      WEIGHTS.language;
  } else {
    score += WEIGHTS.language * 0.5;
  }

  // 4) Disponibilité (chevauchement horaire).
  score +=
    availabilityOverlap(
      criteria.availabilityFrom,
      criteria.availabilityTo,
      candidate.availabilityFrom,
      candidate.availabilityTo,
    ) * WEIGHTS.availability;

  // 5) Région — même région = bonus (moins de latence, même fuseau).
  // (comparaison souple, insensible à la casse)
  const sameRegion =
    candidate.region?.toLowerCase().trim() ===
    (criteria as unknown as { region?: string }).region?.toLowerCase().trim();
  score += (sameRegion ? 1 : 0.4) * WEIGHTS.region;

  // 6) Activité — profil ayant des jeux renseignés.
  score += (candidate.gameSlugs.length > 0 ? 1 : 0) * WEIGHTS.activity;

  return Math.round(Math.max(0, Math.min(100, score)));
}
