-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : create_tables.sql
-- Création des tables avec contraintes

-- Suppression des tables si elles existent déjà (pour pouvoir relancer le script)
DROP TABLE IF EXISTS emprunt CASCADE;
DROP TABLE IF EXISTS livre CASCADE;
DROP TABLE IF EXISTS auteur CASCADE;
DROP TABLE IF EXISTS etudiant CASCADE;

-- Table auteur
CREATE TABLE auteur (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    nationalite TEXT NOT NULL
);

-- Table livre
CREATE TABLE livre (
    isbn TEXT PRIMARY KEY,
    titre TEXT NOT NULL,
    id_auteur INT NOT NULL REFERENCES auteur(id),
    annee_publication INT NOT NULL CHECK(annee_publication > 1800),
    genre TEXT NOT NULL,
    nb_exemplaires INT NOT NULL CHECK(nb_exemplaires >= 0)
);

-- Table etudiant
CREATE TABLE etudiant (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    date_naissance DATE NOT NULL,
    email TEXT NOT NULL UNIQUE,
    dernier_emprunt DATE
);

-- Table emprunt
CREATE TABLE emprunt (
    id SERIAL PRIMARY KEY,
    id_etudiant INT NOT NULL REFERENCES etudiant(id),
    isbn TEXT NOT NULL REFERENCES livre(isbn),
    date_emprunt DATE NOT NULL DEFAULT CURRENT_DATE,
    date_retour_prevue DATE NOT NULL,
    date_retour_reelle DATE
);

-- Contraintes supplémentaires

-- 1. Fonction pour vérifier qu'un étudiant n'a pas plus de 5 emprunts en cours
CREATE OR REPLACE FUNCTION check_max_emprunts()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) 
        FROM emprunt 
        WHERE id_etudiant = NEW.id_etudiant 
        AND date_retour_reelle IS NULL) >= 5 THEN
        RAISE EXCEPTION 'Un étudiant ne peut pas emprunter plus de 5 livres en même temps';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour vérifier le nombre maximum d'emprunts
CREATE TRIGGER trigger_max_emprunts
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_max_emprunts();

-- 2. Fonction pour vérifier la disponibilité des exemplaires
CREATE OR REPLACE FUNCTION check_exemplaires_disponibles()
RETURNS TRIGGER AS $$
DECLARE
    nb_emprunts_actifs INT;
    nb_exemplaires_total INT;
BEGIN
    -- Compter les emprunts actifs pour ce livre
    SELECT COUNT(*) INTO nb_emprunts_actifs
    FROM emprunt 
    WHERE isbn = NEW.isbn AND date_retour_reelle IS NULL;
    
    -- Récupérer le nombre total d'exemplaires
    SELECT nb_exemplaires INTO nb_exemplaires_total
    FROM livre 
    WHERE isbn = NEW.isbn;
    
    -- Vérifier la disponibilité
    IF nb_emprunts_actifs >= nb_exemplaires_total THEN
        RAISE EXCEPTION 'Aucun exemplaire disponible pour ce livre (ISBN: %)', NEW.isbn;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour vérifier la disponibilité des exemplaires
CREATE TRIGGER trigger_exemplaires_disponibles
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_exemplaires_disponibles();

-- 3. Fonction pour empêcher un double emprunt du même livre
CREATE OR REPLACE FUNCTION check_double_emprunt()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM emprunt 
        WHERE id_etudiant = NEW.id_etudiant 
        AND isbn = NEW.isbn 
        AND date_retour_reelle IS NULL
    ) THEN
        RAISE EXCEPTION 'Cet étudiant a déjà emprunté ce livre et ne l''a pas encore rendu';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour empêcher le double emprunt
CREATE TRIGGER trigger_double_emprunt
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_double_emprunt();

-- Index pour optimiser les performances
CREATE INDEX idx_emprunt_etudiant ON emprunt(id_etudiant);
CREATE INDEX idx_emprunt_livre ON emprunt(isbn);
CREATE INDEX idx_emprunt_retour ON emprunt(date_retour_reelle);
CREATE INDEX idx_livre_auteur ON livre(id_auteur);

COMMENT ON TABLE auteur IS 'Table des auteurs de livres';
COMMENT ON TABLE livre IS 'Table des livres disponibles dans la bibliothèque';
COMMENT ON TABLE etudiant IS 'Table des étudiants inscrits à la bibliothèque';
COMMENT ON TABLE emprunt IS 'Table des emprunts de livres par les étudiants'; 