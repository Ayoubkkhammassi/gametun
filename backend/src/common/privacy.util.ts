import { User } from '@prisma/client';

/**
 * Calcule l'âge (années révolues) à partir de la date de naissance.
 */
export function computeAge(birthDate: Date, now: Date = new Date()): number {
  let age = now.getFullYear() - birthDate.getFullYear();
  const m = now.getMonth() - birthDate.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birthDate.getDate())) {
    age -= 1;
  }
  return age;
}

/**
 * Tranche d'âge publique — on n'expose JAMAIS la date exacte (spec §4).
 */
export function ageGroup(age: number): string {
  if (age < 16) return '13-15';
  if (age < 18) return '16-17';
  if (age < 25) return '18-24';
  if (age < 35) return '25-34';
  return '35+';
}

/**
 * Vue publique/sûre d'un utilisateur: retire mot de passe, tokens et
 * la date de naissance exacte. Renvoie uniquement des champs non sensibles.
 */
export function toPublicUser(user: User) {
  const age = computeAge(user.birthDate);
  return {
    id: user.id,
    pseudo: user.pseudo,
    avatarUrl: user.avatarUrl,
    language: user.language,
    region: user.region,
    role: user.role,
    isPremium: user.isPremium,
    isOnline: user.isOnline,
    lastSeenAt: user.lastSeenAt,
    ageGroup: ageGroup(age),
    createdAt: user.createdAt,
  };
}

/**
 * Vue "moi": comme la vue publique mais inclut l'email (données du compte
 * propriétaire uniquement). Toujours sans mot de passe ni tokens.
 */
export function toSelfUser(user: User) {
  return {
    ...toPublicUser(user),
    email: user.email,
    status: user.status,
  };
}
