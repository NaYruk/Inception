# 📚 Résumé Complet - Apprentissage Docker

**Date :** 5 décembre 2024  
**Sujet :** Docker, Dockerfile, Docker Compose pour débutants

---

## 📑 Table des matières

1. [Dockerfile - Les bases](#1-dockerfile---les-bases)
2. [Instructions Dockerfile essentielles](#2-instructions-dockerfile-essentielles)
3. [Cache Docker et Layers](#3-cache-docker-et-layers)
4. [Alpine Linux](#4-alpine-linux)
5. [Docker Compose](#5-docker-compose)
6. [Syntaxe YAML](#6-syntaxe-yaml)
7. [Services, Networks, Volumes](#7-services-networks-volumes)
8. [Configuration Nginx](#8-configuration-nginx)
9. [Exemples pratiques complets](#9-exemples-pratiques-complets)

---

## 1. Dockerfile - Les bases

### Qu'est-ce qu'un Dockerfile ?

Un **Dockerfile** est un fichier texte contenant une série d'instructions pour construire automatiquement une image Docker.

**Analogie :** C'est comme une recette de cuisine qui décrit étape par étape comment préparer votre application.

### Structure minimale

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["node", "server.js"]
```

### Instruction obligatoire

**Seule `FROM` est obligatoire** (définit l'image de base)

```dockerfile
FROM ubuntu:22.04
```

### Construire et lancer

```bash
# Construire l'image
docker build -t mon-app .

# Lancer un conteneur
docker run -p 3000:3000 mon-app
```

---

## 2. Instructions Dockerfile essentielles

### FROM - Image de base

```dockerfile
FROM node:20-alpine
FROM ubuntu:22.04
FROM nginx:alpine
```

### WORKDIR - Répertoire de travail

```dockerfile
WORKDIR /app  # Convention courante
WORKDIR /usr/src/app  # Convention Node.js
```

**Note :** `/app` n'a rien d'obligatoire, c'est juste une convention

### COPY - Copier des fichiers

```dockerfile
# Copier des fichiers spécifiques
COPY package.json package-lock.json ./

# Copier tout
COPY . .

# Multi-stage : copier depuis un autre stage
COPY --from=builder /app/dist /usr/share/nginx/html
```

### RUN - Exécuter des commandes (pendant le build)

```dockerfile
# Installation de dépendances
RUN npm ci
RUN apk add --no-cache curl

# Combiner les commandes (meilleure pratique)
RUN apt-get update && \
    apt-get install -y curl git && \
    rm -rf /var/lib/apt/lists/*
```

### CMD - Commande par défaut (au démarrage)

```dockerfile
# Exec form (recommandé)
CMD ["node", "server.js"]
CMD ["npm", "start"]

# Shell form
CMD node server.js
```

**Différence RUN vs CMD :**
- **RUN** : Exécuté pendant `docker build`
- **CMD** : Exécuté pendant `docker run`

### EXPOSE - Documenter les ports

```dockerfile
EXPOSE 3000
EXPOSE 80
```

**Note :** Purement informatif, ne publie pas réellement le port

### ENV - Variables d'environnement

```dockerfile
ENV NODE_ENV=production
ENV PORT=3000
ENV API_URL=https://api.example.com
```

### ARG - Arguments de build

```dockerfile
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-alpine

ARG BUILD_DATE
LABEL build_date=${BUILD_DATE}
```

### Ordre recommandé

```dockerfile
# 1. ARG (avant FROM si nécessaire)
ARG BASE_IMAGE=node:20-alpine

# 2. FROM
FROM ${BASE_IMAGE}

# 3. LABEL
LABEL maintainer="dev@example.com"

# 4. ENV
ENV NODE_ENV=production

# 5. WORKDIR
WORKDIR /app

# 6. Installation système
RUN apk add --no-cache curl

# 7. COPY fichiers de dépendances
COPY package*.json ./

# 8. RUN installation dépendances
RUN npm ci

# 9. COPY code source
COPY . .

# 10. RUN build
RUN npm run build

# 11. EXPOSE
EXPOSE 3000

# 12. CMD
CMD ["node", "server.js"]
```

---

## 3. Cache Docker et Layers

### Qu'est-ce qu'un Layer ?

Chaque instruction `FROM`, `RUN`, `COPY`, `ADD` crée une **couche (layer)** dans l'image.

**Visualisation :**

```
┌─────────────────────────┐
│ CMD ["node", "server"]  │ Layer 6
├─────────────────────────┤
│ COPY . .                │ Layer 5
├─────────────────────────┤
│ RUN npm install         │ Layer 4
├─────────────────────────┤
│ COPY package.json       │ Layer 3
├─────────────────────────┤
│ WORKDIR /app            │ Layer 2
├─────────────────────────┤
│ FROM node:20-alpine     │ Layer 1
└─────────────────────────┘
```

### Le Cache Docker

**Principe :** Docker met en cache chaque layer. Si rien n'a changé, il réutilise le cache.

### Règle d'or

**Dès qu'un layer est invalidé, TOUS les layers suivants sont aussi invalidés !**

### ❌ Mauvais ordre (pas optimisé)

```dockerfile
FROM node:20-alpine
WORKDIR /app

# ❌ On copie tout le code EN PREMIER
COPY . .

# Puis on installe les dépendances
RUN npm install
```

**Problème :** Chaque modification de code = rebuild complet (2 minutes)

### ✅ Bon ordre (optimisé)

```dockerfile
FROM node:20-alpine
WORKDIR /app

# ✅ D'abord les fichiers de dépendances (changent rarement)
COPY package*.json ./

# Installer les dépendances
RUN npm ci

# ✅ Ensuite le code source (change souvent)
COPY . .
```

**Avantage :** Modification de code = rebuild rapide (5 secondes)

### Principe d'optimisation

**Ordre : Du moins fréquent au plus fréquent**

1. Image de base (ne change quasi jamais)
2. Packages système (rare)
3. Fichiers de dépendances (occasionnel)
4. Installation des dépendances (occasionnel)
5. Code source (change tout le temps)

### .dockerignore

Créer un fichier `.dockerignore` pour éviter de copier des fichiers inutiles :

```
node_modules
npm-debug.log
.git
.env
dist
build
*.md
.vscode
```

---

## 4. Alpine Linux

### Pourquoi Alpine est légère ?

**Comparaison de taille :**

```dockerfile
FROM ubuntu:22.04        # ~77 MB
FROM debian:bullseye     # ~124 MB
FROM node:20             # ~1.1 GB
FROM node:20-alpine      # ~180 MB (6x plus petit !)
```

### 5 raisons principales

1. **musl libc** au lieu de glibc (15x plus petit)
2. **BusyBox** : 400 commandes UNIX dans un seul fichier
3. **apk** : gestionnaire de packages minimaliste
4. **Philosophie minimaliste** : seulement l'essentiel
5. **Pas de bloat** : pas de docs, locales, outils inutiles

### ✅ Quand utiliser Alpine

- Application simple (Node.js, Python, Go)
- Vous construisez depuis les sources (npm install, pip install)
- Production (optimisation importante)
- Microservices

### ❌ Quand éviter Alpine

- Binaires pré-compilés nécessaires (dépendants de glibc)
- Packages exotiques non disponibles
- Scripts bash complexes
- Legacy applications

### Pour une SPA : Alpine est parfait !

```dockerfile
FROM node:20-alpine AS builder
# npm fonctionne parfaitement
# Pas de binaires pré-compilés nécessaires

FROM nginx:alpine
# Parfait pour servir des fichiers statiques
# Image finale de ~40 MB au lieu de 200 MB
```

---

## 5. Docker Compose

### Différence Dockerfile vs Docker Compose

| Aspect | Dockerfile | Docker Compose |
|--------|-----------|----------------|
| **But** | Construire UNE image | Orchestrer PLUSIEURS conteneurs |
| **Format** | Instructions | YAML |
| **Commande** | `docker build` | `docker-compose up` |
| **Résultat** | 1 image | Plusieurs conteneurs qui tournent |
| **Fichier** | `Dockerfile` | `docker-compose.yml` |

### Analogie

- **Dockerfile** = Plan de construction d'une maison
- **Docker Compose** = Plan d'urbanisme d'un quartier entier

### Exemple simple

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:80"
  
  backend:
    build: ./backend
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=mongodb://database:27017
  
  database:
    image: mongo:7
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

**Une seule commande :**

```bash
docker-compose up
# Lance automatiquement les 3 conteneurs !
```

### Ce que Docker Compose fait automatiquement

1. ✅ Crée le réseau
2. ✅ Gère l'ordre de démarrage
3. ✅ Construit les images
4. ✅ Gère les volumes
5. ✅ Configure les ports
6. ✅ Transmet les variables d'environnement
7. ✅ Affiche les logs en temps réel

### Commandes essentielles

```bash
# Démarrer tout (premier plan avec logs)
docker-compose up

# Démarrer en arrière-plan
docker-compose up -d

# Arrêter tout
docker-compose down

# Arrêter et supprimer volumes (⚠️ données perdues)
docker-compose down -v

# Reconstruire et redémarrer
docker-compose up --build

# Voir les logs
docker-compose logs
docker-compose logs -f  # Temps réel
docker-compose logs backend  # Service spécifique

# Voir l'état
docker-compose ps

# Entrer dans un conteneur
docker-compose exec backend sh
```

---

## 6. Syntaxe YAML

### Qu'est-ce que YAML ?

**YAML** = Format de fichier pour structurer des données de manière lisible par les humains.

### Pourquoi YAML pour Docker Compose ?

1. ✅ **Lisible** : Facile à comprendre
2. ✅ **Simple** : Moins de syntaxe que JSON/XML
3. ✅ **Standard** : Utilisé dans tout DevOps
4. ✅ **Commentaires** : Possibilité de documenter

### Règles de base

#### 1. Indentation obligatoire (2 espaces, PAS de tabs)

```yaml
# ✅ CORRECT
services:
  backend:
    image: node

# ❌ INCORRECT : tabs
services:
	backend:
		image: node
```

#### 2. Clé : Valeur (espace après `:` obligatoire)

```yaml
nom: Jean      # ✅ CORRECT
nom:Jean       # ❌ INCORRECT
```

#### 3. Objets (dictionnaires)

```yaml
personne:
  nom: Jean
  age: 30
  adresse:
    ville: Paris
```

#### 4. Listes (avec tirets `-`)

```yaml
fruits:
  - pomme
  - banane
  - orange

# Ou en ligne
fruits: [pomme, banane, orange]
```

#### 5. Commentaires

```yaml
# Ceci est un commentaire
services:
  backend:  # Commentaire en fin de ligne
    image: node
```

### Structure Docker Compose

```yaml
version: '3.8'          # Version obligatoire

services:               # Services (conteneurs)
  nom-service:
    # Configuration

volumes:                # Volumes
  nom-volume:

networks:               # Réseaux
  nom-reseau:
```

### Validation

```bash
# Valider la syntaxe
docker-compose config
```

---

## 7. Services, Networks, Volumes

### SERVICES = Les conteneurs (QUOI)

**Un service = un conteneur qui tourne**

```yaml
services:
  frontend:    # Service 1
  backend:     # Service 2
  database:    # Service 3
```

**Configuration d'un service :**

```yaml
services:
  backend:
    image: node:20-alpine     # OU
    build: ./backend          # Dockerfile
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=production
    volumes:
      - ./backend:/app
    networks:
      - app-network
    depends_on:
      - database
    restart: unless-stopped
```

### NETWORKS = La communication (COMMENT)

**Un network = réseau virtuel pour que les conteneurs communiquent**

#### Réseau par défaut

Docker Compose crée automatiquement un réseau où tous les services peuvent communiquer par leur nom :

```yaml
services:
  backend:
    # ...
  database:
    # ...

# Les services peuvent s'appeler directement :
# DATABASE_URL=postgresql://database:5432/myapp
```

#### Réseaux personnalisés (isolation)

```yaml
services:
  frontend:
    networks:
      - frontend-network
  
  backend:
    networks:
      - frontend-network
      - backend-network
  
  database:
    networks:
      - backend-network  # Isolé du frontend

networks:
  frontend-network:
  backend-network:
```

**Avantage :** Frontend ne peut PAS accéder directement à la database

### VOLUMES = Le stockage (OÙ)

**Un volume = espace de stockage pour persister les données**

#### Type 1 : Volume nommé (persistance)

```yaml
services:
  database:
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:  # Géré par Docker
```

**Utilisation :** Bases de données, uploads, données importantes

#### Type 2 : Bind Mount (développement)

```yaml
services:
  backend:
    volumes:
      - ./backend/src:/app/src  # Dossier local → conteneur
```

**Utilisation :** Hot reload, accès aux fichiers localement

#### Type 3 : Volume anonyme

```yaml
services:
  app:
    volumes:
      - /app/node_modules  # Pas de nom
```

**Utilisation :** Rare, supprimé avec `docker-compose down -v`

### Gestion des volumes

```bash
# Lister les volumes
docker volume ls

# Inspecter un volume
docker volume inspect mon-projet_postgres-data

# Supprimer un volume
docker volume rm mon-projet_postgres-data

# Supprimer tous les volumes non utilisés
docker volume prune
```

### ⚠️ Comportement avec docker-compose down

```bash
docker-compose down
# ✅ CONSERVE : Les volumes nommés
# ✅ SUPPRIME : Conteneurs, réseaux

docker-compose down -v
# ⚠️ SUPPRIME AUSSI : Les volumes (données perdues !)
```

---

## 8. Configuration Nginx

### Pourquoi Nginx ?

**Nginx** = serveur web ultra-léger pour servir des fichiers statiques.

### Pour une SPA : Nginx EST nécessaire

**Problème sans Nginx :**

Après `npm run build`, votre SPA devient des fichiers HTML/CSS/JS statiques. Vous n'avez plus besoin de Node.js !

**Solution multi-stage :**

```dockerfile
# Build avec Node.js
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production avec Nginx (25 MB vs 180 MB)
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
```

### Configuration minimale pour SPA

**nginx.conf :**

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    sendfile on;
    gzip on;
    
    server {
        listen 80;
        root /usr/share/nginx/html;
        index index.html;
        
        # CRUCIAL pour les SPA (React Router, Vue Router...)
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
```

### La ligne magique pour les SPA

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

**Explication :**

1. Nginx cherche le fichier demandé
2. Si pas trouvé, cherche un dossier
3. Si toujours pas trouvé, renvoie `index.html`
4. React Router prend le relais et affiche la bonne page !

**Résultat :**

```
https://monsite.com/          → index.html ✅
https://monsite.com/about     → index.html → React Router ✅
https://monsite.com/products  → index.html → React Router ✅
```

### Configuration optimisée

```nginx
events {
    worker_connections 2048;
}

http {
    include /etc/nginx/mime.types;
    sendfile on;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    
    server {
        listen 80;
        root /usr/share/nginx/html;
        index index.html;
        
        # SPA routing
        location / {
            try_files $uri $uri/ /index.html;
        }
        
        # Cache pour assets statiques
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        # Pas de cache pour index.html
        location = /index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            expires 0;
        }
        
        # Headers de sécurité
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
    }
}
```

### Proxy vers un backend

Si vous avez une API séparée :

```nginx
server {
    listen 80;
    
    # Frontend
    location / {
        root /usr/share/nginx/html;
        try_files $uri $uri/ /index.html;
    }
    
    # API Backend
    location /api {
        proxy_pass http://backend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 9. Exemples pratiques complets

### Exemple 1 : SPA simple (Frontend uniquement)

**Structure :**

```
mon-projet/
├── src/
├── public/
├── package.json
├── Dockerfile
└── nginx.conf
```

**Dockerfile :**

```dockerfile
# ========== BUILD STAGE ==========
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ========== PRODUCTION STAGE ==========
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
```

**nginx.conf :**

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    sendfile on;
    gzip on;
    
    server {
        listen 80;
        root /usr/share/nginx/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ /index.html;
        }
    }
}
```

**Commandes :**

```bash
# Build
docker build -t mon-spa .

# Run
docker run -p 8080:80 mon-spa

# Accès : http://localhost:8080
```

---

### Exemple 2 : Full-stack avec Docker Compose

**Structure :**

```
mon-projet/
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── src/
├── backend/
│   ├── Dockerfile
│   └── src/
├── docker-compose.yml
└── .env
```

**frontend/Dockerfile :**

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
```

**backend/Dockerfile :**

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 4000
CMD ["node", "src/server.js"]
```

**docker-compose.yml :**

```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    container_name: app-frontend
    ports:
      - "3000:80"
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    build: ./backend
    container_name: app-backend
    ports:
      - "4000:4000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@database:5432/${DB_NAME}
    depends_on:
      - database
    networks:
      - app-network
    restart: unless-stopped

  database:
    image: postgres:16-alpine
    container_name: app-database
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network
    restart: unless-stopped

volumes:
  postgres-data:
    driver: local

networks:
  app-network:
    driver: bridge
```

**.env :**

```
DB_NAME=myapp
DB_PASSWORD=supersecretpassword
```

**Commandes :**

```bash
# Lancer tout
docker-compose up -d

# Voir l'état
docker-compose ps

# Logs
docker-compose logs -f

# Arrêter
docker-compose down

# Frontend : http://localhost:3000
# Backend : http://localhost:4000
```

---

## 📝 Points clés à retenir

### Dockerfile

- ✅ `FROM` est la seule instruction obligatoire
- ✅ Optimiser l'ordre : dépendances avant code source
- ✅ Utiliser Alpine pour des images légères
- ✅ Multi-stage pour production (build + run séparé)
- ✅ `.dockerignore` pour éviter de copier des fichiers inutiles

### Docker Compose

- ✅ Un fichier YAML pour orchestrer plusieurs conteneurs
- ✅ Une seule commande : `docker-compose up`
- ✅ Services = conteneurs (QUOI)
- ✅ Networks = communication (COMMENT)
- ✅ Volumes = persistance (OÙ)

### Nginx pour SPA

- ✅ Nginx nécessaire pour router les SPA
- ✅ Ligne magique : `try_files $uri $uri/ /index.html;`
- ✅ Multi-stage pour images ultra-légères (~40 MB)

### Cache et optimisation

- ✅ Chaque instruction = 1 layer
- ✅ Docker met en cache les layers
- ✅ Ordre : du moins fréquent au plus fréquent
- ✅ Layer invalidé = tous les suivants invalidés

### YAML

- ✅ 2 espaces (jamais de tabs)
- ✅ Espace après `:` obligatoire
- ✅ Tirets `-` pour les listes
- ✅ Validation : `docker-compose config`

---

## 🚀 Workflow typique

### Développement

```bash
# 1. Créer le projet
npm create vite@latest mon-app

# 2. Créer Dockerfile et nginx.conf

# 3. Tester localement
docker build -t mon-app .
docker run -p 8080:80 mon-app

# 4. Vérifier : http://localhost:8080
```

### Production avec Compose

```bash
# 1. Créer docker-compose.yml

# 2. Lancer tout
docker-compose up -d

# 3. Vérifier
docker-compose ps
docker-compose logs

# 4. Accéder aux services
```

---

## 📚 Ressources utiles

### Commandes essentielles

```bash
# Docker
docker build -t nom-image .
docker run -p host:conteneur nom-image
docker ps
docker logs conteneur
docker exec -it conteneur sh
docker stop conteneur
docker rm conteneur
docker rmi image

# Docker Compose
docker-compose up
docker-compose up -d
docker-compose down
docker-compose down -v
docker-compose logs
docker-compose ps
docker-compose exec service sh

# Volumes
docker volume ls
docker volume inspect nom-volume
docker volume rm nom-volume
docker volume prune

# Networks
docker network ls
docker network inspect nom-network
```

### Validation

```bash
# Dockerfile : vérifier la syntaxe
docker build --no-cache -t test .

# Docker Compose : valider YAML
docker-compose config

# Nginx : tester la config
docker exec conteneur nginx -t
```

---

## ✅ Checklist avant déploiement

- [ ] `.dockerignore` créé (node_modules, .git, etc.)
- [ ] Multi-stage build utilisé pour production
- [ ] Images Alpine pour minimiser la taille
- [ ] Volumes configurés pour données persistantes
- [ ] Variables sensibles dans `.env` (pas dans le code)
- [ ] Ports correctement mappés
- [ ] Nginx configuré avec `try_files` pour SPA
- [ ] `restart: unless-stopped` pour services critiques
- [ ] Networks configurés pour isolation si nécessaire
- [ ] Tests effectués avec `docker-compose up`

---

## 🎯 Prochaines étapes

1. **Pratiquer** : Créer plusieurs projets avec Docker
2. **Explorer** : Kubernetes pour l'orchestration à grande échelle
3. **Sécurité** : Apprendre les best practices de sécurité Docker
4. **CI/CD** : Intégrer Docker dans un pipeline d'intégration continue
5. **Monitoring** : Mettre en place la surveillance des conteneurs

---

**Bon apprentissage Docker ! 🐳**
