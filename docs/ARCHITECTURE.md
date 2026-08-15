# Architecture GameTun

## Principe directeur

**Frontend et backend totalement séparés.** Le mobile ne connaît que l'URL de
l'API et ne détient aucun secret serveur. Cela permet d'ajouter plus tard une
app Windows (Flutter aussi) et un panneau d'admin web, tous consommant la
**même API** avec le **même compte** utilisateur.

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Android    │   │  Windows    │   │   Admin     │
│  (Flutter)  │   │  (Flutter)  │   │   (web)     │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │ HTTPS (REST + WebSocket)          │
       └─────────────────┬─────────────────┘
                         ▼
              ┌────────────────────┐
              │   API NestJS       │  JWT, rate-limit, validation
              │  (modules métier)  │
              └─────────┬──────────┘
                        ▼
              ┌────────────────────┐
              │   PostgreSQL       │  via Prisma ORM
              └────────────────────┘
                   ☁️ Cloud (Render + Neon), pas le PC du dev
```

## Backend — modules (spec §18)

Organisation par module NestJS (1 domaine = 1 dossier dans `src/modules/`).

| Module          | Statut | Endpoints clés                              |
| --------------- | ------ | ------------------------------------------- |
| `auth`          | ✅     | register, login, refresh, logout, me        |
| `users`         | ✅     | /users/me, /users/:id (profil public)       |
| `profiles`      | ✅     | GET/PUT /profile                            |
| `games`         | ✅     | /games, /games/preferences                  |
| `health`        | ✅     | /health (sonde cloud)                       |
| `match`         | ⏳     | /match/search, /match/accept, /match/pass   |
| `smart-match`   | ⏳     | scoring de compatibilité                    |
| `social`        | ⏳     | découverte + connexions mutuelles           |
| `squads`        | ⏳     | CRUD squads + Smart Squad                   |
| `chat`          | ⏳     | WebSocket temps réel                        |
| `notifications` | ⏳     | centre + push                               |
| `minigames`     | ⏳     | Tic-Tac-Toe, Puissance 4, Quiz…             |
| `statistics`    | ⏳     | agrégats + graphiques                       |
| `reputation`    | ⏳     | évaluations anti-abus                       |
| `reports`       | ⏳     | signalements                               |
| `premium`       | ⏳     | abonnements                                 |
| `admin`         | ⏳     | interface séparée                           |

## Base de données (spec §19)

16 tables/relations définies dans [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma) :
`users`, `profiles`, `games`, `user_games`, `matches`, `social_actions`,
`squads`, `squad_members`, `conversations`, `conversation_participants`,
`messages`, `notifications`, `reports`, `blocked_users`, `reputation`,
`statistics`, `subscriptions`.

Choix de conception notables :

- **Séparation `User` / `Profile`** : le compte (auth) est distinct du profil
  public gaming.
- **`SocialAction` + `Match`** : les swipes (like/pass/favori) sont enregistrés ;
  un like mutuel crée un `Match` qui ouvre une conversation.
- **Réputation anti-abus** : contrainte d'unicité `(rater, rated, contexte)`
  pour empêcher les évaluations répétées.
- **Confidentialité** : `birthDate` stockée mais jamais renvoyée par l'API
  (dérivation en tranche d'âge côté serveur).

## App mobile — architecture

Découpage par *feature* + couche *core* transverse :

```
lib/
├── main.dart              # point d'entrée
├── router.dart            # go_router + redirection selon l'auth
├── core/
│   ├── theme/             # couleurs, thème sombre néon
│   ├── config/env.dart    # URL de l'API (--dart-define)
│   ├── network/           # Dio + interceptor (Bearer + refresh auto)
│   ├── storage/           # tokens chiffrés (flutter_secure_storage)
│   ├── providers.dart     # providers Riverpod partagés
│   └── widgets/           # composants réutilisables (boutons, cartes…)
└── features/
    ├── auth/              # splash, onboarding, login, register (RÉEL)
    └── shell/             # navigation 5 onglets + écrans
```

- **État** : Riverpod (`StateNotifier` pour l'auth).
- **Réseau** : Dio, réponses `{ success, data }` déballées, refresh token
  transparent sur 401, gestion du mode hors ligne.
- **Sécurité** : tokens stockés chiffrés, aucun secret compilé dans l'app.

## Feuille de route (spec §28)

Développement **phase par phase**, en compilant/testant à chaque étape (§29) :

1. ✅ Architecture + backend + DB + auth
2. ✅ Profil + jeux + préférences (API prête, écrans à enrichir)
3. Game Match + Smart Match
4. Social Match + connexion
5. Chat temps réel (WebSocket)
6. Squads + Smart Squad
7. Notifications (+ push)
8. Mini-jeux
9. Sécurité + signalement + blocage
10. Premium
11. Tests & optimisation

## Déploiement cloud

- **API** : Render (offre gratuite) via [`backend/render.yaml`](../backend/render.yaml)
  ou Docker via [`backend/Dockerfile`](../backend/Dockerfile).
- **DB** : Neon ou Supabase (PostgreSQL gratuit).
- **Secrets** : définis dans le dashboard de l'hébergeur, jamais dans le dépôt.
