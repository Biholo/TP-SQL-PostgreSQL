# Schéma physique de la base de données - Bibliothèque universitaire

## Analyse du besoin et modélisation

### Entités identifiées

1. **AUTEUR** - Représente les auteurs des livres
2. **LIVRE** - Représente les ouvrages disponibles dans la bibliothèque
3. **ETUDIANT** - Représente les utilisateurs de la bibliothèque
4. **EMPRUNT** - Représente les transactions d'emprunt de livres

### Relations et cardinalités

```
AUTEUR (1,n) ←→ (0,n) LIVRE
- Un auteur peut écrire plusieurs livres
- Un livre a un seul auteur principal

LIVRE (1,n) ←→ (0,n) EMPRUNT
- Un livre peut être emprunté plusieurs fois
- Un emprunt concerne un seul livre

ETUDIANT (1,n) ←→ (0,n) EMPRUNT
- Un étudiant peut faire plusieurs emprunts
- Un emprunt est fait par un seul étudiant
```

## Structure détaillée des tables

### Table AUTEUR
```sql
auteur (
    id SERIAL PRIMARY KEY,           -- Identifiant unique
    nom TEXT NOT NULL,               -- Nom de famille
    prenom TEXT NOT NULL,            -- Prénom
    nationalite TEXT NOT NULL        -- Nationalité
)
```

### Table LIVRE
```sql
livre (
    isbn TEXT PRIMARY KEY,           -- ISBN (identifiant unique du livre)
    titre TEXT NOT NULL,             -- Titre du livre
    id_auteur INT NOT NULL,          -- Référence vers auteur
    annee_publication INT NOT NULL,  -- Année de publication (> 1800)
    genre TEXT NOT NULL,             -- Genre littéraire
    nb_exemplaires INT NOT NULL,     -- Nombre d'exemplaires disponibles (≥ 0)
    
    FOREIGN KEY (id_auteur) REFERENCES auteur(id),
    CHECK (annee_publication > 1800),
    CHECK (nb_exemplaires >= 0)
)
```

### Table ETUDIANT
```sql
etudiant (
    id SERIAL PRIMARY KEY,           -- Identifiant unique
    nom TEXT NOT NULL,               -- Nom de famille
    prenom TEXT NOT NULL,            -- Prénom
    date_naissance DATE NOT NULL,    -- Date de naissance
    email TEXT NOT NULL UNIQUE,      -- Email (unique)
    dernier_emprunt DATE             -- Date du dernier emprunt (peut être NULL)
)
```

### Table EMPRUNT
```sql
emprunt (
    id SERIAL PRIMARY KEY,           -- Identifiant unique
    id_etudiant INT NOT NULL,        -- Référence vers étudiant
    isbn TEXT NOT NULL,              -- Référence vers livre
    date_emprunt DATE NOT NULL,      -- Date d'emprunt (défaut: aujourd'hui)
    date_retour_prevue DATE NOT NULL,-- Date de retour prévue
    date_retour_reelle DATE,         -- Date de retour réelle (NULL si pas encore rendu)
    
    FOREIGN KEY (id_etudiant) REFERENCES etudiant(id),
    FOREIGN KEY (isbn) REFERENCES livre(isbn)
)
```

## Contraintes métier implémentées

### 1. Contrainte des 5 emprunts maximum
```sql
-- Trigger qui vérifie qu'un étudiant n'a pas plus de 5 emprunts en cours
CREATE TRIGGER trigger_max_emprunts
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_max_emprunts();
```

### 2. Contrainte de disponibilité des exemplaires
```sql
-- Trigger qui vérifie qu'il reste des exemplaires disponibles
CREATE TRIGGER trigger_exemplaires_disponibles
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_exemplaires_disponibles();
```

### 3. Contrainte de double emprunt
```sql
-- Trigger qui empêche un étudiant d'emprunter deux fois le même livre
CREATE TRIGGER trigger_double_emprunt
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_double_emprunt();
```

## Index pour optimisation

```sql
-- Index sur les clés étrangères et colonnes fréquemment utilisées
CREATE INDEX idx_emprunt_etudiant ON emprunt(id_etudiant);
CREATE INDEX idx_emprunt_livre ON emprunt(isbn);
CREATE INDEX idx_emprunt_retour ON emprunt(date_retour_reelle);
CREATE INDEX idx_livre_auteur ON livre(id_auteur);
```

## Vues principales

### v_emprunts_en_cours
Vue qui affiche tous les emprunts non retournés avec les informations complètes de l'étudiant, du livre et de l'auteur.

### v_statistiques_etudiant
Vue qui calcule les statistiques par étudiant : nombre total d'emprunts, emprunts en cours, nombre de retards, moyenne des jours de retard.

### v_catalogue_public
Vue simplifiée du catalogue pour les consultants externes, sans informations sur les étudiants.

## Fonctions utilitaires

- **nb_emprunts_etudiant(id)** : Retourne le nombre total d'emprunts d'un étudiant
- **nb_emprunts_en_cours_etudiant(id)** : Retourne le nombre d'emprunts en cours d'un étudiant
- **livres_disponibles()** : Retourne la liste des livres avec exemplaires disponibles
- **retourner_livre(id_emprunt)** : Marque un emprunt comme retourné

## Règles de gestion

1. **Durée d'emprunt** : 30 jours par défaut
2. **Limite d'emprunts** : Maximum 5 livres par étudiant simultanément
3. **Disponibilité** : Un livre ne peut être emprunté que s'il reste des exemplaires
4. **Unicité** : Un étudiant ne peut pas emprunter le même livre deux fois sans l'avoir rendu
5. **Historique** : Tous les emprunts sont conservés (même après retour)

## Sécurité et rôles

- **bibliothecaire** : CRUD complet sur toutes les tables
- **consultant** : Lecture seule sur livres et auteurs
- **etudiant_role** : Accès limité à ses propres données

## Diagramme conceptuel

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   AUTEUR    │ 1   n │    LIVRE    │ 1   n │   EMPRUNT   │
│             │───────│             │───────│             │
│ id (PK)     │       │ isbn (PK)   │       │ id (PK)     │
│ nom         │       │ titre       │       │ id_etudiant │
│ prenom      │       │ id_auteur   │       │ isbn        │
│ nationalite │       │ annee_pub   │       │ date_emp    │
└─────────────┘       │ genre       │       │ date_ret_p  │
                      │ nb_exemp    │       │ date_ret_r  │
                      └─────────────┘       └─────────────┘
                                                    │
                                                    │ n
                                                    │
                                                    │ 1
                                            ┌─────────────┐
                                            │  ETUDIANT   │
                                            │             │
                                            │ id (PK)     │
                                            │ nom         │
                                            │ prenom      │
                                            │ date_naiss  │
                                            │ email       │
                                            │ dernier_emp │
                                            └─────────────┘
```

## Évolutions possibles

1. **Table GENRE** : Normaliser les genres dans une table séparée
2. **Table EDITEUR** : Ajouter les informations d'éditeur
3. **Table RESERVATION** : Permettre la réservation de livres
4. **Table AMENDES** : Gérer les pénalités de retard
5. **Auteurs multiples** : Gérer les livres avec plusieurs auteurs
6. **Historique des modifications** : Audit trail des changements
7. **Notifications** : Système d'alertes pour les retards 