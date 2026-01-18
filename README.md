# 📚 GUIDE COMPLET - PROJET INCEPTION

## 🚀 INSTALLATION RAPIDE

### 1. Cloner le projet
```bash
git clone <votre_repo>
cd Inception
```

### 2. Configurer les variables d'environnement
```bash
cp srcs/.env.example srcs/.env
```

Puis éditez `srcs/.env` avec vos propres valeurs :
- Remplacez `your_login` par votre login 42
- Changez tous les mots de passe
- Adaptez les emails

### 3. Lancer le projet
```bash
make
```

Le site sera accessible sur `https://your_login.42.fr` (après avoir accepté le certificat SSL auto-signé dans votre navigateur).

### 4. Nettoyage
```bash
make fclean    # Supprime tout
make re        # Nettoie et reconstruit
```

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble du projet](#vue-densemble-du-projet)
2. [Architecture globale](#architecture-globale)
3. [Docker : Concepts fondamentaux](#docker-concepts-fondamentaux)
4. [Docker Compose : Orchestration](#docker-compose-orchestration)
5. [Service MariaDB](#service-mariadb)
6. [Service WordPress](#service-wordpress)
7. [Service Nginx](#service-nginx)
8. [Réseaux Docker](#réseaux-docker)
9. [Volumes Docker](#volumes-docker)
10. [Variables d'environnement](#variables-denvironnement)
11. [SSL/TLS et Certificats](#ssltls-et-certificats)
12. [Communication entre conteneurs](#communication-entre-conteneurs)
13. [Flux de démarrage complet](#flux-de-démarrage-complet)
14. [Commandes et debugging](#commandes-et-debugging)
15. [Glossaire technique complet](#glossaire-technique-complet)

---

# 🎯 VUE D'ENSEMBLE DU PROJET

## Qu'est-ce qu'Inception ?

Inception est un projet qui consiste à créer une **infrastructure web complète** en utilisant Docker. Vous créez un site WordPress accessible via HTTPS, avec une base de données MariaDB, le tout orchestré par Docker Compose.

## Les 3 composants principaux

```
┌─────────────────────────────────────────────────────────────┐
│                         VOTRE MAC                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    DOCKER ENGINE                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   NGINX     │  │  WORDPRESS  │  │  MARIADB    │   │  │
│  │  │ (Serveur    │←→│  (PHP-FPM)  │←→│ (Base de    │   │  │
│  │  │  Web)       │  │             │  │  données)   │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  │         ↓                 ↓                ↓           │  │
│  │    [Volume]          [Volume]         [Volume]        │  │
│  │   wordpress_data    wordpress_data   mariadb_data     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         ↑
    Navigateur → https://mmilliot.42.fr (port 443)
```

### Rôle de chaque service

| Service | Rôle | Technologie |
|---------|------|-------------|
| **Nginx** | Serveur web qui reçoit les requêtes HTTPS et gère le SSL | Debian + Nginx |
| **WordPress** | Génère les pages web dynamiques (PHP) | Debian + PHP-FPM + WordPress |
| **MariaDB** | Stocke toutes les données (articles, utilisateurs, etc.) | Debian + MariaDB |

---

# 🏗️ ARCHITECTURE GLOBALE

## Structure du projet

```
Inception/
├── Makefile                           # Commandes de gestion (à créer)
├── GUIDE_COMPLET_INCEPTION.md         # Ce fichier
├── srcs/
│   ├── .env                           # Variables d'environnement
│   ├── docker-compose.yml             # Orchestration des services
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile             # Instructions pour construire l'image Nginx
│       │   ├── .dockerignore          # Fichiers à ignorer lors du build
│       │   ├── conf/
│       │   │   └── nginx.conf         # Configuration du serveur web
│       │   └── tools/
│       │       └── entrypoint.sh      # Script de démarrage
│       ├── mariadb/
│       │   ├── Dockerfile             # Instructions pour construire l'image MariaDB
│       │   ├── .dockerignore
│       │   ├── conf/
│       │   │   └── 99-custom.cnf      # Configuration MySQL
│       │   └── tools/
│       │       └── init.sh            # Script d'initialisation de la base
│       └── wordpress/
│           ├── Dockerfile             # Instructions pour construire l'image WordPress
│           ├── .dockerignore
│           ├── conf/
│           │   └── www.conf           # Configuration PHP-FPM
│           └── tools/
│               └── wp-cli.sh          # Script d'installation WordPress
```

---

# 🐳 DOCKER : CONCEPTS FONDAMENTAUX

## Qu'est-ce que Docker ?

Docker est une plateforme qui permet d'**isoler des applications** dans des **conteneurs**. Imaginez des boîtes hermétiques qui contiennent tout ce dont une application a besoin pour fonctionner.

### Analogie de la machine virtuelle vs Docker

```
┌─────────────────────────────────────────────────────────────┐
│               MACHINE VIRTUELLE (VM)                         │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │   App A       │  │   App B       │  │   App C       │   │
│  ├───────────────┤  ├───────────────┤  ├───────────────┤   │
│  │  OS Invité    │  │  OS Invité    │  │  OS Invité    │   │
│  │  (Linux)      │  │  (Linux)      │  │  (Linux)      │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              HYPERVISEUR (VirtualBox, VMware)         │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   OS HÔTE (macOS)                     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
Poids : ~5GB par VM | Lent à démarrer (minutes)
```

```
┌─────────────────────────────────────────────────────────────┐
│                      DOCKER                                  │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐               │
│  │  App A    │  │  App B    │  │  App C    │               │
│  │ (Nginx)   │  │(WordPress)│  │ (MariaDB) │               │
│  └───────────┘  └───────────┘  └───────────┘               │
│         Conteneurs (isolation légère)                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              DOCKER ENGINE                            │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   OS HÔTE (macOS)                     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
Poids : ~100MB par conteneur | Rapide à démarrer (secondes)
```

## Les concepts clés

### 1. Image Docker

Une **image** est un **modèle en lecture seule** qui contient :
- Un système d'exploitation de base (Debian dans votre cas)
- Des programmes installés (Nginx, PHP, MariaDB)
- Des fichiers de configuration
- Des scripts

**Analogie** : C'est comme un DVD d'installation ou une recette de cuisine.

```
┌─────────────────────────────────────┐
│         IMAGE DOCKER                │
│  (debian:bookworm)                  │
│  ┌───────────────────────────────┐  │
│  │ Couche 4: Scripts             │  │ ← COPY tools/entrypoint.sh
│  ├───────────────────────────────┤  │
│  │ Couche 3: Configuration       │  │ ← COPY conf/nginx.conf
│  ├───────────────────────────────┤  │
│  │ Couche 2: Nginx installé      │  │ ← RUN apt install nginx
│  ├───────────────────────────────┤  │
│  │ Couche 1: Debian bookworm     │  │ ← FROM debian:bookworm
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 2. Conteneur Docker

Un **conteneur** est une **instance en cours d'exécution** d'une image. C'est l'image qui "prend vie".

**Analogie** : Si l'image est une recette, le conteneur est le plat cuisiné que vous mangez.

```
IMAGE                         CONTENEUR
(modèle)                     (instance vivante)
   │                              │
   │  docker run                  │
   └──────────────────────────────┘
```

Vous pouvez créer **plusieurs conteneurs** à partir de la **même image** :

```
┌──────────────┐
│ Image Nginx  │
└──────┬───────┘
       ├──────→ Conteneur Nginx 1 (votre projet Inception)
       ├──────→ Conteneur Nginx 2 (autre projet)
       └──────→ Conteneur Nginx 3 (encore un autre)
```

### 3. Dockerfile

Le **Dockerfile** est le **fichier d'instructions** pour construire une image.

**Analogie** : C'est la recette de cuisine détaillée étape par étape.

```dockerfile
# Exemple simplifié de Dockerfile
FROM debian:bookworm           # Partir de Debian
RUN apt update                 # Mettre à jour les paquets
RUN apt install -y nginx       # Installer Nginx
COPY nginx.conf /etc/nginx/    # Copier la configuration
CMD ["nginx", "-g", "daemon off;"]  # Commande au démarrage
```

### 4. Docker Engine

Le **Docker Engine** est le moteur qui fait tourner les conteneurs sur votre Mac.

**Composants** :
- **Docker Daemon** : Processus en arrière-plan qui gère les conteneurs
- **Docker CLI** : L'outil en ligne de commande (`docker`, `docker-compose`)
- **Docker API** : Interface pour communiquer avec le daemon

```
Vous tapez:                   Docker Daemon:
docker-compose up    ──────→  - Lit docker-compose.yml
                              - Crée les réseaux
                              - Crée les volumes
                              - Démarre les conteneurs
                              - Configure la communication
```

---

# 🎭 DOCKER COMPOSE : ORCHESTRATION

## Qu'est-ce que Docker Compose ?

Docker Compose est un outil pour **définir et gérer des applications multi-conteneurs**. Au lieu de lancer manuellement chaque conteneur, vous écrivez un fichier YAML qui décrit toute votre infrastructure.

## Le fichier docker-compose.yml

C'est le **chef d'orchestre** de votre projet. Analysons-le ligne par ligne.

### Structure globale

```yaml
services:           # Liste de tous vos conteneurs
  mariadb:          # Nom du service 1
    # configuration

  wordpress:        # Nom du service 2
    # configuration

  nginx:            # Nom du service 3
    # configuration

networks:           # Réseaux pour la communication
  inception:
    # configuration

volumes:            # Stockage persistant
  mariadb_data:
    # configuration
  wordpress_data:
    # configuration
```

### Service MariaDB détaillé

```yaml
  mariadb:
```
**Explication** : Nom du service. C'est aussi le **nom DNS** dans le réseau Docker (les autres conteneurs peuvent faire `ping mariadb`).

```yaml
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
```
**Explication** :
- `build` : Indique qu'on construit l'image nous-mêmes (pas téléchargée du Docker Hub)
- `context` : Répertoire contenant les fichiers nécessaires au build
- `dockerfile` : Nom du fichier Dockerfile (optionnel si c'est "Dockerfile")

```yaml
    container_name: mariadb
```
**Explication** : Nom du conteneur une fois créé. Visible avec `docker ps`.

```yaml
    restart: always
```
**Explication** : Politique de redémarrage
- `always` : Redémarre toujours si le conteneur s'arrête (même après un crash)
- Autres options : `no`, `on-failure`, `unless-stopped`

```yaml
    volumes:
      - mariadb_data:/var/lib/mysql
```
**Explication** :
- `mariadb_data` : Nom du volume (défini en bas du fichier)
- `/var/lib/mysql` : Répertoire **dans le conteneur** où MariaDB stocke ses données
- Le `:` sépare le volume (gauche) du point de montage (droite)

**Schéma** :
```
HÔTE (Mac)                    CONTENEUR MariaDB
┌──────────────────┐          ┌──────────────────┐
│ Volume Docker    │  montage │ /var/lib/mysql/  │
│ mariadb_data     │ ────────→│ - base1/         │
│ (géré par Docker)│          │ - base2/         │
└──────────────────┘          └──────────────────┘
```

```yaml
    networks:
      - inception
```
**Explication** : Connecte ce conteneur au réseau `inception`. Tous les services sur ce réseau peuvent communiquer entre eux.

```yaml
    env_file:
      - .env
```
**Explication** : Charge les variables d'environnement depuis le fichier `.env`. Ces variables seront accessibles dans le conteneur.

```yaml
    expose:
      - "3306"
```
**Explication** :
- Expose le port 3306 **uniquement au réseau interne Docker**
- Ce port **n'est PAS accessible depuis votre Mac**
- Seuls les autres conteneurs (Nginx, WordPress) peuvent y accéder

**Différence avec `ports`** :
```yaml
expose:        # Interne uniquement
  - "3306"

ports:         # Accessible depuis l'hôte
  - "3306:3306"
```

### Service WordPress détaillé

```yaml
  wordpress:
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    container_name: wordpress
    restart: always
```
**Explication** : Similaire à MariaDB

```yaml
    volumes:
      - wordpress_data:/var/www/html
```
**Explication** :
- `/var/www/html` : Répertoire standard pour les sites web sous Linux
- C'est ici que WordPress sera installé (fichiers PHP, images, thèmes, etc.)

```yaml
    networks:
      - inception
```
**Explication** : Sur le même réseau que MariaDB et Nginx

```yaml
    depends_on:
      - mariadb
```
**Explication** :
- Docker Compose démarre MariaDB **avant** WordPress
- **IMPORTANT** : `depends_on` attend que le conteneur démarre, PAS que le service soit prêt
- C'est pourquoi votre script `wp-cli.sh` fait une boucle pour attendre que MariaDB soit vraiment prêt

```yaml
    env_file:
      - .env
```
**Explication** : Variables d'environnement chargées (URL WordPress, identifiants, etc.)

```yaml
    expose:
      - "9000"
```
**Explication** : Port 9000 pour PHP-FPM, accessible uniquement par Nginx

### Service Nginx détaillé

```yaml
  nginx:
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    container_name: nginx
    restart: always
```
**Explication** : Configuration classique

```yaml
    ports:
      - "443:443"
```
**Explication** :
- **DIFFÉRENT d'`expose`** : ici le port est **accessible depuis votre Mac**
- `443:443` signifie : port 443 de l'hôte (Mac) → port 443 du conteneur
- Format : `HOST_PORT:CONTAINER_PORT`
- Vous pouvez faire `8443:443` si le port 443 est déjà utilisé sur votre Mac

```yaml
    volumes:
      - wordpress_data:/var/www/html
```
**Explication** :
- **Même volume** que WordPress !
- Nginx a besoin d'accéder aux fichiers statiques de WordPress (CSS, JS, images)

**Schéma** :
```
┌──────────────────┐          ┌──────────────────┐
│ Conteneur Nginx  │          │ Conteneur WP     │
│ /var/www/html/   │          │ /var/www/html/   │
│ - index.php      │          │ - index.php      │
│ - style.css      │          │ - style.css      │
└────────┬─────────┘          └────────┬─────────┘
         │                             │
         └────────────┬────────────────┘
                      ↓
            ┌──────────────────┐
            │ wordpress_data   │
            │ (Volume partagé) │
            └──────────────────┘
```

```yaml
    networks:
      - inception
```
**Explication** : Sur le réseau `inception`

```yaml
    depends_on:
      - mariadb
      - wordpress
```
**Explication** : Nginx démarre en dernier (après MariaDB et WordPress)

### Section Networks

```yaml
networks:
  inception:
    driver: bridge
```
**Explication** :
- Crée un réseau nommé `inception`
- `driver: bridge` : Type de réseau (par défaut)
  - **Bridge** : Réseau privé interne à Docker
  - Les conteneurs peuvent communiquer entre eux
  - Isolation du réseau de l'hôte

**Schéma du réseau** :
```
┌─────────────────────────────────────────────────────────┐
│            Réseau Docker "inception"                     │
│          (172.18.0.0/16 par exemple)                     │
│                                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Nginx     │  │  WordPress  │  │  MariaDB    │     │
│  │ 172.18.0.4  │  │ 172.18.0.3  │  │ 172.18.0.2  │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│         │                 │                │             │
│         └─────────────────┴────────────────┘             │
│              DNS interne Docker                          │
│        (nginx → 172.18.0.4)                              │
│        (wordpress → 172.18.0.3)                          │
│        (mariadb → 172.18.0.2)                            │
└─────────────────────────────────────────────────────────┘
                      │
                      │ Port mapping 443:443
                      ↓
              ┌───────────────┐
              │  Hôte (Mac)   │
              │  localhost    │
              └───────────────┘
```

### Section Volumes

```yaml
volumes:
  mariadb_data:
    driver: local

  wordpress_data:
    driver: local
```
**Explication** :
- `driver: local` : Volume géré localement par Docker
- Docker crée ces volumes dans son propre espace de stockage
- Sur Mac : `/var/lib/docker/volumes/` (dans la VM Docker Desktop)

**Avantages des volumes Docker** :
1. **Persistance** : Les données survivent même si vous supprimez le conteneur
2. **Performance** : Plus rapide que des bind mounts sur Mac/Windows
3. **Portabilité** : Fonctionnent sur tous les systèmes

---

# 🗄️ SERVICE MARIADB

## Qu'est-ce que MariaDB ?

MariaDB est un **système de gestion de base de données relationnelle** (SGBD). C'est un fork (copie améliorée) de MySQL, créé par les développeurs originaux de MySQL.

### Pourquoi MariaDB et pas MySQL ?

- **Open source** : Complètement libre
- **Compatible** : Syntaxe identique à MySQL
- **Performant** : Optimisations supplémentaires
- **Standard** : Utilisé par défaut dans Debian

## Le Dockerfile MariaDB

```dockerfile
FROM debian:bookworm
```
**Explication** :
- `FROM` : Instruction de base, toujours en premier
- `debian:bookworm` : Image de base
  - `debian` : Distribution Linux
  - `bookworm` : Version stable de Debian (la 12)
  - Cette image vient du Docker Hub (dépôt officiel)

```dockerfile
RUN apt update && apt install -y mariadb-server \
    && rm -rf /var/lib/apt/lists/*
```
**Explication** :
- `RUN` : Exécute une commande lors du build
- `apt update` : Met à jour la liste des paquets disponibles
- `&&` : "ET" logique, exécute la commande suivante seulement si la précédente réussit
- `apt install -y mariadb-server` :
  - `install` : Installe un paquet
  - `-y` : Répond "yes" automatiquement aux questions
  - `mariadb-server` : Nom du paquet
- `\` : Continue la commande sur la ligne suivante (lisibilité)
- `rm -rf /var/lib/apt/lists/*` : Supprime les listes de paquets pour réduire la taille de l'image

```dockerfile
COPY conf/99-custom.cnf /etc/mysql/mariadb.conf.d/
```
**Explication** :
- `COPY` : Copie un fichier depuis l'hôte vers l'image
- `conf/99-custom.cnf` : Fichier source (sur votre Mac)
- `/etc/mysql/mariadb.conf.d/` : Destination dans l'image
  - Ce répertoire est scanné par MariaDB au démarrage
  - Les fichiers `.cnf` sont des fichiers de configuration MySQL/MariaDB

```dockerfile
COPY tools/init.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init.sh
```
**Explication** :
- Copie le script d'initialisation
- `chmod +x` : Rend le fichier exécutable
  - `chmod` : Change mode (permissions)
  - `+x` : Ajoute le droit d'exécution

```dockerfile
EXPOSE 3306
```
**Explication** :
- `EXPOSE` : Documente quel port le conteneur utilise
- `3306` : Port par défaut de MySQL/MariaDB
- **NOTE** : C'est juste de la documentation ! Il faut aussi le déclarer dans `docker-compose.yml`

```dockerfile
CMD ["init.sh"]
```
**Explication** :
- `CMD` : Commande par défaut à exécuter au démarrage du conteneur
- `["init.sh"]` : Format "exec" (recommandé)
- Alternative : `CMD init.sh` (format shell)

## Le fichier de configuration 99-custom.cnf

```ini
[mysqld]
```
**Explication** :
- Section de configuration pour le serveur MySQL (mysqld = MySQL daemon)
- Toutes les directives qui suivent s'appliquent au serveur

```ini
bind-address = 0.0.0.0
```
**Explication** :
- `bind-address` : Adresse IP sur laquelle MariaDB écoute
- `0.0.0.0` : Écoute sur **toutes les interfaces réseau**
- Par défaut, MariaDB écoute sur `127.0.0.1` (localhost uniquement)
- **Nécessaire** dans Docker pour que les autres conteneurs puissent se connecter

**Schéma** :
```
127.0.0.1 (défaut)              0.0.0.0 (votre config)
┌───────────────────┐          ┌───────────────────┐
│ Seulement localhost│          │ Toutes interfaces │
│                   │          │                   │
│ localhost ✓       │          │ localhost ✓       │
│ réseau ✗          │          │ réseau ✓          │
└───────────────────┘          └───────────────────┘
```

```ini
port = 3306
```
**Explication** : Port d'écoute (3306 est le port standard MySQL/MariaDB)

```ini
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
```
**Explication** :
- `character-set` : Jeu de caractères pour stocker le texte
- `utf8mb4` : Version étendue d'UTF-8 qui supporte les emojis et caractères spéciaux
- `collation` : Règles de comparaison et tri des caractères
- `utf8mb4_general_ci` :
  - `general` : Tri général (rapide)
  - `ci` : Case Insensitive (insensible à la casse, 'A' = 'a')

```ini
lower_case_table_names = 1
```
**Explication** :
- Force les noms de tables en minuscules
- `1` : Active cette option
- **Utile sur macOS** : macOS a un système de fichiers insensible à la casse par défaut
- Évite les problèmes de portabilité entre Linux (sensible à la casse) et macOS

```ini
log_error = /var/log/mysql/error.log
```
**Explication** :
- Fichier où MariaDB écrit les erreurs
- Utile pour le debugging

## Le script d'initialisation init.sh

Analysons ce script ligne par ligne :

```bash
#!/bin/bash
```
**Explication** :
- **Shebang** : Indique quel interpréteur utiliser
- `/bin/bash` : Utilise le shell Bash

```bash
set -e
```
**Explication** :
- Active le mode "exit on error"
- Si une commande échoue (code de retour != 0), le script s'arrête immédiatement
- **Sécurité** : Évite de continuer avec des états incohérents

```bash
mkdir -p /run/mysqld /var/log/mysql
```
**Explication** :
- `mkdir` : Crée des répertoires
- `-p` : Crée les répertoires parents si nécessaire, pas d'erreur s'ils existent déjà
- `/run/mysqld` : Répertoire pour le fichier socket Unix de MySQL
- `/var/log/mysql` : Répertoire pour les logs

```bash
chown -R mysql:mysql /run/mysqld /var/log/mysql /var/lib/mysql
```
**Explication** :
- `chown` : Change le propriétaire des fichiers
- `-R` : Récursif (tous les fichiers et sous-répertoires)
- `mysql:mysql` : Utilisateur:Groupe
  - L'utilisateur `mysql` est créé automatiquement lors de l'installation de `mariadb-server`
- **Nécessaire** : MariaDB doit avoir les droits d'écriture sur ces répertoires

```bash
if [ ! -f /var/lib/mysql/.db_configured ]; then
```
**Explication** :
- `if` : Structure conditionnelle
- `[ ... ]` : Test de condition
- `!` : Négation (NOT)
- `-f` : Teste si un fichier existe
- **Logique** : "Si le fichier `.db_configured` n'existe PAS"
- **But** : Idempotence - ne configure qu'une seule fois

```bash
    echo "Première initialisation de MariaDB..."
```
**Explication** : Affiche un message (visible avec `docker-compose logs`)

```bash
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
```
**Explication** :
- `mysql_install_db` : Commande MariaDB qui crée les tables système de base
- `--user=mysql` : Exécute en tant qu'utilisateur mysql
- `--datadir` : Où créer les fichiers de base de données
- **Crée** : Tables `mysql`, `performance_schema`, etc.

```bash
    echo "Démarrage temporaire de MariaDB..."
    mysqld --user=mysql --bootstrap --skip-networking << EOF
```
**Explication** :
- `mysqld` : Lance le serveur MariaDB
- `--bootstrap` : Mode spécial pour initialisation
- `--skip-networking` : N'écoute pas sur le réseau (sécurité pendant l'init)
- `<< EOF` : Heredoc - envoie tout le texte qui suit jusqu'à `EOF` en entrée standard

```bash
FLUSH PRIVILEGES;
```
**Explication** :
- Commande SQL qui recharge les tables de permissions
- **Obligatoire** après avoir modifié les tables `mysql.user`, `mysql.db`, etc.

```bash
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
```
**Explication** :
- `CREATE DATABASE` : Crée une base de données
- `IF NOT EXISTS` : Ne fait rien si elle existe déjà (évite les erreurs)
- `\`${MYSQL_DATABASE}\`` :
  - `${MYSQL_DATABASE}` : Variable d'environnement (ex: "mariaDatabase")
  - Les backticks `\`` protègent les noms avec des caractères spéciaux

```bash
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
```
**Explication** :
- `CREATE USER` : Crée un utilisateur MySQL
- `'${MYSQL_DB_USER}'@'localhost'` :
  - Format : `'utilisateur'@'hôte'`
  - `localhost` : Connexions locales uniquement
- `'${MYSQL_DB_USER}'@'%'` :
  - `%` : Wildcard, accepte **toutes** les adresses IP
  - **Nécessaire** pour que WordPress (autre conteneur) puisse se connecter
- `IDENTIFIED BY` : Définit le mot de passe

**Pourquoi créer deux utilisateurs ?**
```
'toto'@'localhost'  → Connexions depuis le conteneur MariaDB lui-même
'toto'@'%'          → Connexions depuis d'autres conteneurs (WordPress)
```

```bash
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_DB_USER}'@'%';
```
**Explication** :
- `GRANT` : Donne des permissions
- `ALL PRIVILEGES` : Tous les droits (SELECT, INSERT, UPDATE, DELETE, etc.)
- `ON \`${MYSQL_DATABASE}\`.*` :
  - `database.*` : Sur toutes les tables de cette base
- `TO '${MYSQL_DB_USER}'@'...'` : À cet utilisateur

```bash
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
```
**Explication** :
- **Sécurité** : Supprime les utilisateurs anonymes et la base de test
- Ces éléments sont créés par défaut mais dangereux en production

```bash
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
```
**Explication** :
- `ALTER USER` : Modifie un utilisateur existant
- Définit le mot de passe root

```bash
FLUSH PRIVILEGES;
EOF
```
**Explication** :
- Recharge les permissions
- `EOF` : Fin du heredoc

```bash
    touch /var/lib/mysql/.db_configured
```
**Explication** :
- Crée un fichier vide comme "marqueur"
- Lors du prochain démarrage, le bloc `if` sera ignoré
- **Idempotence** garantie

```bash
fi
```
**Explication** : Fermeture du `if`

```bash
echo "Démarrage final de MariaDB..."
exec mysqld --user=mysql
```
**Explication** :
- `exec` : Remplace le processus shell par `mysqld`
  - **Important** : Le PID 1 du conteneur devient `mysqld`
  - Permet la réception des signaux (SIGTERM, SIGINT)
  - Shutdown propre du conteneur
- `mysqld --user=mysql` : Lance MariaDB en mode normal

---

# 🌐 SERVICE WORDPRESS

## Qu'est-ce que WordPress ?

WordPress est un **système de gestion de contenu (CMS)** écrit en PHP. Il permet de créer et gérer un site web sans écrire de code.

### Architecture WordPress

```
┌────────────────────────────────────────────────────────┐
│                    WORDPRESS                            │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PHP Code (WordPress Core)                       │  │
│  │  - index.php (point d'entrée)                    │  │
│  │  - wp-admin/ (interface d'administration)        │  │
│  │  - wp-includes/ (bibliothèques)                  │  │
│  │  - wp-content/ (thèmes, plugins, uploads)        │  │
│  └──────────────────────────────────────────────────┘  │
│                         ↓                               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PHP-FPM (FastCGI Process Manager)               │  │
│  │  - Exécute le code PHP                           │  │
│  │  - Écoute sur le port 9000                       │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

## PHP-FPM : Qu'est-ce que c'est ?

**PHP-FPM** = PHP FastCGI Process Manager

### Sans PHP-FPM (ancien modèle Apache + mod_php)

```
┌───────────────────────────────────────────────────┐
│              Serveur Web Apache                    │
│  ┌─────────────────────────────────────────────┐  │
│  │  Module PHP intégré                         │  │
│  │  - PHP chargé en mémoire                    │  │
│  │  - Un processus par requête                 │  │
│  │  - Lourd et lent                            │  │
│  └─────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────┘
```

### Avec PHP-FPM (modèle moderne)

```
┌──────────────────┐          ┌──────────────────┐
│  Serveur Web     │  FastCGI │   PHP-FPM        │
│  (Nginx)         │ ────────→│   (pool de       │
│  - Fichiers      │   9000   │    processus)    │
│    statiques     │          │   - Rapide       │
│  - Reverse proxy │          │   - Efficace     │
└──────────────────┘          └──────────────────┘
```

**Avantages** :
- **Séparation** : Nginx et PHP sont indépendants
- **Performance** : Pool de processus réutilisables
- **Isolation** : Facilite la mise en conteneur
- **Scalabilité** : Peut tourner sur des machines différentes

## Le Dockerfile WordPress

```dockerfile
FROM debian:bookworm
```
**Explication** : Base Debian, comme pour les autres services

```dockerfile
RUN apt update && apt install -y \
    php php-fpm php-mysql php-cli \
    curl mariadb-client \
    && rm -rf /var/lib/apt/lists/*
```
**Explication** :
- `php` : Interpréteur PHP
- `php-fpm` : FastCGI Process Manager
- `php-mysql` : Extension PHP pour communiquer avec MySQL/MariaDB
- `php-cli` : PHP en ligne de commande (nécessaire pour WP-CLI)
- `curl` : Outil pour télécharger des fichiers via HTTP
- `mariadb-client` : Client MySQL (commande `mariadb` pour tester la connexion)

**Paquets PHP supplémentaires recommandés (absents mais optionnels)** :
```dockerfile
php-curl php-gd php-xml php-mbstring php-zip php-intl
```
- `php-curl` : Requêtes HTTP depuis PHP
- `php-gd` : Manipulation d'images (resize, crop)
- `php-xml` : Parsing XML
- `php-mbstring` : Gestion des chaînes multi-octets (UTF-8)
- `php-zip` : Compression/décompression
- `php-intl` : Internationalisation

```dockerfile
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html
```
**Explication** :
- `/var/www/html` : Répertoire standard pour les sites web
- `www-data` : Utilisateur par défaut pour les serveurs web sous Debian
- **Permissions** : Permet à PHP-FPM (qui tourne en tant que www-data) d'écrire des fichiers

```dockerfile
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
```
**Explication** :
- `/etc/php/8.2/fpm/pool.d/` : Répertoire des "pools" PHP-FPM
- Un **pool** est un groupe de processus PHP avec sa propre configuration
- `8.2` : Version de PHP dans Debian Bookworm

```dockerfile
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp
```
**Explication** :
- **WP-CLI** : Outil en ligne de commande pour gérer WordPress
- `curl -O` : Télécharge le fichier (flag `-O` garde le nom original)
- `chmod +x` : Rend exécutable
- `mv` : Déplace vers `/usr/local/bin/` et renomme en `wp`
- **Résultat** : La commande `wp` est disponible globalement

```dockerfile
COPY tools/wp-cli.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wp-cli.sh
```
**Explication** : Copie et rend exécutable le script d'installation WordPress

```dockerfile
CMD ["wp-cli.sh"]
```
**Explication** : Au démarrage, exécute le script `wp-cli.sh`

## Configuration PHP-FPM : www.conf

```ini
[www]
```
**Explication** : Nom du pool (vous pourriez avoir plusieurs pools)

```ini
user = www-data
group = www-data
```
**Explication** : PHP-FPM s'exécute avec cet utilisateur/groupe

```ini
listen = 9000
```
**Explication** :
- PHP-FPM écoute sur le **port TCP 9000**
- Alternative : `listen = /run/php/php-fpm.sock` (socket Unix, plus rapide mais nécessite un volume partagé)

**Port TCP vs Socket Unix** :
```
Socket Unix (fichier)         Port TCP (réseau)
+ Plus rapide                 + Fonctionne entre conteneurs
+ Moins d'overhead            + Plus simple dans Docker
- Nécessite filesystem        - Légèrement plus lent
  partagé
```

```ini
listen.owner = www-data
listen.group = www-data
```
**Explication** : Permissions de la socket (utile surtout pour les sockets Unix)

```ini
pm = dynamic
```
**Explication** : Mode de gestion des processus
- `dynamic` : Nombre de processus variable selon la charge
- Autres modes :
  - `static` : Nombre fixe
  - `ondemand` : Crée des processus seulement quand nécessaire

```ini
pm.max_children = 5
```
**Explication** : Maximum 5 processus PHP simultanés

```ini
pm.start_servers = 2
```
**Explication** : Au démarrage, lance 2 processus

```ini
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```
**Explication** :
- `min_spare` : Garde au moins 1 processus en attente (idle)
- `max_spare` : Garde au maximum 3 processus en attente

**Schéma du pool dynamique** :
```
Charge faible:           Charge moyenne:        Charge haute:
┌───────────┐            ┌───────────┐          ┌───────────┐
│ Process 1 │ (idle)     │ Process 1 │ (busy)   │ Process 1 │ (busy)
├───────────┤            ├───────────┤          ├───────────┤
│ Process 2 │ (idle)     │ Process 2 │ (busy)   │ Process 2 │ (busy)
└───────────┘            ├───────────┤          ├───────────┤
                         │ Process 3 │ (idle)   │ Process 3 │ (busy)
                         └───────────┘          ├───────────┤
                                                 │ Process 4 │ (busy)
                                                 ├───────────┤
                                                 │ Process 5 │ (idle)
                                                 └───────────┘
```

```ini
clear_env = no
```
**Explication** :
- Par défaut, PHP-FPM **efface** toutes les variables d'environnement
- `no` : **Garde** les variables d'environnement
- **CRUCIAL** : Sans ça, vos variables MySQL ne seront pas visibles dans PHP

## Le script wp-cli.sh

Ce script est le **cœur** de l'installation WordPress. Analysons-le.

```bash
#!/bin/bash
set -e
```
**Explication** : Classique, arrêt en cas d'erreur

```bash
echo "Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u"${MYSQL_DB_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" &>/dev/null; do
    echo "MariaDB is unavailable - sleeping"
    sleep 2
done
echo "MariaDB is up - continuing"
```
**Explication détaillée** :

- `until ... do ... done` : Boucle qui s'exécute **jusqu'à ce que** la condition soit vraie
- `mariadb` : Client MySQL/MariaDB (équivalent à `mysql`)
- `-h mariadb` : Hôte = "mariadb" (nom DNS du service dans Docker)
- `-u"${MYSQL_DB_USER}"` : Utilisateur (ex: "toto")
- `-p"${MYSQL_PASSWORD}"` : Mot de passe (ex: "toto")
- `-e "SELECT 1"` : Exécute cette requête SQL
  - `SELECT 1` : Requête la plus simple, retourne toujours 1
  - Sert juste à tester si la connexion fonctionne
- `&>/dev/null` : Redirige stdout ET stderr vers /dev/null (poubelle)
  - `&>` : Redirige les deux flux
  - Sans ça, le terminal afficherait des erreurs à chaque tentative

**Pourquoi cette boucle est nécessaire** :

```
docker-compose up
   ↓
MariaDB démarre (conteneur up)
   ↓ (2-3 secondes)
MariaDB initialise la base
   ↓ (5-10 secondes)
MariaDB accepte les connexions ✓
   ↓
WordPress peut continuer
```

Le `depends_on` dans docker-compose attend juste que le **conteneur** démarre, pas que le **service** soit prêt.

```bash
cd /var/www/html
```
**Explication** : Se déplace dans le répertoire WordPress

```bash
if [ ! -f wp-config.php ]; then
```
**Explication** :
- Vérifie si WordPress est déjà installé
- `wp-config.php` : Fichier de configuration principal de WordPress
- **Idempotence** : Si WordPress existe déjà, on passe directement au lancement de PHP-FPM

```bash
    echo "Downloading WordPress..."
    wp core download --allow-root
```
**Explication** :
- `wp` : Commande WP-CLI
- `core download` : Télécharge les fichiers WordPress
- `--allow-root` : Autorise l'exécution en tant que root
  - Par défaut, WP-CLI refuse de s'exécuter en root (sécurité)
  - Dans Docker, on est souvent root, donc on force

**Ce qui est téléchargé** :
```
/var/www/html/
├── index.php
├── wp-admin/           (interface d'administration)
├── wp-includes/        (bibliothèques WordPress)
├── wp-content/         (thèmes, plugins, uploads)
├── wp-config-sample.php
└── ... (autres fichiers)
```

```bash
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_DB_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root
```
**Explication** :
- `wp config create` : Génère le fichier `wp-config.php`
- `--dbname` : Nom de la base (ex: "mariaDatabase")
- `--dbuser` : Utilisateur MySQL (ex: "toto")
- `--dbpass` : Mot de passe
- `--dbhost="mariadb:3306"` :
  - `mariadb` : Nom DNS du service (résolu par Docker)
  - `3306` : Port MySQL/MariaDB

**Contenu généré (simplifié)** :
```php
<?php
define('DB_NAME', 'mariaDatabase');
define('DB_USER', 'toto');
define('DB_PASSWORD', 'toto');
define('DB_HOST', 'mariadb:3306');
// ... clés de salage, etc.
```

```bash
    echo "Installing WordPress..."
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
```
**Explication** :
- `wp core install` : Installe WordPress dans la base de données
- `--url` : URL du site (ex: "https://mmilliot.42.fr")
  - **Stocké en base** : WordPress génère les URLs avec cette valeur
- `--title` : Titre du site (ex: "Inception WordPress")
- `--admin_user` : Nom d'utilisateur admin (ex: "admin")
- `--admin_password` : Mot de passe admin
- `--admin_email` : Email admin
- `--skip-email` : Ne pas envoyer d'email de notification
  - Pas de serveur mail configuré dans Docker

**Ce qui se passe en base de données** :
```sql
-- Crée les tables WordPress
CREATE TABLE wp_posts (...);
CREATE TABLE wp_users (...);
CREATE TABLE wp_options (...);
-- ... 12 tables au total

-- Insère l'admin
INSERT INTO wp_users (user_login, user_pass, user_email)
VALUES ('admin', HASH('admin_password_123'), 'admin@mmilliot.42.fr');

-- Configure les options du site
INSERT INTO wp_options (option_name, option_value)
VALUES ('siteurl', 'https://mmilliot.42.fr'),
       ('home', 'https://mmilliot.42.fr'),
       ('blogname', 'Inception WordPress');
```

```bash
    echo "Creating additional user..."
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root
```
**Explication** :
- `wp user create` : Crée un utilisateur supplémentaire
- `--role=author` : Rôle WordPress
  - **Hiérarchie des rôles** :
    1. **Subscriber** : Peut seulement lire
    2. **Contributor** : Peut écrire des articles (validation requise)
    3. **Author** : Peut publier ses propres articles
    4. **Editor** : Peut publier et modifier tous les articles
    5. **Administrator** : Tous les droits

```bash
    echo "WordPress installation completed!"
fi
```
**Explication** : Fin du bloc d'installation

```bash
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
```
**Explication** :
- `exec` : Remplace le processus shell par PHP-FPM
- `php-fpm8.2` : Version 8.2 de PHP-FPM (correspondant à Debian Bookworm)
- `-F` : **Foreground mode**
  - Par défaut, PHP-FPM se met en arrière-plan (daemon)
  - Dans Docker, le processus principal **doit** rester en foreground
  - Sinon le conteneur s'arrêterait immédiatement

---

# 🌐 SERVICE NGINX

## Qu'est-ce que Nginx ?

**Nginx** (prononcé "engine-x") est un **serveur web** et **reverse proxy** très performant.

### Serveur web vs Reverse proxy

```
SERVEUR WEB:
Client → Nginx → Fichiers statiques (HTML, CSS, JS, images)

REVERSE PROXY:
Client → Nginx → Backend (PHP-FPM, Node.js, etc.)
```

Dans votre projet, Nginx fait les **deux** :
- Sert les fichiers statiques de WordPress (CSS, JS, images)
- Fait du reverse proxy vers PHP-FPM pour les fichiers `.php`

## Le Dockerfile Nginx

```dockerfile
FROM debian:bookworm
```

```dockerfile
RUN apt update && apt install -y nginx openssl \
    && rm -rf /var/lib/apt/lists/*
```
**Explication** :
- `nginx` : Serveur web
- `openssl` : Bibliothèque pour SSL/TLS (génération de certificats)

```dockerfile
COPY conf/nginx.conf /etc/nginx/sites-available/default
```
**Explication** :
- `/etc/nginx/sites-available/` : Répertoire des configurations de sites
- `default` : Nom du site par défaut

**Structure Nginx** :
```
/etc/nginx/
├── nginx.conf                  (config globale)
├── sites-available/
│   └── default                 (votre config)
└── sites-enabled/
    └── default → ../sites-available/default  (lien symbolique)
```

```dockerfile
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
```

```dockerfile
EXPOSE 443
```
**Explication** : Port HTTPS

```dockerfile
CMD ["entrypoint.sh"]
```

## Le script entrypoint.sh

```bash
#!/bin/bash
set -e
```

```bash
if [ ! -f /etc/nginx/ssl/mmilliot.crt ]; then
```
**Explication** : Vérifie si le certificat SSL existe déjà

```bash
    echo "Génération des certificats SSL..."
    mkdir -p /etc/nginx/ssl
```
**Explication** : Crée le répertoire pour les certificats

```bash
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/mmilliot.key \
        -out /etc/nginx/ssl/mmilliot.crt \
        -subj "/C=FR/ST=Alsace/L=Mulhouse/O=42/CN=mmilliot.42.fr"
```
**Explication détaillée** :

- `openssl req` : Commande pour générer une demande de certificat
- `-x509` : Génère un certificat auto-signé (pas une demande CSR)
- `-nodes` : "No DES", ne chiffre pas la clé privée avec un mot de passe
  - Nécessaire pour que Nginx puisse charger la clé automatiquement
- `-days 365` : Valide 365 jours (1 an)
- `-newkey rsa:2048` : Génère une nouvelle clé RSA de 2048 bits
  - RSA : Algorithme de chiffrement asymétrique
  - 2048 bits : Taille de clé (sécurisé pour usage non-critique)
- `-keyout` : Fichier de sortie pour la clé privée
- `-out` : Fichier de sortie pour le certificat
- `-subj` : Sujet du certificat (informations du propriétaire)
  - `/C=FR` : Country (Pays)
  - `/ST=Alsace` : State (État/Région)
  - `/L=Mulhouse` : Locality (Ville)
  - `/O=42` : Organization (Organisation)
  - `/CN=mmilliot.42.fr` : Common Name (Nom de domaine) **IMPORTANT**

**Fichiers générés** :
```
/etc/nginx/ssl/
├── mmilliot.key    (Clé privée - à garder secrète)
└── mmilliot.crt    (Certificat public)
```

**Différence certificat officiel vs auto-signé** :

```
Certificat officiel (Let's Encrypt, DigiCert, etc.):
Site → Certificat → Autorité de Certification (CA)
                    ↓
                Navigateur fait confiance ✓

Certificat auto-signé (votre cas):
Site → Certificat (signé par vous-même)
       ↓
   Navigateur ne fait PAS confiance ⚠️
   (mais fonctionne quand même)
```

```bash
    echo "Certificats générés"
fi
```

```bash
echo "Vérification de la configuration..."
nginx -t
```
**Explication** :
- `nginx -t` : Teste la configuration sans démarrer le serveur
- `-t` : Test mode
- **Affiche** :
  - `nginx: configuration file /etc/nginx/nginx.conf test is successful` ✓
  - Ou des erreurs si la config est invalide ✗

```bash
echo "Démarrage de Nginx..."
exec nginx -g 'daemon off;'
```
**Explication** :
- `exec` : Remplace le shell par nginx
- `-g 'daemon off;'` : Option globale
  - Par défaut, nginx se met en daemon (arrière-plan)
  - `daemon off` : Reste en foreground (obligatoire pour Docker)

## Configuration Nginx : nginx.conf

Analysons la configuration ligne par ligne.

```nginx
server {
```
**Explication** : Bloc de configuration d'un serveur virtuel

```nginx
    listen 443 ssl;
    listen [::]:443 ssl;
```
**Explication** :
- `listen 443 ssl` : Écoute sur le port 443 en mode SSL (IPv4)
- `listen [::]:443 ssl` : Pareil pour IPv6
- `ssl` : Active SSL/TLS pour ce port

```nginx
    server_name mmilliot.42.fr;
```
**Explication** :
- Nom du serveur (domaine)
- Nginx compare cette valeur avec l'en-tête `Host:` de la requête HTTP

**Schéma de la requête** :
```
Client → https://mmilliot.42.fr
         ↓
         Requête HTTP:
         GET / HTTP/1.1
         Host: mmilliot.42.fr    ← Nginx vérifie cette ligne
         ...
```

```nginx
    ssl_certificate /etc/nginx/ssl/mmilliot.crt;
    ssl_certificate_key /etc/nginx/ssl/mmilliot.key;
```
**Explication** : Chemins vers le certificat et la clé privée

```nginx
    ssl_protocols TLSv1.2 TLSv1.3;
```
**Explication** :
- Active seulement TLS 1.2 et 1.3
- **Désactive** les anciennes versions (SSLv3, TLS 1.0, TLS 1.1)
  - Anciennes versions ont des vulnérabilités connues (POODLE, BEAST, etc.)

**Historique SSL/TLS** :
```
SSLv2 (1995) ✗ Cassé
SSLv3 (1996) ✗ Vulnérable (POODLE)
TLS 1.0 (1999) ⚠️ Déprécié
TLS 1.1 (2006) ⚠️ Déprécié
TLS 1.2 (2008) ✓ Sécurisé
TLS 1.3 (2018) ✓ Recommandé
```

```nginx
    root /var/www/html;
```
**Explication** :
- **Document root** : Répertoire de base des fichiers du site
- Tous les chemins d'URL sont relatifs à ce répertoire

**Exemples** :
```
URL: https://mmilliot.42.fr/image.jpg
→ Fichier: /var/www/html/image.jpg

URL: https://mmilliot.42.fr/wp-content/themes/twentytwentyfour/style.css
→ Fichier: /var/www/html/wp-content/themes/twentytwentyfour/style.css
```

```nginx
    index index.php index.html index.htm;
```
**Explication** :
- Liste des fichiers d'index (par ordre de priorité)
- Si l'URL est un répertoire, Nginx cherche ces fichiers

**Exemples** :
```
URL: https://mmilliot.42.fr/
→ Cherche: /var/www/html/index.php (trouve ✓)
→ Sert: index.php

URL: https://mmilliot.42.fr/wp-admin/
→ Cherche: /var/www/html/wp-admin/index.php (trouve ✓)
→ Sert: index.php
```

```nginx
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
```
**Explication** :
- `location /` : Bloc pour toutes les URLs
- `try_files` : Essaie plusieurs options dans l'ordre

**Décortiquons `try_files $uri $uri/ /index.php?$args`** :

1. `$uri` : Essaie le fichier exact
   - Exemple : `/style.css` → Cherche `/var/www/html/style.css`
   - Si existe : Sert le fichier ✓

2. `$uri/` : Essaie comme répertoire + index
   - Exemple : `/wp-admin` → Cherche `/var/www/html/wp-admin/index.php`
   - Si existe : Sert le fichier ✓

3. `/index.php?$args` : Fallback final
   - Passe tout à WordPress
   - `$args` : Conserve les paramètres GET

**Pourquoi c'est nécessaire** :

WordPress utilise des "permaliens" (jolies URLs) :
```
URL affichée: https://mmilliot.42.fr/hello-world/
Fichier réel:  Il n'existe pas de fichier /hello-world/

→ Nginx redirige vers /index.php?args
→ WordPress parse l'URL et affiche l'article "hello-world"
```

```nginx
    location ~ \.php$ {
```
**Explication** :
- `location ~` : Expression régulière
- `\.php$` :
  - `\.` : Point littéral (échappé avec `\`)
  - `php` : Lettres "php"
  - `$` : Fin de chaîne
- **Match** : Tous les fichiers se terminant par `.php`

**Exemples** :
```
/index.php              ✓ Match
/wp-admin/admin.php     ✓ Match
/style.css              ✗ No match
/image.jpg.php          ✓ Match (attention: sécurité)
```

```nginx
        include snippets/fastcgi-php.conf;
```
**Explication** :
- Inclut un fichier de configuration standard
- `/etc/nginx/snippets/fastcgi-php.conf` : Fourni par Debian
- Contient des directives FastCGI standard

**Contenu (simplifié)** :
```nginx
fastcgi_split_path_info ^(.+\.php)(/.+)$;
fastcgi_index index.php;
```

```nginx
        fastcgi_pass wordpress:9000;
```
**Explication** :
- **LA LIGNE CRUCIALE !**
- `fastcgi_pass` : Envoie la requête à un serveur FastCGI
- `wordpress:9000` :
  - `wordpress` : Nom DNS du service (résolu par Docker)
  - `9000` : Port PHP-FPM

**Schéma de la communication** :
```
Client → Nginx:443 (HTTPS)
         ↓
         /index.php détecté
         ↓
         Nginx → WordPress:9000 (FastCGI)
                 ↓
                 PHP-FPM exécute le script
                 ↓
                 WordPress génère la page HTML
                 ↓
         Nginx ← WordPress (HTML)
         ↓
Client ← Nginx (HTML)
```

```nginx
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
```
**Explication** :
- Définit une variable FastCGI
- `SCRIPT_FILENAME` : Chemin absolu du script PHP à exécuter
- `$document_root` : `/var/www/html` (de la directive `root`)
- `$fastcgi_script_name` : `/index.php` (depuis l'URL)
- **Résultat** : `/var/www/html/index.php`

**Pourquoi c'est nécessaire** :

PHP-FPM a besoin de savoir **quel fichier exécuter**. Nginx et PHP-FPM sont dans des conteneurs différents, mais partagent le même volume, donc ils voient les mêmes fichiers.

```nginx
        include fastcgi_params;
```
**Explication** : Inclut des paramètres FastCGI standard

**Contenu (partiel)** :
```nginx
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;
# ... ~20 paramètres au total
```

Ces paramètres sont accessibles dans PHP via `$_SERVER` :
```php
<?php
echo $_SERVER['REQUEST_METHOD'];  // GET, POST, etc.
echo $_SERVER['QUERY_STRING'];    // ?foo=bar
```

```nginx
    }
```
**Explication** : Fin du bloc `location ~ \.php$`

```nginx
    location ~ /\.ht {
        deny all;
    }
```
**Explication** :
- `location ~ /\.ht` : Match tout fichier commençant par `.ht`
- Exemples : `.htaccess`, `.htpasswd`
- `deny all` : Refuse toutes les requêtes
- **Sécurité** : Ces fichiers Apache ne devraient pas être accessibles

```nginx
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }
```
**Explication** :
- `location ~*` : Expression régulière insensible à la casse
- `\.(js|css|png|...)$` : Fichiers statiques
- `expires max` : Cache navigateur maximum (10 ans)
  - Envoie l'en-tête : `Cache-Control: max-age=315360000`
- `log_not_found off` : Ne pas logger les 404 pour ces fichiers

**Avantages** :
- Réduit la charge serveur
- Accélère le site pour les visiteurs

```nginx
}
```
**Explication** : Fin du bloc `server`

---

# 🔗 RÉSEAUX DOCKER

## Types de réseaux Docker

Docker propose plusieurs types de réseaux :

### 1. Bridge (votre cas)

```
┌──────────────────────────────────────────────────┐
│         Réseau bridge "inception"                 │
│                                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  Nginx   │  │WordPress │  │ MariaDB  │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│       │             │              │              │
│       └─────────────┴──────────────┘              │
│             Réseau privé isolé                    │
└──────────────────────────────────────────────────┘
           │ (port mapping 443:443)
           ↓
      Hôte (Mac)
```

**Caractéristiques** :
- Réseau privé interne
- Isolation du réseau hôte
- DNS intégré (résolution par nom de service)
- Communication inter-conteneurs possible

### 2. Host (non utilisé ici)

```
Conteneur utilise directement le réseau de l'hôte
(pas d'isolation réseau)
```

### 3. None (non utilisé ici)

```
Aucun réseau (conteneur isolé)
```

## DNS Docker

Docker fournit un **serveur DNS intégré** pour les réseaux bridge.

```
┌─────────────────────────────────────────┐
│     Serveur DNS Docker                   │
│  ┌────────────────────────────────────┐ │
│  │ mariadb    → 172.18.0.2            │ │
│  │ wordpress  → 172.18.0.3            │ │
│  │ nginx      → 172.18.0.4            │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**Quand vous faites** :
```bash
# Depuis le conteneur WordPress
mariadb -h mariadb -u toto -p
```

Docker résout `mariadb` en `172.18.0.2` automatiquement.

**Test** :
```bash
docker-compose exec wordpress ping mariadb
# PING mariadb (172.18.0.2): 56 data bytes
# 64 bytes from 172.18.0.2: icmp_seq=0 ttl=64 time=0.123 ms
```

## Isolation réseau

```
┌──────────────────────────────────────────────────┐
│                  Hôte (Mac)                       │
│  ┌────────────────────────────────────────────┐  │
│  │  Réseau inception (172.18.0.0/16)          │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐             │  │
│  │  │Nginx │  │  WP  │  │ DB   │             │  │
│  │  └──────┘  └──────┘  └──────┘             │  │
│  └────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────┐  │
│  │  Autre réseau (172.19.0.0/16)              │  │
│  │  ┌──────┐  ┌──────┐                        │  │
│  │  │ App1 │  │ App2 │  ← Isolés de Inception│  │
│  │  └──────┘  └──────┘                        │  │
│  └────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────┘
```

Les conteneurs de différents réseaux **ne peuvent PAS** communiquer entre eux (sauf si explicitement connectés).

---

# 💾 VOLUMES DOCKER

## Pourquoi des volumes ?

Les conteneurs sont **éphémères** : quand vous les supprimez, toutes les données disparaissent.

```
SANS VOLUMES:
docker-compose up     → Conteneur créé, données écrites
docker-compose down   → Conteneur supprimé, DONNÉES PERDUES ✗

AVEC VOLUMES:
docker-compose up     → Conteneur créé, données dans volume
docker-compose down   → Conteneur supprimé, données préservées ✓
docker-compose up     → Nouveau conteneur, données restaurées ✓
```

## Types de volumes

### 1. Volumes nommés (votre cas)

```yaml
volumes:
  - mariadb_data:/var/lib/mysql
```

```
┌──────────────────────────────────────────────┐
│  Docker gère le stockage                      │
│  /var/lib/docker/volumes/                     │
│  └── srcs_mariadb_data/                       │
│      └── _data/                               │
│          ├── mysql/                           │
│          ├── mariaDatabase/                   │
│          └── ...                              │
└──────────────────────────────────────────────┘
```

**Avantages** :
- Géré par Docker
- Performance optimale
- Portabilité (fonctionne partout)

**Inconvénients** :
- Fichiers "cachés" (pas facilement accessibles)

### 2. Bind mounts (alternative)

```yaml
volumes:
  - /Users/marcmilliot/data/mariadb:/var/lib/mysql
```

```
┌──────────────────────────────────────────────┐
│  Votre Mac                                    │
│  /Users/marcmilliot/data/mariadb/            │
│  ├── mysql/                                   │
│  ├── mariaDatabase/                           │
│  └── ...                                      │
└──────────────────────────────────────────────┘
         ↕ (montage)
┌──────────────────────────────────────────────┐
│  Conteneur MariaDB                            │
│  /var/lib/mysql/                              │
│  ├── mysql/                                   │
│  ├── mariaDatabase/                           │
│  └── ...                                      │
└──────────────────────────────────────────────┘
```

**Avantages** :
- Fichiers accessibles sur votre Mac
- Facile à backup

**Inconvénients** :
- Moins performant sur Mac/Windows
- Dépendant du chemin absolu

## Volume partagé wordpress_data

```
┌──────────────────────────────────────────────┐
│           Volume wordpress_data               │
│  /var/www/html/                               │
│  ├── index.php                                │
│  ├── wp-config.php                            │
│  ├── wp-content/                              │
│  │   ├── themes/                              │
│  │   ├── plugins/                             │
│  │   └── uploads/                             │
│  └── ...                                      │
└─────────────┬────────────────┬────────────────┘
              │                │
       ┌──────┴──────┐  ┌─────┴──────┐
       │  Conteneur  │  │ Conteneur  │
       │  WordPress  │  │   Nginx    │
       │             │  │            │
       │ - Écrit PHP │  │ - Lit CSS  │
       │ - Upload    │  │ - Lit JS   │
       │   fichiers  │  │ - Lit img  │
       └─────────────┘  └────────────┘
```

**Pourquoi partagé** :
- WordPress crée/modifie les fichiers PHP, uploads, etc.
- Nginx doit lire ces fichiers pour les servir au client

---

# 🔐 VARIABLES D'ENVIRONNEMENT

## Le fichier .env

```bash
# MariaDB
MYSQL_DATABASE=mariaDatabase
MYSQL_DB_USER=toto
MYSQL_PASSWORD=toto
MYSQL_ROOT_PASSWORD=toto

# WordPress
WP_URL=https://mmilliot.42.fr
WP_TITLE=Inception WordPress
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin_password_123
WP_ADMIN_EMAIL=admin@mmilliot.42.fr
WP_USER=user1
WP_USER_EMAIL=user1@mmilliot.42.fr
WP_USER_PASSWORD=user_password_123
```

## Comment elles sont chargées

```
1. docker-compose.yml:
   env_file:
     - .env

2. Docker Compose lit le fichier .env

3. Variables injectées dans le conteneur

4. Accessibles dans les scripts:
   echo $MYSQL_DATABASE  # Bash

5. Accessibles dans PHP:
   echo getenv('MYSQL_DATABASE');  // PHP
```

## Sécurité des variables

**Mauvaises pratiques (votre projet actuel)** :
```bash
MYSQL_PASSWORD=toto    # Mot de passe faible
```

**Bonnes pratiques (production)** :

```bash
# Utiliser Docker secrets
docker secret create mysql_password ./secret.txt

# Ou variables d'environnement sécurisées
export MYSQL_PASSWORD=$(openssl rand -base64 32)
```

**Fichier .env ne devrait JAMAIS être commité sur Git** :
```bash
# .gitignore
.env
```

---

# 🔒 SSL/TLS ET CERTIFICATS

## Qu'est-ce que SSL/TLS ?

**SSL** (Secure Sockets Layer) et **TLS** (Transport Layer Security) sont des protocoles de chiffrement pour sécuriser les communications web.

### Communication HTTP (sans chiffrement)

```
Client                          Serveur
  │                               │
  │──── GET /index.php ───────→  │  (texte clair)
  │                               │
  │←─── <html>...</html> ────────│  (texte clair)
  │                               │

⚠️ Un attaquant peut lire/modifier les données
```

### Communication HTTPS (avec chiffrement)

```
Client                          Serveur
  │                               │
  │──── Handshake TLS ─────────→ │
  │←─── Certificat ──────────────│
  │──── Clé de session ─────────→│
  │                               │
  │══ GET /index.php (chiffré) ═→│
  │                               │
  │←═ <html>... (chiffré) ═══════│
  │                               │

✓ Les données sont illisibles pour un attaquant
```

## Certificats SSL

Un certificat SSL contient :
- **Nom de domaine** (CN: Common Name)
- **Clé publique**
- **Signature numérique** (de l'autorité de certification)
- **Période de validité**

### Certificat auto-signé (votre projet)

```
┌─────────────────────────────────────────────┐
│         Certificat mmilliot.42.fr           │
├─────────────────────────────────────────────┤
│ Émis pour: mmilliot.42.fr                   │
│ Émis par:  mmilliot.42.fr  ← VOUS-MÊME     │
│ Valide du: 2026-01-13                       │
│ Valide jusqu'au: 2027-01-13                 │
│ Clé publique: [2048 bits RSA]              │
│ Signature: [auto-signée]                    │
└─────────────────────────────────────────────┘

Navigateur: "Je ne connais pas cette autorité" ⚠️
```

### Certificat officiel (Let's Encrypt, etc.)

```
┌─────────────────────────────────────────────┐
│         Certificat example.com              │
├─────────────────────────────────────────────┤
│ Émis pour: example.com                      │
│ Émis par:  Let's Encrypt Authority X3       │
│ Valide du: 2026-01-13                       │
│ Valide jusqu'au: 2026-04-13                 │
│ Clé publique: [2048 bits RSA]              │
│ Signature: [signée par Let's Encrypt]      │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│    Certificat Let's Encrypt Authority X3    │
├─────────────────────────────────────────────┤
│ Émis par: DST Root CA X3                    │
│ [Signature de l'autorité racine]            │
└─────────────────────────────────────────────┘
         ↓
  ┌──────────────────────┐
  │   DST Root CA X3     │ ← Autorité racine
  │ (dans le navigateur) │    (de confiance)
  └──────────────────────┘

Navigateur: "Je fais confiance à cette chaîne" ✓
```

## Chiffrement asymétrique (RSA)

```
Clé publique (certificat)   +   Clé privée (secrète)
        │                              │
        │                              │
   Chiffrement                    Déchiffrement
        │                              │
        └──────────┬───────────────────┘
                   │
            Données sécurisées
```

**Exemple simplifié** :
```
1. Client récupère la clé publique du serveur (certificat)
2. Client génère une clé de session aléatoire
3. Client chiffre la clé de session avec la clé publique
4. Client envoie la clé de session chiffrée
5. Serveur déchiffre avec sa clé privée
6. Les deux parties utilisent la clé de session pour chiffrer la communication
```

---

# 📡 COMMUNICATION ENTRE CONTENEURS

## Schéma complet de communication

```
┌────────────────────────────────────────────────────────────┐
│                    RÉSEAU INCEPTION                         │
│                                                              │
│  ┌─────────────────┐                                        │
│  │     NGINX       │                                        │
│  │  (172.18.0.4)   │                                        │
│  └────────┬────────┘                                        │
│           │                                                  │
│           │ 1. Client demande /index.php                    │
│           │                                                  │
│           │ 2. Nginx détecte .php                           │
│           │                                                  │
│           │ FastCGI (port 9000)                             │
│           ↓                                                  │
│  ┌─────────────────┐                                        │
│  │   WORDPRESS     │                                        │
│  │  (172.18.0.3)   │                                        │
│  │                 │                                        │
│  │  PHP-FPM écoute │                                        │
│  │  sur port 9000  │                                        │
│  └────────┬────────┘                                        │
│           │                                                  │
│           │ 3. WordPress a besoin de données                │
│           │                                                  │
│           │ MySQL Protocol (port 3306)                      │
│           ↓                                                  │
│  ┌─────────────────┐                                        │
│  │    MARIADB      │                                        │
│  │  (172.18.0.2)   │                                        │
│  │                 │                                        │
│  │  mysqld écoute  │                                        │
│  │  sur port 3306  │                                        │
│  └─────────────────┘                                        │
│           │                                                  │
│           │ 4. MariaDB retourne les données                 │
│           ↓                                                  │
│  ┌─────────────────┐                                        │
│  │   WORDPRESS     │                                        │
│  │                 │                                        │
│  │  Génère HTML    │                                        │
│  └────────┬────────┘                                        │
│           │                                                  │
│           │ 5. Retourne HTML à Nginx                        │
│           ↓                                                  │
│  ┌─────────────────┐                                        │
│  │     NGINX       │                                        │
│  │                 │                                        │
│  │  Envoie au      │                                        │
│  │  client         │                                        │
│  └────────┬────────┘                                        │
│           │                                                  │
└───────────┼──────────────────────────────────────────────────┘
            │ HTTPS (port 443)
            ↓
      ┌───────────┐
      │  CLIENT   │
      │ (Browser) │
      └───────────┘
```

## Exemple de requête complète

### 1. Requête initiale

```http
GET https://mmilliot.42.fr/ HTTP/1.1
Host: mmilliot.42.fr
User-Agent: Mozilla/5.0
Accept: text/html
```

### 2. Nginx reçoit et traite

```nginx
# Nginx vérifie la configuration
location / {
    try_files $uri $uri/ /index.php?$args;
}

# $uri = "/"
# Fichier / n'existe pas
# Répertoire / existe mais pas d'index
# → Redirige vers /index.php
```

### 3. Nginx détecte .php

```nginx
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
    # ...
}

# Envoie la requête à wordpress:9000
```

### 4. PHP-FPM exécute le code

```php
// /var/www/html/index.php (WordPress)
<?php
define('WP_USE_THEMES', true);
require __DIR__ . '/wp-blog-header.php';

// WordPress se connecte à la base de données
$db = new mysqli('mariadb', 'toto', 'toto', 'mariaDatabase');

// Récupère les articles
$posts = $db->query("SELECT * FROM wp_posts WHERE post_status='publish'");

// Génère le HTML
?>
<!DOCTYPE html>
<html>
<head><title>Inception WordPress</title></head>
<body>
    <h1>Bienvenue</h1>
    <?php foreach ($posts as $post): ?>
        <article>
            <h2><?= $post['post_title'] ?></h2>
            <div><?= $post['post_content'] ?></div>
        </article>
    <?php endforeach; ?>
</body>
</html>
```

### 5. Connexion à MariaDB

```
WordPress (172.18.0.3) → MariaDB (172.18.0.2:3306)

Requête SQL:
SELECT * FROM wp_posts WHERE post_status='publish'

Réponse:
[
  {id: 1, title: "Hello World", content: "Welcome to WordPress..."},
  ...
]
```

### 6. Retour à Nginx

```
PHP-FPM → Nginx (via FastCGI)

Content-Type: text/html; charset=UTF-8
Content-Length: 2048

<!DOCTYPE html>
<html>
...
</html>
```

### 7. Nginx envoie au client

```http
HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html; charset=UTF-8
Content-Length: 2048

<!DOCTYPE html>
<html>
...
</html>
```

---

# 🚀 FLUX DE DÉMARRAGE COMPLET

## Commande : docker-compose up

Voici ce qui se passe exactement quand vous lancez `docker-compose up` :

### Phase 1 : Parsing et Validation

```
1. Docker Compose lit docker-compose.yml
2. Valide la syntaxe YAML
3. Charge les variables de .env
4. Résout les dépendances (depends_on)
5. Crée un plan d'exécution
```

### Phase 2 : Création du réseau

```
$ docker network create srcs_inception

Résultat:
┌─────────────────────────────────────┐
│  Réseau: srcs_inception              │
│  Type: bridge                        │
│  Subnet: 172.18.0.0/16              │
│  Gateway: 172.18.0.1                │
└─────────────────────────────────────┘
```

### Phase 3 : Création des volumes

```
$ docker volume create srcs_mariadb_data
$ docker volume create srcs_wordpress_data

Résultat:
┌─────────────────────────────────────┐
│  Volume: srcs_mariadb_data           │
│  Mountpoint: /var/lib/docker/...    │
└─────────────────────────────────────┘
┌─────────────────────────────────────┐
│  Volume: srcs_wordpress_data         │
│  Mountpoint: /var/lib/docker/...    │
└─────────────────────────────────────┘
```

### Phase 4 : Build des images (si nécessaire)

```
$ docker build -t srcs_mariadb ./requirements/mariadb

Étapes:
[1/5] FROM debian:bookworm
[2/5] RUN apt update && apt install -y mariadb-server
[3/5] COPY conf/99-custom.cnf /etc/mysql/...
[4/5] COPY tools/init.sh /usr/local/bin/
[5/5] RUN chmod +x /usr/local/bin/init.sh

Image créée: srcs_mariadb (SHA: abc123...)
```

Pareil pour `srcs_wordpress` et `srcs_nginx`.

### Phase 5 : Démarrage des conteneurs (ordre de dépendance)

#### 5.1 Démarrage de MariaDB

```
$ docker run -d \
  --name mariadb \
  --network srcs_inception \
  -v srcs_mariadb_data:/var/lib/mysql \
  -e MYSQL_DATABASE=mariaDatabase \
  -e MYSQL_DB_USER=toto \
  -e MYSQL_PASSWORD=toto \
  -e MYSQL_ROOT_PASSWORD=toto \
  srcs_mariadb

Conteneur ID: a1b2c3d4e5f6
```

**Logs MariaDB** :
```
Première initialisation de MariaDB...
mysql_install_db: Creating tables...
Démarrage temporaire de MariaDB...
Configuration de la base de données...
CREATE DATABASE mariaDatabase
CREATE USER 'toto'@'localhost'
CREATE USER 'toto'@'%'
GRANT ALL PRIVILEGES...
Arrêt du serveur temporaire...
Démarrage final de MariaDB...
mysqld: ready for connections. Port: 3306
```

#### 5.2 Démarrage de WordPress (attend MariaDB)

```
$ docker run -d \
  --name wordpress \
  --network srcs_inception \
  -v srcs_wordpress_data:/var/www/html \
  -e MYSQL_DATABASE=mariaDatabase \
  -e MYSQL_DB_USER=toto \
  -e MYSQL_PASSWORD=toto \
  -e WP_URL=https://mmilliot.42.fr \
  -e WP_TITLE=Inception WordPress \
  -e WP_ADMIN_USER=admin \
  -e WP_ADMIN_PASSWORD=admin_password_123 \
  -e WP_ADMIN_EMAIL=admin@mmilliot.42.fr \
  -e WP_USER=user1 \
  -e WP_USER_EMAIL=user1@mmilliot.42.fr \
  -e WP_USER_PASSWORD=user_password_123 \
  srcs_wordpress

Conteneur ID: b2c3d4e5f6g7
```

**Logs WordPress** :
```
Waiting for MariaDB to be ready...
MariaDB is unavailable - sleeping
MariaDB is unavailable - sleeping
MariaDB is up - continuing
Downloading WordPress...
Downloading WordPress 6.9 (en_US)...
Success: WordPress downloaded.
Creating wp-config.php...
Success: Generated 'wp-config.php' file.
Installing WordPress...
Success: WordPress installed successfully.
Creating additional user...
Success: Created user 2.
WordPress installation completed!
Starting PHP-FPM...
[13-Jan-2026 10:00:00] NOTICE: fpm is running, pid 1
[13-Jan-2026 10:00:00] NOTICE: ready to handle connections
```

#### 5.3 Démarrage de Nginx (attend MariaDB et WordPress)

```
$ docker run -d \
  --name nginx \
  --network srcs_inception \
  -p 443:443 \
  -v srcs_wordpress_data:/var/www/html \
  srcs_nginx

Conteneur ID: c3d4e5f6g7h8
```

**Logs Nginx** :
```
Génération des certificats SSL...
Generating RSA private key, 2048 bit...
Writing new private key to '/etc/nginx/ssl/mmilliot.key'
Certificats générés
Vérification de la configuration...
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
Démarrage de Nginx...
```

### Phase 6 : Système opérationnel

```
┌────────────────────────────────────────────────┐
│            Tous les services sont UP            │
├────────────────────────────────────────────────┤
│  ✓ MariaDB    (port 3306, réseau interne)      │
│  ✓ WordPress  (port 9000, réseau interne)      │
│  ✓ Nginx      (port 443, exposé)               │
├────────────────────────────────────────────────┤
│  Réseau:  srcs_inception                       │
│  Volumes: mariadb_data, wordpress_data         │
└────────────────────────────────────────────────┘

Système prêt à recevoir des requêtes HTTPS !
```

---

# 🛠️ COMMANDES ET DEBUGGING

## Commandes Docker Compose

### Démarrage

```bash
# Build + démarrage
docker-compose up

# Build + démarrage en arrière-plan
docker-compose up -d

# Build forcé (sans cache)
docker-compose up --build

# Build sans cache + démarrage
docker-compose up --build --force-recreate
```

### Arrêt

```bash
# Arrête les conteneurs (mais les garde)
docker-compose stop

# Arrête et supprime les conteneurs
docker-compose down

# Arrête, supprime conteneurs + volumes (PERTE DE DONNÉES)
docker-compose down -v

# Arrête, supprime conteneurs + volumes + images
docker-compose down -v --rmi all
```

### Logs

```bash
# Tous les logs
docker-compose logs

# Logs d'un service
docker-compose logs nginx

# Logs en temps réel
docker-compose logs -f

# Logs en temps réel d'un service
docker-compose logs -f wordpress

# Dernières 50 lignes
docker-compose logs --tail=50
```

### État des services

```bash
# Liste des conteneurs
docker-compose ps

# Liste détaillée
docker-compose ps -a

# Processus dans les conteneurs
docker-compose top
```

### Reconstruction

```bash
# Rebuild une image
docker-compose build nginx

# Rebuild toutes les images
docker-compose build

# Rebuild sans cache
docker-compose build --no-cache
```

### Redémarrage

```bash
# Redémarre tous les services
docker-compose restart

# Redémarre un service
docker-compose restart wordpress
```

## Commandes Docker natives

### Images

```bash
# Liste des images
docker images

# Supprimer une image
docker rmi srcs_nginx

# Supprimer toutes les images non utilisées
docker image prune -a

# Détails d'une image
docker image inspect srcs_nginx
```

### Conteneurs

```bash
# Liste des conteneurs actifs
docker ps

# Liste de tous les conteneurs
docker ps -a

# Détails d'un conteneur
docker inspect wordpress

# Arrêter un conteneur
docker stop wordpress

# Démarrer un conteneur
docker start wordpress

# Supprimer un conteneur
docker rm wordpress

# Supprimer tous les conteneurs arrêtés
docker container prune
```

### Volumes

```bash
# Liste des volumes
docker volume ls

# Détails d'un volume
docker volume inspect srcs_wordpress_data

# Supprimer un volume
docker volume rm srcs_wordpress_data

# Supprimer tous les volumes non utilisés
docker volume prune

# Supprimer TOUS les volumes (ATTENTION)
docker volume prune -a
```

### Réseaux

```bash
# Liste des réseaux
docker network ls

# Détails d'un réseau
docker network inspect srcs_inception

# Supprimer un réseau
docker network rm srcs_inception

# Supprimer tous les réseaux non utilisés
docker network prune
```

## Entrer dans un conteneur

```bash
# Ouvrir un shell dans un conteneur en cours d'exécution
docker-compose exec wordpress bash

# Alternative avec Docker natif
docker exec -it wordpress bash

# Exécuter une commande sans shell interactif
docker-compose exec wordpress ls -la /var/www/html

# En tant qu'un autre utilisateur
docker-compose exec -u www-data wordpress bash
```

## Debugging avancé

### Vérifier les logs détaillés

```bash
# Logs avec timestamps
docker-compose logs -f --timestamps

# Logs depuis une date
docker-compose logs --since="2026-01-13T10:00:00"

# Logs des 10 dernières minutes
docker-compose logs --since=10m
```

### Vérifier la connectivité réseau

```bash
# Depuis WordPress vers MariaDB
docker-compose exec wordpress ping mariadb

# Tester le port MySQL
docker-compose exec wordpress nc -zv mariadb 3306

# Tester la connexion MySQL
docker-compose exec wordpress mariadb -h mariadb -u toto -ptoto -e "SHOW DATABASES;"

# DNS lookup
docker-compose exec wordpress nslookup mariadb

# Voir les connexions réseau
docker-compose exec wordpress netstat -tuln
```

### Vérifier les volumes

```bash
# Lister les fichiers WordPress
docker-compose exec wordpress ls -la /var/www/html

# Vérifier les permissions
docker-compose exec wordpress ls -la /var/www/html/wp-config.php

# Voir l'utilisation disque
docker-compose exec wordpress du -sh /var/www/html

# Voir les bases MariaDB
docker-compose exec mariadb ls -la /var/lib/mysql
```

### Vérifier les processus

```bash
# Processus PHP-FPM
docker-compose exec wordpress ps aux | grep php-fpm

# Processus Nginx
docker-compose exec nginx ps aux | grep nginx

# Processus MySQL
docker-compose exec mariadb ps aux | grep mysql
```

### Vérifier les ports

```bash
# Ports ouverts dans un conteneur
docker-compose exec wordpress netstat -tuln

# Port mapping de l'hôte
docker port nginx

# Vérifier si le port 443 est accessible
curl -k https://localhost:443
```

### Tester les configurations

```bash
# Tester la config Nginx
docker-compose exec nginx nginx -t

# Recharger la config Nginx (sans redémarrage)
docker-compose exec nginx nginx -s reload

# Vérifier la version PHP
docker-compose exec wordpress php -v

# Configuration PHP
docker-compose exec wordpress php -i | grep "Configuration File"

# Variables d'environnement
docker-compose exec wordpress env

# Tester WP-CLI
docker-compose exec wordpress wp --info --allow-root
```

### Analyser les problèmes de performance

```bash
# Statistiques en temps réel
docker stats

# Statistiques d'un conteneur
docker stats wordpress

# Utilisation mémoire
docker-compose exec wordpress free -h

# Utilisation CPU
docker-compose exec wordpress top
```

## Problèmes courants et solutions

### 1. "Port 443 already in use"

```bash
# Trouver ce qui utilise le port
sudo lsof -i :443

# Tuer le processus
sudo kill -9 <PID>

# Ou changer le port dans docker-compose.yml
ports:
  - "8443:443"  # Utiliser le port 8443 sur l'hôte
```

### 2. "Cannot connect to MariaDB"

```bash
# Vérifier que MariaDB tourne
docker-compose ps mariadb

# Voir les logs MariaDB
docker-compose logs mariadb

# Tester la connexion depuis WordPress
docker-compose exec wordpress mariadb -h mariadb -u toto -ptoto
```

### 3. "502 Bad Gateway" sur Nginx

```bash
# Vérifier que PHP-FPM tourne
docker-compose exec wordpress ps aux | grep php-fpm

# Vérifier que le port 9000 est ouvert
docker-compose exec wordpress netstat -tuln | grep 9000

# Tester la connexion Nginx → WordPress
docker-compose exec nginx ping wordpress
docker-compose exec nginx nc -zv wordpress 9000
```

### 4. "Permission denied" dans WordPress

```bash
# Vérifier les permissions
docker-compose exec wordpress ls -la /var/www/html

# Corriger les permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html
docker-compose exec wordpress chmod -R 755 /var/www/html
```

### 5. WordPress affiche "Error establishing database connection"

```bash
# Vérifier wp-config.php
docker-compose exec wordpress cat /var/www/html/wp-config.php | grep DB_

# Vérifier que les variables sont correctes
docker-compose exec wordpress env | grep MYSQL

# Tester manuellement la connexion
docker-compose exec wordpress mariadb -h mariadb -u toto -ptoto -e "USE mariaDatabase; SHOW TABLES;"
```

### 6. "Build failed" lors du docker-compose build

```bash
# Build avec output détaillé
docker-compose build --progress=plain

# Build sans cache
docker-compose build --no-cache

# Nettoyer le cache de build
docker builder prune
```

### 7. Volumes vides après redémarrage

```bash
# Vérifier que les volumes existent
docker volume ls

# Inspecter le volume
docker volume inspect srcs_wordpress_data

# Vérifier le contenu du volume
docker run --rm -v srcs_wordpress_data:/data alpine ls -la /data
```

---

# 📖 GLOSSAIRE TECHNIQUE COMPLET

## A

**Alpine Linux** : Distribution Linux ultra-légère (5 MB) souvent utilisée comme base pour les images Docker.

**API (Application Programming Interface)** : Interface pour communiquer entre programmes.

**APT (Advanced Package Tool)** : Gestionnaire de paquets de Debian/Ubuntu.

## B

**Backend** : Partie serveur d'une application (invisible pour l'utilisateur).

**Bash** : Shell Unix, interpréteur de commandes.

**Bind Mount** : Montage d'un répertoire hôte dans un conteneur.

**Bridge Network** : Réseau virtuel isolé pour connecter des conteneurs.

**Build Context** : Ensemble des fichiers envoyés au Docker daemon lors du build.

## C

**Cache** : Stockage temporaire pour accélérer les accès futurs.

**Certificate Authority (CA)** : Autorité qui signe les certificats SSL/TLS.

**CGI (Common Gateway Interface)** : Protocole pour exécuter des scripts côté serveur.

**CI/CD** : Continuous Integration / Continuous Deployment (intégration et déploiement continus).

**CLI (Command Line Interface)** : Interface en ligne de commande.

**CMS (Content Management System)** : Système de gestion de contenu (ex: WordPress).

**Container** : Instance exécutable d'une image Docker.

**CRUD** : Create, Read, Update, Delete (opérations de base de données).

## D

**Daemon** : Programme qui tourne en arrière-plan.

**Database** : Base de données, système de stockage structuré.

**Debian** : Distribution Linux stable et populaire.

**Dependency** : Dépendance, un composant dont un autre a besoin.

**DNS (Domain Name System)** : Système de résolution de noms de domaine en adresses IP.

**Docker** : Plateforme de containerisation.

**Docker Compose** : Outil pour définir et gérer des applications multi-conteneurs.

**Docker Engine** : Moteur qui exécute les conteneurs.

**Docker Hub** : Registre public d'images Docker.

**Dockerfile** : Fichier d'instructions pour construire une image.

**Document Root** : Répertoire racine des fichiers web.

## E

**Environment Variable** : Variable d'environnement, configuration passée au programme.

**Entrypoint** : Point d'entrée, première commande exécutée dans un conteneur.

**Exec** : Exécuter une commande dans un conteneur en cours d'exécution.

**Expose** : Déclarer un port dans un Dockerfile (documentation).

## F

**FastCGI** : Protocole pour communiquer entre serveur web et application.

**Filesystem** : Système de fichiers.

**Foreground** : Premier plan (opposé de background/daemon).

**Frontend** : Partie visible d'une application (interface utilisateur).

**FPM (FastCGI Process Manager)** : Gestionnaire de processus PHP.

## G

**Gateway** : Passerelle réseau.

**Git** : Système de contrôle de version.

## H

**Hash** : Empreinte cryptographique d'un fichier ou mot de passe.

**Heredoc** : Syntaxe pour écrire du texte multi-lignes dans un script.

**Host** : Machine hôte qui exécute Docker.

**HTTPS (HTTP Secure)** : Protocole HTTP chiffré avec SSL/TLS.

## I

**Idempotence** : Propriété d'une opération qui donne le même résultat si exécutée plusieurs fois.

**Image** : Modèle en lecture seule pour créer des conteneurs.

**Index** : Fichier par défaut servi pour un répertoire (ex: index.php).

**Isolation** : Séparation entre conteneurs/processus.

## J

**JSON (JavaScript Object Notation)** : Format de données structuré.

## K

**Kernel** : Noyau du système d'exploitation.

## L

**Layer** : Couche d'une image Docker (chaque instruction Dockerfile crée une couche).

**Localhost** : Adresse de bouclage locale (127.0.0.1).

**Log** : Journal des événements d'un programme.

## M

**MariaDB** : Fork open-source de MySQL.

**Mount** : Montage, action de rendre accessible un filesystem.

**MySQL** : Système de gestion de base de données relationnelle.

## N

**Namespace** : Espace de noms, mécanisme d'isolation Linux.

**Network** : Réseau Docker pour connecter des conteneurs.

**Nginx** : Serveur web et reverse proxy performant.

**Node** : Nœud, machine dans un réseau.

## O

**Orchestration** : Coordination automatisée de plusieurs conteneurs.

**OS (Operating System)** : Système d'exploitation.

## P

**Package** : Paquet logiciel.

**Permission** : Droit d'accès à un fichier (lecture, écriture, exécution).

**Permalink** : URL permanente (jolies URLs de WordPress).

**PID (Process ID)** : Identifiant unique d'un processus.

**Plugin** : Extension pour ajouter des fonctionnalités.

**Port** : Point de communication réseau (ex: 443 pour HTTPS).

**Port Mapping** : Redirection de port hôte vers conteneur.

**Process** : Processus, programme en cours d'exécution.

**Proxy** : Intermédiaire entre client et serveur.

**Prune** : Nettoyer les ressources Docker non utilisées.

## Q

**Query** : Requête (SQL, HTTP, etc.).

## R

**RDBMS (Relational Database Management System)** : Système de gestion de base de données relationnelle.

**Regex (Regular Expression)** : Expression régulière pour rechercher des motifs.

**Repository** : Dépôt (code source ou images Docker).

**Reverse Proxy** : Serveur qui redirige les requêtes vers d'autres serveurs.

**Root** : Racine (superutilisateur ou répertoire /).

**RSA** : Algorithme de chiffrement asymétrique.

## S

**Schema** : Schéma, structure d'une base de données.

**Server** : Serveur, machine ou programme qui fournit des services.

**Service** : Service Docker Compose, définition d'un conteneur.

**Shebang** : Première ligne d'un script (`#!/bin/bash`).

**Shell** : Interpréteur de commandes (bash, sh, zsh).

**Signal** : Message envoyé à un processus (SIGTERM, SIGKILL).

**Socket** : Point de communication (fichier Unix ou port TCP).

**SQL (Structured Query Language)** : Langage de requête pour bases de données.

**SSL (Secure Sockets Layer)** : Ancien nom de TLS.

**Subnet** : Sous-réseau.

## T

**TCP (Transmission Control Protocol)** : Protocole de transport fiable.

**Theme** : Thème WordPress (apparence du site).

**TLS (Transport Layer Security)** : Protocole de chiffrement pour sécuriser les communications.

**TTL (Time To Live)** : Durée de vie d'un élément en cache.

## U

**UID (User ID)** : Identifiant numérique d'un utilisateur.

**Upstream** : Serveur backend dans une configuration proxy.

**URL (Uniform Resource Locator)** : Adresse web.

**UTF-8** : Encodage de caractères universel.

## V

**Virtual Host** : Serveur virtuel (plusieurs sites sur une machine).

**Volume** : Espace de stockage persistant pour conteneurs.

## W

**WordPress** : CMS populaire écrit en PHP.

**WP-CLI** : Outil en ligne de commande pour gérer WordPress.

**www-data** : Utilisateur système par défaut pour les serveurs web sous Debian.

## X

**X.509** : Standard pour les certificats numériques.

## Y

**YAML (YAML Ain't Markup Language)** : Format de configuration lisible.

---

# 🎓 CONCLUSION

Vous avez maintenant une compréhension complète de votre projet Inception :

## Ce que vous savez maintenant

✅ **Docker** : Images, conteneurs, volumes, réseaux
✅ **Docker Compose** : Orchestration multi-conteneurs
✅ **Nginx** : Serveur web, reverse proxy, SSL/TLS
✅ **PHP-FPM** : Exécution de code PHP
✅ **WordPress** : Installation, configuration, WP-CLI
✅ **MariaDB** : Base de données, utilisateurs, permissions
✅ **Réseaux** : DNS Docker, communication inter-conteneurs
✅ **Volumes** : Persistance des données
✅ **SSL/TLS** : Certificats, chiffrement
✅ **Debugging** : Logs, inspection, résolution de problèmes

## Architecture finale

```
┌──────────────────────────────────────────────────────┐
│                   Projet Inception                    │
│                                                        │
│  Client HTTPS → Nginx → WordPress → MariaDB          │
│                   ↓         ↓          ↓              │
│              SSL/TLS   PHP-FPM    MySQL/3306         │
│                   ↓         ↓          ↓              │
│              Port 443  Port 9000  (interne)          │
│                                                        │
│  Volumes: wordpress_data, mariadb_data               │
│  Réseau:  inception (bridge)                         │
└──────────────────────────────────────────────────────┘
```

## Pour aller plus loin

- **Makefile** : Automatiser les commandes
- **Secrets Docker** : Sécuriser les mots de passe
- **Health checks** : Vérifier la santé des conteneurs
- **Services bonus** : Redis, FTP, Adminer, etc.
- **Monitoring** : Prometheus, Grafana
- **CI/CD** : GitHub Actions, GitLab CI

---

**Bon courage pour votre projet Inception ! 🚀**
