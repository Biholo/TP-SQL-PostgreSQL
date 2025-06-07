-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : views_and_functions.sql
-- Création des vues, fonctions et triggers

-- ========================================
-- PARTIE 5.1 - CRÉATION DE VUES
-- ========================================

-- Vue : emprunts en cours avec informations complètes
CREATE OR REPLACE VIEW v_emprunts_en_cours AS
SELECT 
    em.id as id_emprunt,
    CONCAT(e.prenom, ' ', e.nom) as nom_prenom_etudiant,
    e.email,
    l.titre as titre_livre,
    CONCAT(a.prenom, ' ', a.nom) as auteur_livre,
    em.date_emprunt,
    em.date_retour_prevue,
    CASE 
        WHEN em.date_retour_prevue < CURRENT_DATE THEN 'EN RETARD'
        ELSE 'À TEMPS'
    END as statut,
    CASE 
        WHEN em.date_retour_prevue < CURRENT_DATE 
        THEN CURRENT_DATE - em.date_retour_prevue
        ELSE 0
    END as jours_retard
FROM emprunt em
JOIN etudiant e ON em.id_etudiant = e.id
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
WHERE em.date_retour_reelle IS NULL;

-- Vue : statistiques par étudiant
CREATE OR REPLACE VIEW v_statistiques_etudiant AS
SELECT 
    e.id,
    CONCAT(e.prenom, ' ', e.nom) as nom_prenom,
    e.email,
    COALESCE(stats.total_emprunts, 0) as nombre_total_emprunts,
    COALESCE(stats.emprunts_en_cours, 0) as emprunts_en_cours,
    COALESCE(stats.nombre_retards, 0) as nombre_retards,
    COALESCE(ROUND(stats.moyenne_jours_retard, 2), 0) as moyenne_jours_retard,
    e.dernier_emprunt as date_dernier_emprunt
FROM etudiant e
LEFT JOIN (
    SELECT 
        em.id_etudiant,
        COUNT(*) as total_emprunts,
        COUNT(CASE WHEN em.date_retour_reelle IS NULL THEN 1 END) as emprunts_en_cours,
        COUNT(CASE WHEN em.date_retour_reelle > em.date_retour_prevue THEN 1 END) as nombre_retards,
        AVG(CASE 
            WHEN em.date_retour_reelle > em.date_retour_prevue 
            THEN em.date_retour_reelle - em.date_retour_prevue 
            ELSE NULL 
        END) as moyenne_jours_retard
    FROM emprunt em
    GROUP BY em.id_etudiant
) stats ON e.id = stats.id_etudiant;

-- ========================================
-- PARTIE 7.1 - FONCTION PERSONNALISÉE
-- ========================================

-- Fonction pour compter le nombre total d'emprunts d'un étudiant
CREATE OR REPLACE FUNCTION nb_emprunts_etudiant(id_etudiant_param INT)
RETURNS INT AS $$
DECLARE
    nb_emprunts INT;
BEGIN
    SELECT COUNT(*) INTO nb_emprunts
    FROM emprunt
    WHERE id_etudiant = id_etudiant_param;
    
    RETURN COALESCE(nb_emprunts, 0);
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir le nombre d'emprunts en cours d'un étudiant
CREATE OR REPLACE FUNCTION nb_emprunts_en_cours_etudiant(id_etudiant_param INT)
RETURNS INT AS $$
DECLARE
    nb_emprunts_cours INT;
BEGIN
    SELECT COUNT(*) INTO nb_emprunts_cours
    FROM emprunt
    WHERE id_etudiant = id_etudiant_param 
    AND date_retour_reelle IS NULL;
    
    RETURN COALESCE(nb_emprunts_cours, 0);
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- PARTIE 7.2 - TRIGGER AVANCÉ
-- ========================================

-- Fonction trigger pour mettre à jour dernier_emprunt et vérifier les contraintes
CREATE OR REPLACE FUNCTION trigger_after_insert_emprunt()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour la date du dernier emprunt de l'étudiant
    UPDATE etudiant 
    SET dernier_emprunt = NEW.date_emprunt
    WHERE id = NEW.id_etudiant;
    
    -- Vérifier que l'étudiant n'a pas plus de 5 emprunts actifs
    -- (Cette vérification est déjà faite par le trigger BEFORE INSERT,
    -- mais on la refait ici pour être sûr après l'insertion)
    IF (SELECT COUNT(*) 
        FROM emprunt 
        WHERE id_etudiant = NEW.id_etudiant 
        AND date_retour_reelle IS NULL) > 5 THEN
        RAISE EXCEPTION 'ERREUR: L''étudiant % a maintenant plus de 5 emprunts actifs', NEW.id_etudiant;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger AFTER INSERT sur emprunt
CREATE TRIGGER trigger_after_emprunt_insert
    AFTER INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION trigger_after_insert_emprunt();

-- ========================================
-- FONCTIONS UTILITAIRES SUPPLÉMENTAIRES
-- ========================================

-- Fonction pour obtenir les livres disponibles (CORRIGÉE)
CREATE OR REPLACE FUNCTION livres_disponibles()
RETURNS TABLE(
    livre_isbn TEXT,
    livre_titre TEXT,
    livre_auteur TEXT,
    livre_nb_exemplaires INT,
    livre_nb_empruntes INT,
    livre_nb_disponibles INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.isbn as livre_isbn,
        l.titre as livre_titre,
        CONCAT(a.prenom, ' ', a.nom) as livre_auteur,
        l.nb_exemplaires as livre_nb_exemplaires,
        COALESCE(emprunts_actifs.nb_empruntes, 0) as livre_nb_empruntes,
        (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) as livre_nb_disponibles
    FROM livre l
    JOIN auteur a ON l.id_auteur = a.id
    LEFT JOIN (
        SELECT em.isbn, COUNT(*) as nb_empruntes
        FROM emprunt em
        WHERE em.date_retour_reelle IS NULL
        GROUP BY em.isbn
    ) emprunts_actifs ON l.isbn = emprunts_actifs.isbn
    WHERE (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) > 0
    ORDER BY l.titre;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour simuler le retour d'un livre
CREATE OR REPLACE FUNCTION retourner_livre(id_emprunt_param INT)
RETURNS BOOLEAN AS $$
DECLARE
    emprunt_existe BOOLEAN;
BEGIN
    -- Vérifier que l'emprunt existe et n'est pas déjà retourné
    SELECT EXISTS(
        SELECT 1 FROM emprunt 
        WHERE id = id_emprunt_param 
        AND date_retour_reelle IS NULL
    ) INTO emprunt_existe;
    
    IF NOT emprunt_existe THEN
        RAISE EXCEPTION 'Emprunt % non trouvé ou déjà retourné', id_emprunt_param;
    END IF;
    
    -- Mettre à jour la date de retour
    UPDATE emprunt 
    SET date_retour_reelle = CURRENT_DATE
    WHERE id = id_emprunt_param;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- TESTS DES VUES ET FONCTIONS
-- ========================================

-- Test de la vue des emprunts en cours
SELECT 'Test de la vue v_emprunts_en_cours:' as test;
SELECT * FROM v_emprunts_en_cours ORDER BY date_emprunt;

-- Test de la vue des statistiques étudiants
SELECT 'Test de la vue v_statistiques_etudiant:' as test;
SELECT * FROM v_statistiques_etudiant ORDER BY nombre_total_emprunts DESC;

-- Test de la fonction nb_emprunts_etudiant
SELECT 'Test de la fonction nb_emprunts_etudiant:' as test;
SELECT 
    CONCAT(e.prenom, ' ', e.nom) as etudiant,
    nb_emprunts_etudiant(e.id) as nb_emprunts
FROM etudiant e
ORDER BY nb_emprunts_etudiant(e.id) DESC;

-- Test de la fonction livres_disponibles
SELECT 'Test de la fonction livres_disponibles:' as test;
SELECT * FROM livres_disponibles(); 