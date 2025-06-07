# 🐳 Environnement Docker - Bibliothèque Universitaire

## Description

Cet environnement Docker permet de déployer rapidement et facilement la base de données PostgreSQL de la bibliothèque universitaire avec toutes les fonctionnalités et données de test.

## 🏗️ Architecture

```
📦 Projet optimisé
├── 🐳 docker-compose.yml          # Configuration Docker Compose
├── ⚙️ postgres.conf              # Configuration PostgreSQL  
├── 🚀 start.ps1                  # Script de démarrage Windows
├── 🚀 start.sh                   # Script de démarrage Linux/Mac
├── 📁 init/                      # Scripts SQL d'initialisation automatique
│   ├── 01-create_tables.sql      # Création des tables
│   ├── 02-insert_data.sql        # Insertion des données
│   ├── 03-views_and_functions.sql # Vues et fonctions
│   ├── 04-roles.sql              # Rôles utilisateur
│   ├── 05-transaction_test.sql   # Tests des transactions
│   └── 06-test_complet.sql       # Tests complets
└── 📚 README-Docker.md           # Ce fichier
```

## 🚀 Démarrage rapide

### Prérequis
- Docker installé sur votre machine
- Docker Compose installé

### 1. Démarrage automatisé

```bash
# Windows (PowerShell)
./start.ps1

# Linux/Mac (Bash)
chmod +x start.sh
./start.sh

# Ou manuellement
docker-compose up -d
```

### 2. Vérifier le déploiement

```bash
# Vérifier que les conteneurs sont en cours d'exécution
docker-compose ps

# Suivre les logs d'initialisation
docker-compose logs postgres

# Attendre que l'initialisation soit terminée (message "Bibliotheque universitaire prete!")
```

### 3. Se connecter à la base de données

```bash
# Via psql (si installé localement)
psql -h localhost -U admin -d bibliotheque_universitaire

# Via Docker
docker exec -it bibliotheque_postgres psql -U admin -d bibliotheque_universitaire

# Mot de passe : admin123
```

## 🔧 Services disponibles

### 📊 PostgreSQL Database
- **Host**: localhost
- **Port**: 5432
- **Database**: bibliotheque_universitaire
- **Username**: admin
- **Password**: admin123

### 🌐 PgAdmin (Interface Web)
- **URL**: http://localhost:8081
- **Email**: admin@bibliotheque.fr
- **Password**: admin123

#### Configuration de la connexion dans PgAdmin :
1. Aller sur http://localhost:8081
2. Se connecter avec les identifiants ci-dessus
3. Ajouter un nouveau serveur :
   - **Name**: Bibliothèque Universitaire
   - **Host**: postgres (nom du conteneur)
   - **Port**: 5432
   - **Database**: bibliotheque_universitaire
   - **Username**: admin
   - **Password**: admin123

## 🗂️ Données incluses

L'environnement est automatiquement initialisé avec :

### 👥 Utilisateurs et rôles
- **admin** : Administrateur système
- **bibliothecaire** : Accès complet aux données
- **consultant** : Lecture seule sur livres et auteurs
- **etudiant_role** : Accès limité aux données personnelles

### 📚 Données de test
- **5 auteurs** de nationalités variées
- **10 livres** répartis entre les auteurs
- **6 étudiants** d'âges différents
- **12 emprunts** avec différents scénarios

### 🔧 Fonctionnalités
- **3 contraintes métier** actives via triggers
- **Vues** pour consultation simplifiée
- **Fonctions** utilitaires
- **Tests complets** automatisés

## 🧪 Tests et vérifications

### Exécuter les tests manuellement

```bash
# Se connecter à la base
docker exec -it bibliotheque_postgres psql -U admin -d bibliotheque_universitaire

# Exécuter quelques requêtes de test
SELECT * FROM v_emprunts_en_cours;
SELECT * FROM v_statistiques_etudiant;
SELECT * FROM livres_disponibles();
```

### Consulter les logs complets

```bash
# Logs du conteneur PostgreSQL
docker-compose logs postgres

# Logs en temps réel
docker-compose logs -f postgres
```

## 🔄 Commandes utiles

### Gestion des conteneurs

```bash
# Démarrer l'environnement
docker-compose up -d

# Arrêter l'environnement
docker-compose down

# Redémarrer après modifications
docker-compose down && docker-compose up -d --build

# Supprimer complètement (données incluses)
docker-compose down -v
```

### Sauvegarde et restauration

```bash
# Sauvegarde de la base
docker exec bibliotheque_postgres pg_dump -U admin -d bibliotheque_universitaire > backup.sql

# Restauration (après avoir supprimé et recréé l'environnement)
docker exec -i bibliotheque_postgres psql -U admin -d bibliotheque_universitaire < backup.sql
```

### Accès aux fichiers de logs

```bash
# Accéder au conteneur
docker exec -it bibliotheque_postgres bash

# Consulter les logs PostgreSQL  
cat /var/lib/postgresql/data/log/postgresql-*.log
```

## 🛠️ Développement et personnalisation

### Modifier la configuration PostgreSQL

1. Éditer le fichier `postgres.conf`
2. Redémarrer les conteneurs :
   ```bash
   docker-compose down && docker-compose up -d
   ```

### Ajouter des scripts d'initialisation

1. Ajouter vos fichiers `.sql` dans le dossier `init/`
2. Les nommer avec un préfixe numérique (ex: `07-mon_script.sql`)
3. Redémarrer l'environnement :
   ```bash
   docker-compose down -v && docker-compose up -d
   ```

### Modifier les données d'initialisation

1. Éditer les fichiers dans `init/`
2. Supprimer les volumes existants :
   ```bash
   docker-compose down -v
   ```
3. Redémarrer :
   ```bash
   docker-compose up -d
   ```

## 🐛 Dépannage

### Problème de connexion
```bash
# Vérifier que PostgreSQL est prêt
docker exec bibliotheque_postgres pg_isready -U admin

# Vérifier les logs
docker-compose logs postgres
```

### Réinitialisation complète
```bash
# Supprimer tout et recommencer
docker-compose down -v
docker system prune -f
docker-compose up -d
```

### Port déjà utilisé (8081)
```bash
# Trouver le processus utilisant le port
lsof -i :8081  # Linux/Mac
netstat -ano | findstr :8081  # Windows

# Ou changer le port dans docker-compose.yml
```

## 📊 Surveillance

### Statistiques de performance

```sql
-- Se connecter et exécuter :
SELECT * FROM pg_stat_activity WHERE datname = 'bibliotheque_universitaire';
SELECT * FROM pg_stat_database WHERE datname = 'bibliotheque_universitaire';
```

### Espace disque

```bash
# Taille de la base de données
docker exec bibliotheque_postgres psql -U admin -d bibliotheque_universitaire -c "SELECT pg_size_pretty(pg_database_size('bibliotheque_universitaire'));"
```

## 🎯 Cas d'usage

### Pour le développement
- Base de données prête en 2 minutes
- Données de test cohérentes
- Environnement isolé et reproductible

### Pour les tests
- Tests automatisés inclus
- Contraintes métier vérifiées
- Rollback facile entre les tests

### Pour les démonstrations
- Interface web disponible (PgAdmin)
- Données réalistes
- Toutes les fonctionnalités opérationnelles

## ✨ Avantages de cette architecture

- ✅ **Configuration simplifiée** : Plus de fichiers inutiles (Dockerfile, docker.env)
- ✅ **Initialisation automatique** : PostgreSQL exécute automatiquement les scripts du dossier `init/`
- ✅ **Scripts optimisés** : Encodage correct, pas de caractères spéciaux
- ✅ **Ports disponibles** : PgAdmin sur 8081 pour éviter les conflits
- ✅ **Documentation à jour** : Reflet de la structure réelle du projet

## 🔗 Ressources

- [Documentation PostgreSQL](https://www.postgresql.org/docs/)
- [Documentation Docker](https://docs.docker.com/)
- [Documentation PgAdmin](https://www.pgadmin.org/docs/)

---

**🎉 Votre bibliothèque universitaire est maintenant containerisée et optimisée !** 