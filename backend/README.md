# GameTun — Backend API

API sécurisée pour l'application sociale gaming **GameTun** 🇹🇳🎮
Construite avec **NestJS + Prisma + PostgreSQL**. Indépendante du frontend
(Android/Windows/Admin consomment la même API).

## Stack

| Rôle            | Techno                          |
| --------------- | ------------------------------- |
| Framework       | NestJS 10 (TypeScript)          |
| ORM             | Prisma 6                        |
| Base de données | PostgreSQL                      |
| Auth            | JWT (access + refresh) + argon2 |
| Temps réel      | Socket.IO (Chat, à venir)       |
| Sécurité        | Helmet, CORS, rate limiting     |

## Démarrage rapide

### 1. Prérequis

- Node.js ≥ 20
- Une base PostgreSQL. Options :
  - **Cloud gratuit (recommandé)** : [Neon](https://neon.tech) ou
    [Supabase](https://supabase.com) → copier l'URL de connexion.
  - Local : PostgreSQL installé sur la machine.

### 2. Configuration

```bash
cd backend
cp .env.example .env
# Éditer .env : mettre DATABASE_URL et des secrets JWT forts
npm install
```

Générer des secrets forts :

```bash
node -e "console.log(require('crypto').randomBytes(48).toString('base64'))"
```

### 3. Base de données

```bash
npm run prisma:generate     # génère le client Prisma
npm run prisma:migrate      # crée les tables (dev)
npm run seed                # remplit le catalogue de jeux
```

### 4. Lancer

```bash
npm run start:dev           # http://localhost:3000/api/v1
```

Vérifier : `GET http://localhost:3000/api/v1/health` → `{ status: "ok" }`.

## Endpoints (Phase 1 & 2)

Toutes les routes sont préfixées `/api/v1`. Réponses au format
`{ success: true, data: ... }` ou `{ success: false, message, statusCode }`.

| Méthode | Route                 | Auth | Description                       |
| ------- | --------------------- | ---- | -------------------------------- |
| POST    | `/auth/register`      | —    | Inscription (contrôle d'âge)     |
| POST    | `/auth/login`         | —    | Connexion (email ou pseudo)      |
| POST    | `/auth/refresh`       | —    | Renouvelle les tokens (rotation) |
| POST    | `/auth/logout`        | ✅   | Révoque le refresh token         |
| GET     | `/auth/me`            | ✅   | Utilisateur du token             |
| GET     | `/users/me`           | ✅   | Mon compte complet               |
| GET     | `/users/:id`          | ✅   | Profil public d'un joueur        |
| GET     | `/profile`            | ✅   | Mon profil                       |
| PUT     | `/profile`            | ✅   | Modifier mon profil              |
| GET     | `/games`              | —    | Catalogue de jeux                |
| GET     | `/games/preferences`  | ✅   | Mes jeux favoris                 |
| POST    | `/games/preferences`  | ✅   | Définir mes jeux favoris         |
| GET     | `/health`             | —    | Sonde de vitalité                |

Authentification : en-tête `Authorization: Bearer <accessToken>`.

## Sécurité & confidentialité

- Mots de passe hachés avec **argon2** (jamais en clair).
- La **date de naissance exacte n'est jamais renvoyée** : l'API expose une
  tranche d'âge (`ageGroup`). Contrôle d'âge minimum à l'inscription (`MIN_AGE`).
- **Rate limiting** global + limites strictes sur `/auth/*` (anti brute-force).
- Refresh token **haché en base** et **rotaté** à chaque usage (révocable).
- Validation stricte des entrées (`whitelist`, rejet des champs inconnus).
- Aucun secret dans le code : tout vient des variables d'environnement.

## Déploiement cloud (gratuit)

Le backend ne doit PAS tourner sur le PC du développeur en production.
Voir [`render.yaml`](./render.yaml) — déploiement en un clic sur
[Render](https://render.com) (offre gratuite) + base Neon/Supabase.

```
📱/🖥️ Frontend → 🌐 API (Render) → 🗄️ PostgreSQL (Neon)
```

## Tests

```bash
npm test           # tests unitaires
npm run test:e2e   # tests end-to-end
```

## Architecture

```
src/
├── main.ts                 # bootstrap (helmet, CORS, validation, prefix /api/v1)
├── app.module.ts           # câblage global (guards, filtres, throttler)
├── config/                 # chargement + validation des variables d'env
├── prisma/                 # service + module Prisma
├── common/                 # filtres, interceptors, décorateurs, utils privacy
└── modules/
    ├── auth/               # inscription, login, refresh, JWT
    ├── users/              # compte + profils publics
    ├── profiles/           # profil joueur
    ├── games/              # catalogue + préférences
    └── health/             # sonde
```

Modules à venir (phases suivantes) : `match`, `smart-match`, `social`,
`squads`, `chat`, `notifications`, `minigames`, `statistics`, `reputation`,
`reports`, `premium`, `admin`.
