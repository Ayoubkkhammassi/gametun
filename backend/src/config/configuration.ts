/**
 * Chargement + validation des variables d'environnement.
 * Aucune valeur secrète n'est codée en dur: tout vient de `process.env`.
 * L'app refuse de démarrer si une variable requise est absente/invalide.
 */

export interface AppConfig {
  nodeEnv: string;
  port: number;
  corsOrigins: string[];
  databaseUrl: string;
  jwt: {
    accessSecret: string;
    accessTtl: string;
    refreshSecret: string;
    refreshTtl: string;
  };
  throttle: {
    ttlMs: number;
    limit: number;
  };
  minAge: number;
  premiumPriceTnd: number;
  googleClientId: string;
}

class ConfigError extends Error {}

function required(key: string): string {
  const value = process.env[key];
  if (!value || value.trim() === '') {
    throw new ConfigError(`Variable d'environnement manquante: ${key}`);
  }
  return value;
}

function optional(key: string, fallback: string): string {
  const value = process.env[key];
  return value && value.trim() !== '' ? value : fallback;
}

function toInt(value: string, key: string): number {
  const n = Number.parseInt(value, 10);
  if (Number.isNaN(n)) {
    throw new ConfigError(`Variable d'environnement invalide (entier attendu): ${key}`);
  }
  return n;
}

export function loadConfiguration(): AppConfig {
  const nodeEnv = optional('NODE_ENV', 'development');
  const isProd = nodeEnv === 'production';

  // En production, on exige de vrais secrets. En dev, on tolère des valeurs par défaut.
  const accessSecret = isProd
    ? required('JWT_ACCESS_SECRET')
    : optional('JWT_ACCESS_SECRET', 'dev_access_secret_change_me');
  const refreshSecret = isProd
    ? required('JWT_REFRESH_SECRET')
    : optional('JWT_REFRESH_SECRET', 'dev_refresh_secret_change_me');

  if (isProd && accessSecret === refreshSecret) {
    throw new ConfigError('JWT_ACCESS_SECRET et JWT_REFRESH_SECRET doivent être différents.');
  }

  return {
    nodeEnv,
    port: toInt(optional('PORT', '3000'), 'PORT'),
    corsOrigins: optional('CORS_ORIGINS', 'http://localhost:8080')
      .split(',')
      .map((o) => o.trim())
      .filter(Boolean),
    databaseUrl: required('DATABASE_URL'),
    jwt: {
      accessSecret,
      accessTtl: optional('JWT_ACCESS_TTL', '15m'),
      refreshSecret,
      refreshTtl: optional('JWT_REFRESH_TTL', '30d'),
    },
    throttle: {
      ttlMs: toInt(optional('THROTTLE_TTL_MS', '60000'), 'THROTTLE_TTL_MS'),
      limit: toInt(optional('THROTTLE_LIMIT', '120'), 'THROTTLE_LIMIT'),
    },
    minAge: toInt(optional('MIN_AGE', '13'), 'MIN_AGE'),
    premiumPriceTnd: Number.parseFloat(optional('PREMIUM_PRICE_TND', '2.99')),
    // ID client Web Google (public) pour vérifier les tokens Google.
    googleClientId: optional('GOOGLE_CLIENT_ID', ''),
  };
}
