# TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire

## 🐳 Démarrage rapide avec Docker (RECOMMANDÉ)

**La méthode la plus simple pour tester le projet :**

### Windows (PowerShell)
```powershell
./start.ps1
```

### Linux/Mac (Bash)
```bash
chmod +x start.sh
./start.sh
```

### Manuellement
```bash
docker-compose up -d
```

**Ensuite :** 
- PostgreSQL : `localhost:5432` (admin/admin123)
- PgAdmin : http://localhost:8081 (admin@bibliotheque.fr/admin123)

📚 **Documentation complète Docker :** [README-Docker.md](README-Docker.md)

---

## Description du projet

Ce projet implémente une base de données complète pour la gestion d'une bibliothèque universitaire avec PostgreSQL. Il comprend la création des tables, l'insertion de données de test, des requêtes complexes, des vues, des fonctions, des triggers et la gestion des rôles utilisateur.

## Structure du projet

```
📦 Projet optimisé
├── 🐳 DOCKER                     # Environnement containerisé
│   ├── docker-compose.yml        # Configuration Docker Compose
│   ├── postgres.conf             # Configuration PostgreSQL
│   ├── start.ps1                 # Script de démarrage Windows
│   ├── start.sh                  # Script de démarrage Linux/Mac
│   └── init/                     # Scripts d'initialisation automatique
│       ├── 01-create_tables.sql  # Création des tables et contraintes
│       ├── 02-insert_data.sql    # Insertion des données de test
│       ├── 03-views_and_functions.sql # Vues, fonctions et triggers
│       ├── 04-roles.sql          # Gestion des rôles et droits d'accès
│       ├── 05-transaction_test.sql # Tests de transactions
│       └── 06-test_complet.sql   # Tests automatisés complets
├── 📝 REQUÊTES SQL               # Scripts de référence
│   └── queries.sql               # Requêtes d'exemple et jointures
└── 📚 DOCUMENTATION              # Documentation complète
    ├── README.md                 # Ce fichier (guide principal)
    ├── README-Docker.md          # Guide Docker détaillé
    └── schema_description.md     # Documentation du schéma de données
```

## Installation et utilisation

### 🚀 Méthode recommandée : Docker

L'installation avec Docker est automatisée et ne nécessite aucune configuration manuelle de PostgreSQL.

1. **Démarrage automatique** : Exécutez `./start.ps1` (Windows) ou `./start.sh` (Linux/Mac)
2. **Accès immédiat** : La base est prête en 2 minutes avec toutes les données de test
3. **Interface web** : PgAdmin disponible sur http://localhost:8081

### 📋 Installation manuelle (PostgreSQL local)

Pour une installation manuelle, exécutez les scripts dans cet ordre :

1. **01-create_tables.sql** - Création de la structure de base
2. **02-insert_data.sql** - Insertion des données de test
3. **03-views_and_functions.sql** - Création des vues et fonctions
4. **04-roles.sql** - Configuration des rôles utilisateur
5. **queries.sql** - Requêtes d'exemple (optionnel)
6. **05-transaction_test.sql** - Tests des transactions (optionnel)

## Modèle de données

### Tables principales

- **auteur** : Informations sur les auteurs (id, nom, prénom, nationalité)
- **livre** : Catalogue des livres (ISBN, titre, auteur, année, genre, nb_exemplaires)
- **etudiant** : Étudiants inscrits (id, nom, prénom, date_naissance, email)
- **emprunt** : Historique des emprunts (id, étudiant, livre, dates)

### Contraintes implémentées

1. **Maximum 5 emprunts par étudiant** - Trigger automatique
2. **Vérification de disponibilité** - Pas d'emprunt si aucun exemplaire disponible
3. **Pas de double emprunt** - Un étudiant ne peut pas emprunter deux fois le même livre

## Fonctionnalités principales

### Vues créées

- **v_emprunts_en_cours** : Emprunts non retournés avec détails complets
- **v_statistiques_etudiant** : Statistiques par étudiant (nb emprunts, retards, etc.)
- **v_catalogue_public** : Catalogue visible par les consultants

### Fonctions utiles

- **nb_emprunts_etudiant(id)** : Compte le nombre total d'emprunts d'un étudiant
- **livres_disponibles()** : Liste des livres actuellement disponibles
- **retourner_livre(id_emprunt)** : Marque un livre comme retourné

### Rôles utilisateur

- **bibliothecaire** : Accès complet aux données (CRUD)
- **consultant** : Lecture seule sur livres et auteurs
- **etudiant_role** : Accès limité à ses propres données

## Données de test incluses

- **5 auteurs** de nationalités variées
- **10 livres** répartis entre les auteurs
- **6 étudiants** d'âges différents
- **12 emprunts** avec cas spécifiques :
  - Emprunts en retard
  - Emprunts en cours
  - Étudiant avec 5 emprunts (limite)
  - Livre épuisé (0 exemplaire)

## Exemples d'utilisation

### Connexion avec un rôle spécifique
```sql
SET ROLE bibliothecaire;
-- Maintenant vous avez les droits du bibliothécaire
SELECT * FROM emprunt;
RESET ROLE;
```

### Utilisation des fonctions
```sql
-- Nombre d'emprunts d'un étudiant
SELECT nb_emprunts_etudiant(1);

-- Livres disponibles
SELECT * FROM livres_disponibles();

-- Retourner un livre
SELECT retourner_livre(5);
```

### Consultation des vues
```sql
-- Emprunts en cours
SELECT * FROM v_emprunts_en_cours;

-- Statistiques des étudiants
SELECT * FROM v_statistiques_etudiant;
```

## Tests et validation

Le projet inclut des tests automatisés complets :

- **Tests de contraintes** : Vérification des règles métier
- **Tests de transactions** : Gestion des erreurs et rollback
- **Tests de performance** : Validation des index et requêtes
- **Tests de sécurité** : Vérification des rôles et permissions

## Commandes PostgreSQL utiles

```bash
# Se connecter à PostgreSQL (via Docker)
docker exec -it bibliotheque_postgres psql -U admin -d bibliotheque_universitaire

# Se connecter à PostgreSQL (installation locale)
psql -U username -d bibliotheque_universitaire

# Exécuter un script
\i queries.sql

# Lister les tables
\dt

# Décrire une table
\d nom_table

# Lister les rôles
\du
```

## Points forts du projet

- ✅ **Déploiement automatisé** avec Docker
- ✅ **Scripts réexécutables** (DROP IF EXISTS)
- ✅ **Contraintes métier** via triggers
- ✅ **Données de test réalistes** couvrant tous les cas d'usage
- ✅ **Sécurité granulaire** avec système de rôles
- ✅ **Tests automatisés** complets
- ✅ **Documentation exhaustive**

## Auteur

Projet réalisé dans le cadre du TP SQL/PostgreSQL sur la gestion d'une bibliothèque universitaire.
