# Guide Docker - Documentation Complète

## Table des matières
- [Introduction](#introduction)
- [Gestion des Images](#gestion-des-images)
- [Gestion des Conteneurs](#gestion-des-conteneurs)
- [Docker Hub et Registres](#docker-hub-et-registres)
- [Docker Compose](#docker-compose)
- [Dockerfile](#dockerfile)
- [Couches d'Images](#couches-dimages)

---

## Introduction

Docker est une plateforme de conteneurisation qui permet d'empaqueter, distribuer et exécuter des applications dans des environnements isolés appelés conteneurs.

---

## Gestion des Images

### Créer et Builder une Image

Pour créer une image à partir d'un dossier contenant un Dockerfile :

```bash
docker build -t DOCKER_USERNAME/nom-de-limage .
```

**Exemple :**
```bash
docker build -t DOCKER_USERNAME/getting-started-todo-app .
```

### Lister les Images

Pour vérifier si l'image a bien été créée :

```bash
docker image ls
```

### Historique d'une Image

Pour répertorier les couches (layers) d'une image :

```bash
docker image history nom-image
```

### Pousser une Image sur Docker Hub

Une fois l'image créée, vous pouvez la partager sur Docker Hub :

```bash
docker push DOCKER_USERNAME/nom-de-limage
```

### Rechercher et Télécharger des Images

Docker Hub est un registre public qui contient des milliers d'images prêtes à l'emploi et approuvées par Docker.

```bash
# Rechercher une image
docker search nom-image

# Télécharger une image (comme git pull)
docker pull nom-image
```

---

## Gestion des Conteneurs

### Lancer un Conteneur

Pour exécuter une image dans un conteneur :

```bash
docker run nom-image
```

### Voir les Conteneurs

```bash
# Voir uniquement les conteneurs en cours d'exécution
docker ps

# Voir tous les conteneurs (actifs et arrêtés)
docker ps -a
```

### Arrêter un Conteneur

```bash
docker stop <container-ID>
```

---

## Docker Hub et Registres

### Concept de Registre

Un **registre** est un dossier qui contient plusieurs dépôts, qui eux-mêmes contiennent des images. On peut le comparer à GitHub qui contient des repositories avec des projets.

**Structure :**
```
Registre
  ├── repo1
  │   ├── image1
  │   └── image2
  └── repo2
      ├── image1
      └── image2
```

**Exemples de registres :**
- Docker Hub (public)
- Amazon ECR (Amazon)
- Google Container Registry (Google)
- Azure Container Registry (Microsoft)

---

## Docker Compose

### Concept

Docker Compose permet de **relier plusieurs conteneurs** pour faire fonctionner plusieurs services ensemble. Il permet de lancer toutes les images avec une seule commande.

### Principe Important

> **Best Practice :** Un conteneur doit faire **une chose mais le faire bien**. C'est une mauvaise pratique d'avoir un seul conteneur pour faire tourner plusieurs services. Docker Compose sert donc à lier tous les conteneurs pour faire fonctionner l'application complète.

### Lancer une Application avec Docker Compose

```bash
docker compose up -d
```

Le flag `-d` (detached) permet de lancer les conteneurs en arrière-plan.

### Arrêter une Application

Pas besoin de fermer tous les conteneurs manuellement :

```bash
docker compose down
```

### Persistance des Données

Par défaut, les volumes ne sont **pas automatiquement supprimés** lors du `docker compose down`, dans l'idée de pouvoir récupérer les données lors d'un redémarrage.

Pour supprimer également les volumes :

```bash
docker compose down --volumes
```

### Exemple de fichier `compose.yaml`

```yaml
services:
  app:
    image: node:18-alpine
    command: sh -c "yarn install && yarn run dev"
    ports:
      - 127.0.0.1:3000:3000
    working_dir: /app
    volumes:
      - ./:/app
    environment:
      MYSQL_HOST: mysql
      MYSQL_USER: root
      MYSQL_PASSWORD: secret
      MYSQL_DB: todos

  mysql:
    image: mysql:8.0
    volumes:
      - todo-mysql-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: todos

volumes:
  todo-mysql-data:
```

### Explication de l'exemple

Lors du `docker compose up` :
- Définit tous les services de l'application ainsi que leurs configurations
- Chaque service spécifie son image, ses ports, ses volumes, ses réseaux et tous autres paramètres nécessaires

Dans cet exemple :
- **Service `app`** : Application Node.js qui se connecte à MySQL
- **Service `mysql`** : Base de données MySQL
- **Volume `todo-mysql-data`** : Stockage persistant pour les données MySQL

### ⚠️ Attention

**Bien utiliser les lignes de commande et pas l'IDE** car l'IDE ne supprime pas le réseau quand on supprime les conteneurs d'une application, contrairement à la ligne de commande.

---

## Dockerfile

### Qu'est-ce qu'un Dockerfile ?

Un **Dockerfile** est un document textuel utilisé pour créer une image de conteneur. Il fournit des instructions au générateur d'images sur :
- Les commandes à exécuter
- Les fichiers à copier
- La commande de démarrage
- Etc.

### Exemple de Dockerfile

Voici un Dockerfile qui produit une application Python prête à l'emploi :

```dockerfile
FROM python:3.13
WORKDIR /usr/local/app

# Install the application dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy in the source code
COPY src ./src
EXPOSE 8080

# Setup an app user so the container doesn't run as the root user
RUN useradd app
USER app

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

### Instructions Principales

| Instruction | Description |
|------------|-------------|
| `FROM <image>` | Spécifie l'image de base que la construction étendra |
| `WORKDIR <path>` | Spécifie le "répertoire de travail" ou le chemin dans l'image où les fichiers seront copiés et les commandes exécutées |
| `COPY <host-path> <image-path>` | Indique au constructeur de copier les fichiers de l'hôte et de les mettre dans l'image du conteneur |
| `RUN <command>` | Indique au constructeur d'exécuter la commande spécifiée |
| `ENV <name> <value>` | Définit une variable d'environnement qu'un conteneur en cours d'exécution utilisera |
| `EXPOSE <port-number>` | Définit la configuration sur l'image qui indique un port que l'image aimerait exposer |
| `USER <user-or-uid>` | Définit l'utilisateur par défaut pour toutes les instructions suivantes |
| `CMD ["<command>", "<arg1>"]` | Définit la commande par défaut qu'un conteneur utilisant cette image exécutera |

### Initialisation Rapide

Pour conteneuriser rapidement de nouveaux projets :

```bash
docker init
```

Cette commande crée automatiquement :
- Un fichier `compose.yaml`
- Un fichier `.dockerignore`

---

## Couches d'Images

### Concept

Les **couches d'images** (layers) permettent l'ajout, la suppression ou la modification du système de fichiers de l'image.

### Créer une Nouvelle Couche Manuellement

Vous pouvez créer l'image que vous voulez en tant qu'image de base, puis ajouter ce que vous voulez dans une image. Quand vous êtes satisfait :

```bash
docker container commit -m "MESSAGE" image_precedente nouvelle_image
```

Cela crée une nouvelle couche de l'image.

### ⚠️ Note Importante

**La plupart des builds n'utilisent pas `docker container commit`**. À la place, on utilise un **Dockerfile** (voir section précédente) qui est la méthode recommandée et la plus reproductible.

---

## Résumé des Commandes Essentielles

| Commande | Description |
|----------|-------------|
| `docker build -t nom .` | Créer une image |
| `docker run nom` | Lancer un conteneur |
| `docker ps` | Lister les conteneurs actifs |
| `docker ps -a` | Lister tous les conteneurs |
| `docker stop <ID>` | Arrêter un conteneur |
| `docker image ls` | Lister les images |
| `docker push nom` | Pousser sur Docker Hub |
| `docker pull nom` | Télécharger une image |
| `docker compose up -d` | Lancer une application multi-conteneurs |
| `docker compose down` | Arrêter une application |
| `docker compose down --volumes` | Arrêter et supprimer les volumes |
| `docker init` | Initialiser un nouveau projet Docker |

---

## Bonnes Pratiques

1. **Un conteneur = Une responsabilité** : Chaque conteneur doit faire une chose et la faire bien
2. **Utiliser Docker Compose** pour les applications multi-services
3. **Ne pas exécuter en tant que root** : Créer un utilisateur dédié dans le Dockerfile
4. **Utiliser .dockerignore** : Pour exclure les fichiers inutiles
5. **Utiliser la CLI plutôt que l'IDE** : Pour une gestion complète (notamment des réseaux)
6. **Nommer ses images clairement** : Utiliser le format `username/project-name:tag`

---

*Document créé à partir de recherches et notes personnelles sur Docker*
