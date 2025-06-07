-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : test_complet.sql
-- Test complet de toutes les fonctionnalités

-- ========================================
-- TEST 1 : VÉRIFICATION DES TABLES CRÉÉES
-- ========================================

SELECT '=== TEST 1 : Vérification des tables créées ===' as test_section;

-- Lister toutes les tables
SELECT 'Tables créées dans la base:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Vérifier la structure des tables
SELECT 'Structure de la table auteur:' as info;
\d auteur;

SELECT 'Structure de la table livre:' as info;
\d livre;

SELECT 'Structure de la table etudiant:' as info;
\d etudiant;

SELECT 'Structure de la table emprunt:' as info;
\d emprunt;

-- ========================================
-- TEST 2 : VÉRIFICATION DES DONNÉES INSÉRÉES
-- ========================================

SELECT '=== TEST 2 : Vérification des données insérées ===' as test_section;

SELECT 'Nombre d''auteurs:' as info, COUNT(*) as total FROM auteur;
SELECT 'Nombre de livres:' as info, COUNT(*) as total FROM livre;
SELECT 'Nombre d''étudiants:' as info, COUNT(*) as total FROM etudiant;
SELECT 'Nombre d''emprunts:' as info, COUNT(*) as total FROM emprunt;

-- Vérifier quelques données spécifiques
SELECT 'Auteurs français:' as info;
SELECT nom, prenom FROM auteur WHERE nationalite = 'Française';

SELECT 'Livres épuisés (0 exemplaire):' as info;
SELECT titre, nb_exemplaires FROM livre WHERE nb_exemplaires = 0;

SELECT 'Étudiant avec 5 emprunts (Thomas Petit):' as info;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant, COUNT(*) as nb_emprunts_actifs
FROM etudiant e
JOIN emprunt em ON e.id = em.id_etudiant
WHERE em.date_retour_reelle IS NULL
GROUP BY e.id, e.prenom, e.nom
HAVING COUNT(*) = 5;

-- ========================================
-- TEST 3 : VÉRIFICATION DES CONTRAINTES
-- ========================================

SELECT '=== TEST 3 : Test des contraintes métier ===' as test_section;

-- Test 1 : Tentative d'emprunt d'un livre épuisé (doit échouer)
SELECT 'TEST 3.1 : Tentative d''emprunt d''un livre épuisé' as test_contrainte;
DO $$
BEGIN
    BEGIN
        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
        VALUES (1, '978-0-439-06486-6', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
        RAISE NOTICE 'ERREUR: L''insertion aurait dû échouer!';
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'SUCCÈS: Contrainte respectée - %', SQLERRM;
    END;
END $$;

-- Test 2 : Tentative de 6ème emprunt pour Thomas Petit (doit échouer)
SELECT 'TEST 3.2 : Tentative de 6ème emprunt (limite dépassée)' as test_contrainte;
DO $$
BEGIN
    BEGIN
        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
        VALUES (6, '978-2-07-041799-1', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
        RAISE NOTICE 'ERREUR: L''insertion aurait dû échouer!';
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'SUCCÈS: Contrainte respectée - %', SQLERRM;
    END;
END $$;

-- Test 3 : Tentative de double emprunt du même livre (doit échouer)
SELECT 'TEST 3.3 : Tentative de double emprunt du même livre' as test_contrainte;
DO $$
DECLARE
    etudiant_test INT;
    livre_test TEXT;
BEGIN
    -- Trouver un étudiant qui a déjà un emprunt en cours
    SELECT em.id_etudiant, em.isbn 
    INTO etudiant_test, livre_test
    FROM emprunt em 
    WHERE em.date_retour_reelle IS NULL 
    LIMIT 1;
    
    IF etudiant_test IS NOT NULL THEN
        BEGIN
            INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
            VALUES (etudiant_test, livre_test, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
            RAISE NOTICE 'ERREUR: L''insertion aurait dû échouer!';
        EXCEPTION 
            WHEN OTHERS THEN
                RAISE NOTICE 'SUCCÈS: Contrainte respectée - %', SQLERRM;
        END;
    END IF;
END $$;

-- ========================================
-- TEST 4 : VÉRIFICATION DES VUES
-- ========================================

SELECT '=== TEST 4 : Test des vues ===' as test_section;

SELECT 'TEST 4.1 : Vue v_emprunts_en_cours' as test_vue;
SELECT COUNT(*) as nb_emprunts_en_cours FROM v_emprunts_en_cours;
SELECT * FROM v_emprunts_en_cours LIMIT 3;

SELECT 'TEST 4.2 : Vue v_statistiques_etudiant' as test_vue;
SELECT COUNT(*) as nb_etudiants FROM v_statistiques_etudiant;
SELECT nom_prenom, nombre_total_emprunts, emprunts_en_cours 
FROM v_statistiques_etudiant 
ORDER BY nombre_total_emprunts DESC 
LIMIT 3;

-- ========================================
-- TEST 5 : VÉRIFICATION DES FONCTIONS
-- ========================================

SELECT '=== TEST 5 : Test des fonctions ===' as test_section;

SELECT 'TEST 5.1 : Fonction nb_emprunts_etudiant()' as test_fonction;
SELECT 
    CONCAT(e.prenom, ' ', e.nom) as etudiant,
    nb_emprunts_etudiant(e.id) as nb_emprunts_total
FROM etudiant e
ORDER BY nb_emprunts_etudiant(e.id) DESC
LIMIT 3;

SELECT 'TEST 5.2 : Fonction nb_emprunts_en_cours_etudiant()' as test_fonction;
SELECT 
    CONCAT(e.prenom, ' ', e.nom) as etudiant,
    nb_emprunts_en_cours_etudiant(e.id) as nb_emprunts_en_cours
FROM etudiant e
WHERE nb_emprunts_en_cours_etudiant(e.id) > 0
ORDER BY nb_emprunts_en_cours_etudiant(e.id) DESC;

SELECT 'TEST 5.3 : Fonction livres_disponibles()' as test_fonction;
SELECT COUNT(*) as nb_livres_disponibles FROM livres_disponibles();
SELECT * FROM livres_disponibles() LIMIT 3;

SELECT 'TEST 5.4 : Test de la fonction retourner_livre()' as test_fonction;
DO $$
DECLARE
    emprunt_test INT;
BEGIN
    -- Trouver un emprunt en cours pour le test
    SELECT id INTO emprunt_test 
    FROM emprunt 
    WHERE date_retour_reelle IS NULL 
    LIMIT 1;
    
    IF emprunt_test IS NOT NULL THEN
        -- Sauvegarder l'état avant
        RAISE NOTICE 'Test de retour du livre - Emprunt ID: %', emprunt_test;
        
        -- Effectuer le retour
        PERFORM retourner_livre(emprunt_test);
        RAISE NOTICE 'SUCCÈS: Livre retourné avec succès';
        
        -- Vérifier que le retour a bien été enregistré
        IF EXISTS(SELECT 1 FROM emprunt WHERE id = emprunt_test AND date_retour_reelle IS NOT NULL) THEN
            RAISE NOTICE 'VÉRIFICATION: Date de retour bien enregistrée';
        END IF;
    END IF;
END $$;

-- ========================================
-- TEST 6 : VÉRIFICATION DES REQUÊTES COMPLEXES
-- ========================================

SELECT '=== TEST 6 : Test des requêtes complexes ===' as test_section;

SELECT 'TEST 6.1 : Emprunts en retard' as test_requete;
SELECT COUNT(*) as nb_emprunts_en_retard
FROM emprunt
WHERE date_retour_reelle IS NULL 
AND date_retour_prevue < CURRENT_DATE;

SELECT 'TEST 6.2 : Top 3 des auteurs les plus empruntés' as test_requete;
SELECT CONCAT(a.prenom, ' ', a.nom) as auteur,
       COUNT(em.id) as nombre_emprunts
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
GROUP BY a.id, a.prenom, a.nom
ORDER BY nombre_emprunts DESC
LIMIT 3;

SELECT 'TEST 6.3 : Étudiants avec plus de 3 emprunts' as test_requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       COUNT(em.id) as total_emprunts
FROM etudiant e
JOIN emprunt em ON e.id = em.id_etudiant
GROUP BY e.id, e.prenom, e.nom
HAVING COUNT(em.id) > 3
ORDER BY total_emprunts DESC;

-- ========================================
-- TEST 7 : VÉRIFICATION DES RÔLES (si exécuté en tant que superuser)
-- ========================================

SELECT '=== TEST 7 : Vérification des rôles ===' as test_section;

SELECT 'Rôles créés:' as info;
SELECT rolname, rolcanlogin 
FROM pg_roles 
WHERE rolname IN ('bibliothecaire', 'consultant', 'etudiant_role');

SELECT 'Droits accordés:' as info;
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges 
WHERE grantee IN ('bibliothecaire', 'consultant', 'etudiant_role')
ORDER BY grantee, table_name;

-- ========================================
-- TEST 8 : STATISTIQUES GÉNÉRALES
-- ========================================

SELECT '=== TEST 8 : Statistiques générales du système ===' as test_section;

SELECT 'Résumé du système:' as statistiques;
SELECT 
    (SELECT COUNT(*) FROM auteur) as nb_auteurs,
    (SELECT COUNT(*) FROM livre) as nb_livres,
    (SELECT COUNT(*) FROM etudiant) as nb_etudiants,
    (SELECT COUNT(*) FROM emprunt) as nb_emprunts_total,
    (SELECT COUNT(*) FROM emprunt WHERE date_retour_reelle IS NULL) as nb_emprunts_en_cours,
    (SELECT COUNT(*) FROM emprunt WHERE date_retour_reelle IS NULL AND date_retour_prevue < CURRENT_DATE) as nb_emprunts_en_retard;

SELECT 'Distribution des emprunts par genre:' as statistiques;
SELECT l.genre, COUNT(em.id) as nb_emprunts
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
GROUP BY l.genre
ORDER BY nb_emprunts DESC;

SELECT 'Moyenne d''âge des étudiants:' as statistiques;
SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(date_naissance))), 2) as age_moyen
FROM etudiant;

-- ========================================
-- RÉSULTAT FINAL
-- ========================================

SELECT '=== TESTS TERMINÉS ===' as fin_tests;
SELECT 'Si aucune erreur n''est apparue, le système fonctionne correctement!' as resultat; 