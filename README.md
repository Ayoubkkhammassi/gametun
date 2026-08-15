# GameTun 🇹🇳🎮

> **« Trouve tes joueurs. Crée ton équipe. Joue ensemble. »**
> La communauté gaming tunisienne — plateforme sociale pour trouver des
> coéquipiers compatibles, créer des squads, discuter et jouer.

Ce dépôt est un **monorepo** : le frontend et le backend sont séparés pour
permettre plus tard une version **Windows** partageant le même compte et la
même API.

```
📱 Android (Flutter)  ─┐
🖥️  Windows (Flutter)  ─┼──►  🌐 API (NestJS)  ──►  🗄️ PostgreSQL  ──►  ☁️ Cloud
🛠️  Admin (à venir)    ─┘
```

## Structure

| Dossier     | Contenu                                            | Statut          |
| ----------- | -------------------------------------------------- | --------------- |
| `backend/`  | API NestJS + Prisma + PostgreSQL (16 tables, auth) | ✅ Phase 1      |
| `mobile/`   | App Flutter (Android + Windows), thème premium     | ✅ Ossature     |
| `docs/`     | Architecture & feuille de route                    | 📄              |
| `admin/`    | Panneau d'administration web                        | ⏳ plus tard    |

## Démarrage rapide

### 1. Backend

```bash
cd backend
cp .env.example .env      # renseigner DATABASE_URL + secrets JWT
npm install
npm run prisma:generate
npm run prisma:migrate    # crée les tables
npm run seed              # catalogue de jeux
npm run start:dev         # http://localhost:3000/api/v1
```

> Base PostgreSQL gratuite recommandée : [Neon](https://neon.tech) ou
> [Supabase](https://supabase.com). Le backend ne doit **pas** tourner en
> production sur le PC du développeur (spec §24).

### 2. App mobile

```bash
cd mobile
flutter pub get
# Émulateur Android (10.0.2.2 = localhost de la machine hôte) :
flutter run
# Ou pointer vers l'API déployée :
flutter run --dart-define=API_BASE_URL=https://ton-api.onrender.com/api/v1
```

## État d'avancement (par rapport à la spec §28)

| Phase | Contenu                                   | Statut               |
| ----- | ----------------------------------------- | -------------------- |
| 1     | Architecture + backend + DB + auth        | ✅ Fait & testé      |
| 2     | Profil + jeux + préférences               | ✅ API prête         |
| 3     | Game Match + Smart Match                  | ⏳ À venir           |
| 4     | Social Match + connexion                  | ⏳ À venir           |
| 5     | Chat (temps réel)                         | ⏳ À venir           |
| 6     | Squads + Smart Squad                      | ⏳ À venir           |
| 7     | Notifications                             | ⏳ À venir           |
| 8     | Mini-jeux                                 | ⏳ À venir           |
| 9     | Sécurité + signalement + blocage          | ⏳ (base en place)   |
| 10    | Premium                                   | ⏳ À venir           |
| 11    | Tests & optimisation                      | ⏳ En continu        |

## Ce qui fonctionne vraiment aujourd'hui

L'authentification est **réelle et de bout en bout** (pas de fausses données) :

1. L'app démarre sur le splash → onboarding.
2. Inscription (contrôle d'âge) ou connexion → appelle l'API NestJS.
3. Les tokens JWT sont stockés de façon **chiffrée** sur l'appareil.
4. La session est restaurée au redémarrage ; le token expiré est rafraîchi
   automatiquement.
5. Accueil et Profil affichent les **vraies données** du compte connecté.

Les onglets Social / Recherche / Squad affichent honnêtement « à venir » —
aucune donnée factice n'est présentée comme réelle (spec §27).

## Sécurité & confidentialité

- Mots de passe hachés (**argon2**), jamais stockés en clair.
- **Date de naissance jamais exposée** : seule une tranche d'âge est publique.
- Contrôle d'âge minimum à l'inscription (protection des mineurs).
- Rate limiting, validation stricte, CORS, Helmet.
- **Aucun secret dans le code** — tout via variables d'environnement.

Voir [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) pour les détails.
