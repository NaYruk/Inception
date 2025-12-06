# 📚 Récapitulatif : Backend Node.js + Docker - 6 décembre 2025

## 🎯 Ce que j'ai accompli aujourd'hui

J'ai créé un **backend API complet** avec Node.js et Express, containerisé avec Docker, et orchestré avec Docker Compose.

---

## 📁 Structure finale du projet

```
CV-Site/
├── frontend/                    # Application React (déjà existante)
│   ├── src/
│   ├── public/
│   ├── Dockerfile              # Multi-stage: Node.js build + Nginx
│   ├── nginx.conf              # Config pour SPA routing
│   └── package.json
│
├── backend/                     # Nouveau ! API Node.js
│   ├── src/
│   │   └── index.js            # Serveur Express avec 3 routes
│   ├── Dockerfile              # Image Node.js Alpine
│   ├── package.json            # Dependencies: express + cors
│   └── package-lock.json
│
├── docker-compose.yml           # Orchestre frontend + backend
└── README.md
```

---

## 🧠 Concepts clés appris

### 1. **Différence Frontend vs Backend**

| Aspect | Frontend (Nginx) | Backend (Node.js) |
|--------|------------------|-------------------|
| **Rôle** | Servir les fichiers statiques | Traiter la logique métier |
| **Type** | Serveur web statique | Serveur web dynamique |
| **Contenu** | HTML, CSS, JS (déjà compilés) | Données JSON, API |
| **Exemple** | Envoie `index.html` | Envoie `{name: "Marc", ...}` |D
| **Analogie** | Serveur de restaurant | Cuisinier |

**Flow complet** :
```
1. Navigateur → http://localhost:3000
2. Nginx envoie index.html + React
3. React s'exécute dans le navigateur
4. React fait : fetch('http://localhost:5001/api/profile')
5. Node.js reçoit la requête → Se connecte à la DB → Renvoie JSON
6. React affiche les données
```

---

### 2. **Node.js pour le backend**

**Node.js** = Environnement d'exécution JavaScript côté serveur

**Utilisations** :
- Serveur HTTP (avec Express)
- Accès aux fichiers
- Connexion aux bases de données
- Traitement de données

---

### 3. **Express.js : Le framework web**

**Express** = Framework pour créer des serveurs web facilement

#### **Sans Express (Node.js pur)** ❌
```javascript
import http from 'http';

const server = http.createServer((req, res) => {
  if (req.url === '/api/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  } else if (req.url === '/api/profile' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ name: 'Marc' }));
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});
```

#### **Avec Express** ✅
```javascript
import express from 'express';
const app = express();

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/api/profile', (req, res) => {
  res.json({ name: 'Marc' });
});

app.listen(5001);
```

**Avantages** :
- Code plus lisible et concis
- Routing simplifié
- Middleware facile à utiliser

---

### 4. **CORS : Cross-Origin Resource Sharing**

**Problème** : Les navigateurs bloquent les requêtes entre différentes origines par sécurité.

```
Frontend: http://localhost:3000   (Nginx)
Backend:  http://localhost:5001   (Node.js)
          ↑
          Deux origines différentes !
```

**Sans CORS** ❌ :
```javascript
// Dans React
fetch('http://localhost:5001/api/profile')

// Erreur dans le navigateur:
// "Access to fetch blocked by CORS policy"
```

**Avec CORS** ✅ :
```javascript
import cors from 'cors';
app.use(cors());  // Autorise toutes les origines
```

**Ce que ça fait** : Ajoute des headers HTTP spéciaux
```
Response Headers:
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
```

**En production (plus sécurisé)** :
```javascript
app.use(cors({
  origin: 'https://mon-cv.com',  // Seulement ce domaine
  methods: ['GET', 'POST']
}));
```

---

### 5. **Middleware : Les intermédiaires**

**Middleware** = Fonction qui traite les requêtes **avant** qu'elles n'arrivent aux routes

```javascript
app.use(cors());           // 1. Autorise CORS
app.use(express.json());   // 2. Parse le JSON

// Puis les routes
app.get('/api/profile', (req, res) => {
  // La requête arrive ici après avoir traversé les middlewares
});
```

**Flow** :
```
Requête → cors() → express.json() → Route
         ↑         ↑
      Autorise   Décode JSON
```

**`express.json()`** :
- Transforme le JSON reçu en objet JavaScript
- Sans ça : `req.body` serait du texte brut

---

### 6. **Routes GET vs POST**

#### **GET** : Récupérer des données
```javascript
app.get('/api/profile', (req, res) => {
  res.json({ name: 'Marc', title: 'Développeur' });
});
```

**Usage** : `curl http://localhost:5001/api/profile`

#### **POST** : Envoyer des données
```javascript
app.post('/api/contact', (req, res) => {
  const { name, email, message } = req.body;  // Destructuration
  console.log('Message reçu:', { name, email, message });

  res.json({ success: true });
});
```

**Usage** :
```bash
curl -X POST http://localhost:5001/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"Marc","email":"test@test.com","message":"Hello"}'
```

---

### 7. **req et res : Request & Response**

```javascript
app.get('/api/profile', (req, res) => {
  // req = requête entrante
  // res = réponse à envoyer
});
```

**`req` (request)** :
- `req.body` : Données envoyées (POST/PUT)
- `req.params` : Paramètres d'URL (`/users/:id`)
- `req.query` : Query parameters (`?search=test`)
- `req.headers` : Headers HTTP

**`res` (response)** :
- `res.json({ ... })` : Envoyer du JSON
- `res.status(404).send('Not found')` : Définir le statut HTTP
- `res.send('text')` : Envoyer du texte

---

## 🐳 Docker : Concepts clés

### 8. **Dockerfile backend : Simple vs Frontend**

**Frontend** : Multi-stage (build + production)
```dockerfile
FROM node:20-alpine AS builder  # Stage 1: Build
RUN npm run build

FROM nginx:alpine               # Stage 2: Serve
COPY --from=builder /app/dist /usr/share/nginx/html
```

**Backend** : Simple (pas de compilation)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
EXPOSE 5001
CMD ["npm", "start"]
```

**Pourquoi plus simple ?**
- Pas de build step (pas de compilation)
- Pas besoin de Nginx (Node.js gère le serveur HTTP)
- Un seul stage suffit

---

### 9. **RUN vs CMD**

| Instruction | Quand ? | Combien de fois ? | Exemple |
|-------------|---------|-------------------|---------|
| `RUN` | Pendant le **build** | Plusieurs fois possible | `RUN npm ci` |
| `CMD` | Au **démarrage** du container | Une seule fois | `CMD ["npm", "start"]` |

**RUN** : Construit l'image
```dockerfile
RUN npm ci              # S'exécute pendant docker build
RUN apt-get install ... # S'exécute pendant docker build
```

**CMD** : Démarre le container
```dockerfile
CMD ["npm", "start"]    # S'exécute au docker run
```

---

### 10. **docker-compose.yml : Orchestration**

**Rôle** : Gérer plusieurs services ensemble

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:80"

  backend:
    build: ./backend
    ports:
      - "5001:5001"
    environment:
      - NODE_ENV=production
```

**Avantages** :
- Une seule commande : `docker compose up`
- Networking automatique entre services
- Facile à gérer

---

### 11. **depends_on : Ordre de démarrage**

```yaml
frontend:
  depends_on:
    - backend    # Frontend attend que backend démarre

backend:
  depends_on:
    - postgres   # Backend attend que la DB démarre
```

**Ordre** :
```
1. postgres   (DB)
2. backend    (API) - attend postgres
3. frontend   (UI)  - attend backend
```

⚠️ **Important** : `depends_on` attend que le container démarre, pas qu'il soit **prêt** !

**Solution** : Utiliser `healthcheck`

---

### 12. **Healthcheck : Vérifier que le service est prêt**

```yaml
backend:
  healthcheck:
    test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5001/api/health"]
    interval: 30s      # Vérifie toutes les 30s
    timeout: 10s       # Timeout après 10s
    retries: 3         # 3 essais avant "unhealthy"
    start_period: 10s  # Attendre 10s au démarrage
```

**États possibles** :
- `starting` : En train de démarrer
- `healthy` : Tout va bien ✅
- `unhealthy` : Le service ne répond pas ❌

**Utilisation avancée** :
```yaml
backend:
  depends_on:
    postgres:
      condition: service_healthy  # Attend le healthcheck !
```

---

### 13. **Environment variables : Configuration**

```yaml
backend:
  environment:
    - NODE_ENV=production
    - PORT=5001
    - DATABASE_URL=postgresql://user:pass@postgres:5432/db
```

**Dans le code** :
```javascript
const PORT = process.env.PORT || 5001;  // Lit la variable
const env = process.env.NODE_ENV;       // 'production'
```

---

## 📝 Fichiers créés

### 1. `backend/package.json`

```json
{
  "name": "cv-site-backend",
  "version": "1.0.0",
  "description": "Backend API pour le CV interactif",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js"
  },
  "dependencies": {
    "express": "^5.2.1",
    "cors": "^2.8.5"
  }
}
```

**Points importants** :
- `"type": "module"` : Permet d'utiliser `import` au lieu de `require`
- `"start"` : Pour la production
- `"dev"` : Avec `--watch` pour le hot reload

---

### 2. `backend/src/index.js`

```javascript
import express from 'express';
import cors from 'cors';

const app = express();
const PORT = process.env.PORT || 5001;

// Middlewares
app.use(cors());           // Autorise les requêtes cross-origin
app.use(express.json());   // Parse le JSON des requêtes

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend is running' });
});

app.get('/api/profile', (req, res) => {
  res.json({
    name: 'Marc Milliot',
    title: 'Développeur Fullstack',
    school: 'École 42',
    skills: ['React', 'TypeScript', 'Docker', 'Node.js', 'Express'],
    location: 'Mulhouse, France'
  });
});

app.post('/api/contact', (req, res) => {
  const { name, email, message } = req.body;

  console.log('📧 Message reçu:', { name, email, message });

  res.json({
    success: true,
    message: 'Message reçu avec succès !'
  });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`🚀 Backend API listening on http://localhost:${PORT}`);
});
```

---

### 3. `backend/Dockerfile`

```dockerfile
# Image Node.js Alpine
FROM node:20-alpine

# Définir le répertoire de travail
WORKDIR /app

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Exposer le port 5001
EXPOSE 5001

# Démarrer le serveur
CMD ["npm", "start"]
```

**Ordre des instructions** :
1. `FROM` : Image de base
2. `WORKDIR` : Dossier de travail
3. `COPY package*.json` : Fichiers de dépendances (cache Docker)
4. `RUN npm ci` : Installation (layer caché)
5. `COPY . .` : Reste du code
6. `EXPOSE` : Documentation du port
7. `CMD` : Commande de démarrage

---

### 4. `docker-compose.yml` (extrait backend)

```yaml
services:
  frontend:
    # ... (déjà existant)

  backend:
    container_name: cv-site-backend
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: unless-stopped
    ports:
      - "5001:5001"
    environment:
      - NODE_ENV=production
      - PORT=5001
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:5001/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

---

## 🧪 Tests et commandes

### Développement local (sans Docker)

```bash
# Dans backend/
npm install          # Installer les dépendances
npm run dev          # Lancer en mode développement (hot reload)

# Tester les routes
curl http://localhost:5001/api/health
curl http://localhost:5001/api/profile

curl -X POST http://localhost:5001/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","email":"test@test.com","message":"Hello"}'
```

### Avec Docker Compose

```bash
# Démarrer tout
docker compose up --build

# En arrière-plan
docker compose up -d

# Voir les logs
docker compose logs -f
docker compose logs -f backend

# Arrêter
docker compose down

# Voir l'état
docker compose ps

# Entrer dans un container
docker compose exec backend sh
```

---

## 🔧 Debugging : Problèmes rencontrés et solutions

### 1. **Port 5000 déjà utilisé par AirTunes (macOS)**

**Erreur** :
```
< HTTP/1.1 403 Forbidden
< Server: AirTunes/870.14.1
```

**Solution** : Utiliser le port 5001 au lieu de 5000
```javascript
const PORT = 5001;
```

---

### 2. **package-lock.json exclu par .dockerignore**

**Erreur** :
```
npm ci can only install with an existing package-lock.json
```

**Problème** : `package-lock.json` était dans `.dockerignore`

**Solution** : NE PAS exclure `package-lock.json` (nécessaire pour `npm ci`)

```dockerignore
# ✅ Exclure
node_modules/

# ❌ NE PAS exclure
# package-lock.json
```

---

### 3. **Faute de frappe dans healthcheck**

**Erreur** : Frontend marqué "unhealthy"

**Problème** :
```yaml
test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "htpp://localhost:80"]
                                                          ^^^^
```

**Solution** : `http://` (pas `htpp://`)

---

## 🎓 Compétences acquises

### Techniques
- ✅ Créer un serveur backend Node.js + Express
- ✅ Gérer les routes GET et POST
- ✅ Utiliser les middlewares (CORS, JSON parsing)
- ✅ Containeriser un backend avec Docker
- ✅ Orchestrer plusieurs services avec Docker Compose
- ✅ Configurer des healthchecks
- ✅ Débugger des problèmes réseau et Docker

### Concepts
- ✅ Architecture client-serveur
- ✅ API REST
- ✅ CORS et sécurité web
- ✅ Variables d'environnement
- ✅ Networking Docker
- ✅ Multi-stage builds vs simple builds

---

## 📊 Architecture finale

```
┌─────────────────────────────────────────┐
│          DOCKER COMPOSE                 │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │  Frontend    │  │   Backend    │   │
│  │  (Nginx)     │  │  (Node.js +  │   │
│  │              │  │   Express)   │   │
│  │  Port 3000   │  │  Port 5001   │   │
│  │              │  │              │   │
│  │ - Sert HTML  │  │ - 3 Routes   │   │
│  │ - Sert CSS   │  │ - CORS       │   │
│  │ - Sert JS    │  │ - JSON       │   │
│  └──────┬───────┘  └──────┬───────┘   │
│         │                  │            │
│         │  Réseau Docker   │            │
│         └──────────────────┘            │
│                                         │
│  Network: cv-site_default               │
└─────────────────────────────────────────┘
         │                  │
         │                  │
         ▼                  ▼
   localhost:3000    localhost:5001
```

---

## 🚀 Prochaines étapes possibles

1. **Ajouter PostgreSQL** : Base de données pour stocker les contacts
2. **Connecter le backend à la DB** : Utiliser `pg` (node-postgres)
3. **Créer un formulaire de contact** dans le frontend
4. **Authentification** : JWT tokens
5. **Déploiement** : Railway, Render, VPS

---

## 💡 Commandes à retenir

```bash
# Backend local
npm run dev              # Développement avec hot reload
npm start                # Production

# Docker Compose
docker compose up -d     # Démarrer en arrière-plan
docker compose down      # Arrêter tout
docker compose ps        # Voir l'état
docker compose logs -f   # Voir les logs
docker compose exec backend sh  # Entrer dans le container

# Debug
docker compose logs -f backend  # Logs du backend
curl http://localhost:5001/api/health  # Tester la route
```

---

## 📚 Ressources utiles

- **Express.js** : https://expressjs.com/
- **CORS** : https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
- **Docker** : https://docs.docker.com/
- **Docker Compose** : https://docs.docker.com/compose/
- **Node.js** : https://nodejs.org/

---

## ✅ Checklist de ce qui fonctionne

- [x] Serveur backend démarre correctement
- [x] Route `/api/health` répond avec `{"status":"ok"}`
- [x] Route `/api/profile` renvoie les données
- [x] Route `/api/contact` reçoit et log les messages
- [x] CORS activé (frontend peut appeler le backend)
- [x] Dockerfile backend build sans erreur
- [x] docker-compose.yml orchestre les 2 services
- [x] Healthcheck backend fonctionnel
- [x] Variables d'environnement passées correctement
- [x] Frontend accessible sur `http://localhost:3000`
- [x] Backend accessible sur `http://localhost:5001`

---

## 🎉 Conclusion

J'ai réussi à créer une **application fullstack complète** avec :
- Un frontend React servi par Nginx
- Un backend Node.js + Express avec 3 routes API
- Le tout containerisé avec Docker et orchestré avec Docker Compose

Ce projet démontre une compréhension solide de :
- L'architecture web moderne
- Le développement backend
- La containerisation
- L'orchestration de microservices

**Date** : 6 décembre 2025
**Temps passé** : Session complète d'apprentissage
**Niveau** : De débutant en Node.js à application fullstack fonctionnelle 🚀
