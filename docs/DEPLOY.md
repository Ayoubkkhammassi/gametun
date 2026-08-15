# Déployer GameTun sur le cloud (gratuit) — pour que l'app marche sans ton PC

Objectif : mettre le **backend** en ligne sur **Render** (gratuit) pour qu'il tourne
24/7, indépendamment de ton PC. La base est déjà sur **Neon**.

```
📱 App  →  🌐 API sur Render (24/7)  →  🗄️ Base Neon
```

## Étape 1 — Mettre le code sur GitHub

1. Crée un compte sur **https://github.com** (si tu n'en as pas).
2. Crée un **nouveau dépôt** : bouton **New** → nom `gametun` → **Private** →
   **NE PAS** cocher "Add a README" → **Create repository**.
3. GitHub affiche une adresse type : `https://github.com/TON_PSEUDO/gametun.git`
   Copie-la, puis lance ces commandes (remplace l'URL) :

```bash
cd "C:/Users/AyoubKh/Desktop/gametun"
git branch -M main
git remote add origin https://github.com/TON_PSEUDO/gametun.git
git push -u origin main
```

> Au `git push`, une fenêtre **"Sign in to GitHub"** s'ouvre dans le navigateur.
> Connecte-toi → le code se pousse tout seul.

## Étape 2 — Déployer sur Render

1. Crée un compte sur **https://render.com** (bouton "Get Started", tu peux te
   connecter avec ton compte GitHub → plus simple).
2. Clique **New +** → **Blueprint**.
3. Sélectionne ton dépôt `gametun`. Render détecte automatiquement le fichier
   `backend/render.yaml`.
4. Render va te demander 2 valeurs (les autres sont auto) :
   - **DATABASE_URL** → colle ton URL Neon (la même que dans `backend/.env`).
   - **CORS_ORIGINS** → mets `*` (ou laisse vide).
5. Clique **Apply** / **Create**. Render installe, compile, applique les
   migrations et démarre. (~3-5 min. En gratuit, 1er accès après inactivité = ~50s.)
6. À la fin, Render te donne une URL type :
   `https://gametun-api.onrender.com`
   Teste-la : ouvre `https://gametun-api.onrender.com/api/v1/health` → tu dois
   voir `{"status":"ok"}`.

## Étape 3 — Pointer l'app vers le serveur en ligne

Une fois l'URL Render obtenue, on reconstruit l'APK pour qu'il vise ce serveur
(au lieu de ton PC) :

```bash
cd "C:/Users/AyoubKh/Desktop/gametun/mobile"
flutter build apk --release --dart-define=API_BASE_URL=https://gametun-api.onrender.com/api/v1
```

Puis on installe cet APK sur le téléphone. **Fini les coupures** : l'app marche
partout, tout le temps, même PC éteint. Tu peux même l'envoyer à tes amis.

---

### Notes
- Le plan gratuit Render "s'endort" après inactivité → 1er accès un peu lent
  (~50s), puis rapide. Suffisant pour tester et montrer l'app.
- Le WebSocket (chat + jeux à 2) fonctionne sur Render.
- Les secrets JWT sont générés automatiquement par Render (voir `render.yaml`).
