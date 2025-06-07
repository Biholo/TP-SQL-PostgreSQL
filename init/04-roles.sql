-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : roles.sql
-- Gestion des rôles et droits d'accès

-- ========================================
-- PARTIE 6 - SÉCURITÉ ET RÔLES
-- ========================================

-- Suppression des rôles s'ils existent déjà (pour pouvoir relancer le script)
DROP ROLE IF EXISTS bibliothecaire;
DROP ROLE IF EXISTS consultant;

-- ========================================
-- 6.1 - RÔLE BIBLIOTHECAIRE
-- ========================================

-- Création du rôle bibliothecaire
CREATE ROLE bibliothecaire WITH LOGIN PASSWORD 'biblio2024';

-- Droits sur toutes les tables : SELECT, INSERT, UPDATE, DELETE
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE auteur TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE livre TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE etudiant TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE emprunt TO bibliothecaire;

-- Droits sur les séquences (pour les SERIAL)
GRANT USAGE, SELECT ON SEQUENCE auteur_id_seq TO bibliothecaire;
GRANT USAGE, SELECT ON SEQUENCE etudiant_id_seq TO bibliothecaire;
GRANT USAGE, SELECT ON SEQUENCE emprunt_id_seq TO bibliothecaire;

-- Droits sur les vues
GRANT SELECT ON v_emprunts_en_cours TO bibliothecaire;
GRANT SELECT ON v_statistiques_etudiant TO bibliothecaire;

-- Droits d'exécution sur les fonctions
GRANT EXECUTE ON FUNCTION nb_emprunts_etudiant(INT) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION nb_emprunts_en_cours_etudiant(INT) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION livres_disponibles() TO bibliothecaire;
GRANT EXECUTE ON FUNCTION retourner_livre(INT) TO bibliothecaire;

-- Le bibliothecaire ne peut PAS modifier la structure (ALTER, DROP)
-- Ces droits ne sont pas accordés, donc interdits par défaut

-- ========================================
-- 6.2 - RÔLE CONSULTANT
-- ========================================

-- Création du rôle consultant
CREATE ROLE consultant WITH LOGIN PASSWORD 'consult2024';

-- Droits limités : SELECT uniquement sur livre et auteur
GRANT SELECT ON TABLE livre TO consultant;
GRANT SELECT ON TABLE auteur TO consultant;

-- Le consultant ne voit PAS les données des étudiants ou emprunts
-- Aucun droit accordé sur etudiant et emprunt

-- Droits sur une vue spéciale pour les consultants (catalogue public)
CREATE OR REPLACE VIEW v_catalogue_public AS
SELECT 
    l.isbn,
    l.titre,
    CONCAT(a.prenom, ' ', a.nom) as auteur,
    a.nationalite,
    l.annee_publication,
    l.genre,
    l.nb_exemplaires,
    COALESCE(emprunts_actifs.nb_empruntes, 0) as nb_empruntes,
    (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) as nb_disponibles,
    CASE 
        WHEN (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) > 0 
        THEN 'DISPONIBLE'
        ELSE 'INDISPONIBLE'
    END as statut_disponibilite
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
LEFT JOIN (
    SELECT isbn, COUNT(*) as nb_empruntes
    FROM emprunt 
    WHERE date_retour_reelle IS NULL
    GROUP BY isbn
) emprunts_actifs ON l.isbn = emprunts_actifs.isbn
ORDER BY l.titre;

-- Accorder l'accès à cette vue au consultant
GRANT SELECT ON v_catalogue_public TO consultant;

-- ========================================
-- TESTS DES RÔLES
-- ========================================

-- Test du rôle bibliothecaire
SELECT 'Test des droits du rôle bibliothecaire:' as test;

-- Simulation de connexion en tant que bibliothecaire
-- SET ROLE bibliothecaire;

-- Le bibliothecaire peut voir toutes les données
-- SELECT 'Emprunts visibles par bibliothecaire:' as info;
-- SELECT COUNT(*) as nb_emprunts FROM emprunt;

-- SELECT 'Étudiants visibles par bibliothecaire:' as info;
-- SELECT COUNT(*) as nb_etudiants FROM etudiant;

-- RESET ROLE;

-- Test du rôle consultant
SELECT 'Test des droits du rôle consultant:' as test;

-- Simulation de connexion en tant que consultant
-- SET ROLE consultant;

-- Le consultant peut voir le catalogue
-- SELECT 'Catalogue visible par consultant:' as info;
-- SELECT COUNT(*) as nb_livres FROM livre;

-- Le consultant ne peut PAS voir les emprunts (cette requête échouerait)
-- SELECT COUNT(*) FROM emprunt; -- ERREUR : permission denied

-- RESET ROLE;

-- ========================================
-- RÔLES SUPPLÉMENTAIRES (BONUS)
-- ========================================

-- Rôle pour un étudiant (lecture seule sur ses propres données)
CREATE ROLE etudiant_role WITH LOGIN PASSWORD 'etudiant2024';

-- Vue pour qu'un étudiant ne voie que ses propres emprunts
CREATE OR REPLACE FUNCTION mes_emprunts(email_etudiant TEXT)
RETURNS TABLE(
    titre_livre TEXT,
    auteur TEXT,
    date_emprunt DATE,
    date_retour_prevue DATE,
    date_retour_reelle DATE,
    statut TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.titre,
        CONCAT(a.prenom, ' ', a.nom) as auteur,
        em.date_emprunt,
        em.date_retour_prevue,
        em.date_retour_reelle,
        CASE 
            WHEN em.date_retour_reelle IS NULL AND em.date_retour_prevue < CURRENT_DATE THEN 'EN RETARD'
            WHEN em.date_retour_reelle IS NULL THEN 'EN COURS'
            WHEN em.date_retour_reelle > em.date_retour_prevue THEN 'RENDU EN RETARD'
            ELSE 'RENDU À TEMPS'
        END as statut
    FROM emprunt em
    JOIN etudiant e ON em.id_etudiant = e.id
    JOIN livre l ON em.isbn = l.isbn
    JOIN auteur a ON l.id_auteur = a.id
    WHERE e.email = email_etudiant
    ORDER BY em.date_emprunt DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Droits pour le rôle étudiant
GRANT SELECT ON v_catalogue_public TO etudiant_role;
GRANT EXECUTE ON FUNCTION mes_emprunts(TEXT) TO etudiant_role;

-- ========================================
-- INFORMATIONS SUR LES RÔLES CRÉÉS
-- ========================================

SELECT 'Rôles créés dans la base de données:' as info;
SELECT rolname, rolcanlogin, rolcreaterole, rolcreatedb 
FROM pg_roles 
WHERE rolname IN ('bibliothecaire', 'consultant', 'etudiant_role');

SELECT 'Droits accordés aux rôles:' as info;
SELECT 
    grantee,
    table_name,
    privilege_type
FROM information_schema.table_privileges 
WHERE grantee IN ('bibliothecaire', 'consultant', 'etudiant_role')
ORDER BY grantee, table_name, privilege_type;

-- ========================================
-- EXEMPLES D'UTILISATION DES RÔLES
-- ========================================

-- Pour tester les rôles, utiliser ces commandes :

-- 1. Se connecter en tant que bibliothecaire :
-- SET ROLE bibliothecaire;
-- SELECT * FROM emprunt; -- Fonctionne
-- INSERT INTO auteur (nom, prenom, nationalite) VALUES ('Test', 'Auteur', 'Test'); -- Fonctionne
-- RESET ROLE;

-- 2. Se connecter en tant que consultant :
-- SET ROLE consultant;
-- SELECT * FROM v_catalogue_public; -- Fonctionne
-- SELECT * FROM emprunt; -- ERREUR : permission denied
-- RESET ROLE;

-- 3. Se connecter en tant qu'étudiant :
-- SET ROLE etudiant_role;
-- SELECT * FROM mes_emprunts('marie.dupont@univ.fr'); -- Fonctionne
-- SELECT * FROM emprunt; -- ERREUR : permission denied
-- RESET ROLE; 