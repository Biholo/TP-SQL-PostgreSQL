-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : transaction_test.sql
-- Tests de transactions et gestion des erreurs

-- ========================================
-- PARTIE 5.3 - TRANSACTION SIMULÉE
-- ========================================

-- Scénario 1 : Transaction réussie - Emprunt d'un livre disponible
SELECT 'SCÉNARIO 1 : Transaction réussie - Emprunt d''un livre disponible' as scenario;

BEGIN;
    -- Afficher l'état initial
    SELECT 'État initial du livre "Les Misérables":' as info;
    SELECT titre, nb_exemplaires, 
           (SELECT COUNT(*) FROM emprunt WHERE isbn = '978-2-07-036057-1' AND date_retour_reelle IS NULL) as emprunts_actifs
    FROM livre WHERE isbn = '978-2-07-036057-1';
    
    -- Tentative d'emprunt par Emma Bernard (id=5)
    INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
    VALUES (5, '978-2-07-036057-1', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
    
    -- Vérifier que l'emprunt a été créé
    SELECT 'Emprunt créé avec succès:' as info;
    SELECT em.id, CONCAT(e.prenom, ' ', e.nom) as etudiant, l.titre
    FROM emprunt em
    JOIN etudiant e ON em.id_etudiant = e.id
    JOIN livre l ON em.isbn = l.isbn
    WHERE em.id = currval('emprunt_id_seq');
    
COMMIT;
SELECT 'Transaction 1 : COMMIT réussi' as resultat;

-- ========================================

-- Scénario 2 : Transaction échouée - Tentative d'emprunt d'un livre épuisé
SELECT 'SCÉNARIO 2 : Transaction échouée - Livre épuisé' as scenario;

BEGIN;
    -- Afficher l'état du livre épuisé
    SELECT 'État du livre épuisé "Harry Potter et la Chambre des secrets":' as info;
    SELECT titre, nb_exemplaires
    FROM livre WHERE isbn = '978-0-439-06486-6';
    
    -- Tentative d'emprunt d'un livre épuisé (devrait échouer)
    -- Cette instruction va déclencher le trigger qui vérifie la disponibilité
    INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
    VALUES (4, '978-0-439-06486-6', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
    
COMMIT;

-- Cette partie ne sera jamais atteinte à cause de l'exception
SELECT 'Cette ligne ne devrait jamais s''afficher' as erreur;

-- ========================================

-- Scénario 3 : Transaction avec gestion d'exception
SELECT 'SCÉNARIO 3 : Transaction avec gestion d''exception' as scenario;

DO $$
DECLARE
    emprunt_id INT;
    livre_titre TEXT;
BEGIN
    -- Début de la transaction
    BEGIN
        SELECT 'Tentative d''emprunt d''un livre épuisé avec gestion d''erreur' as info;
        
        -- Récupérer le titre du livre pour l'affichage
        SELECT titre INTO livre_titre FROM livre WHERE isbn = '978-0-439-06486-6';
        
        -- Tentative d'emprunt (va échouer)
        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
        VALUES (3, '978-0-439-06486-6', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days')
        RETURNING id INTO emprunt_id;
        
        RAISE NOTICE 'Emprunt créé avec l''ID: %', emprunt_id;
        
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'ERREUR CAPTURÉE: %', SQLERRM;
            RAISE NOTICE 'Transaction annulée automatiquement (ROLLBACK)';
    END;
END $$;

-- ========================================

-- Scénario 4 : Transaction complexe - Emprunt avec vérifications multiples
SELECT 'SCÉNARIO 4 : Transaction complexe avec vérifications' as scenario;

DO $$
DECLARE
    etudiant_id INT := 2; -- Pierre Martin
    livre_isbn TEXT := '978-1-84343-068-9'; -- Kafka sur le rivage
    nb_emprunts_actuels INT;
    nb_exemplaires_dispo INT;
    emprunt_id INT;
BEGIN
    BEGIN
        -- Vérification 1 : Nombre d'emprunts actuels de l'étudiant
        SELECT COUNT(*) INTO nb_emprunts_actuels
        FROM emprunt 
        WHERE id_etudiant = etudiant_id AND date_retour_reelle IS NULL;
        
        RAISE NOTICE 'Étudiant % a actuellement % emprunts', etudiant_id, nb_emprunts_actuels;
        
        -- Vérification 2 : Disponibilité du livre
        SELECT (l.nb_exemplaires - COALESCE(emp.nb_empruntes, 0)) INTO nb_exemplaires_dispo
        FROM livre l
        LEFT JOIN (
            SELECT isbn, COUNT(*) as nb_empruntes
            FROM emprunt 
            WHERE date_retour_reelle IS NULL
            GROUP BY isbn
        ) emp ON l.isbn = emp.isbn
        WHERE l.isbn = livre_isbn;
        
        RAISE NOTICE 'Livre % a % exemplaires disponibles', livre_isbn, nb_exemplaires_dispo;
        
        -- Si tout est OK, procéder à l'emprunt
        IF nb_emprunts_actuels < 5 AND nb_exemplaires_dispo > 0 THEN
            INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
            VALUES (etudiant_id, livre_isbn, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days')
            RETURNING id INTO emprunt_id;
            
            RAISE NOTICE 'SUCCÈS: Emprunt créé avec l''ID %', emprunt_id;
        ELSE
            RAISE EXCEPTION 'Emprunt impossible: emprunts=%, disponibles=%', nb_emprunts_actuels, nb_exemplaires_dispo;
        END IF;
        
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'ERREUR dans la transaction: %', SQLERRM;
            -- Le ROLLBACK est automatique en cas d'exception
    END;
END $$;

-- ========================================

-- Scénario 5 : Test de la contrainte des 5 emprunts maximum
SELECT 'SCÉNARIO 5 : Test de la contrainte des 5 emprunts maximum' as scenario;

DO $$
DECLARE
    etudiant_thomas INT := 6; -- Thomas Petit qui a déjà 5 emprunts
BEGIN
    BEGIN
        SELECT 'Thomas Petit a déjà 5 emprunts, tentative d''un 6ème...' as info;
        
        -- Cette insertion devrait échouer à cause du trigger
        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) 
        VALUES (etudiant_thomas, '978-2-07-041799-1', CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');
        
        RAISE NOTICE 'ERREUR: Cette ligne ne devrait jamais s''afficher!';
        
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'SUCCÈS: Contrainte respectée - %', SQLERRM;
    END;
END $$;

-- ========================================

-- Scénario 6 : Transaction de retour de livre
SELECT 'SCÉNARIO 6 : Transaction de retour de livre' as scenario;

DO $$
DECLARE
    emprunt_a_retourner INT;
    etudiant_nom TEXT;
    livre_titre TEXT;
BEGIN
    BEGIN
        -- Trouver un emprunt en cours
        SELECT em.id, CONCAT(e.prenom, ' ', e.nom), l.titre
        INTO emprunt_a_retourner, etudiant_nom, livre_titre
        FROM emprunt em
        JOIN etudiant e ON em.id_etudiant = e.id
        JOIN livre l ON em.isbn = l.isbn
        WHERE em.date_retour_reelle IS NULL
        LIMIT 1;
        
        IF emprunt_a_retourner IS NOT NULL THEN
            RAISE NOTICE 'Retour du livre "%" emprunté par %', livre_titre, etudiant_nom;
            
            -- Utiliser la fonction de retour
            PERFORM retourner_livre(emprunt_a_retourner);
            
            RAISE NOTICE 'SUCCÈS: Livre retourné avec succès';
        ELSE
            RAISE NOTICE 'Aucun emprunt en cours trouvé';
        END IF;
        
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE NOTICE 'ERREUR lors du retour: %', SQLERRM;
    END;
END $$;

-- ========================================
-- VÉRIFICATIONS FINALES
-- ========================================

SELECT 'VÉRIFICATIONS FINALES' as section;

-- État des emprunts après tous les tests
SELECT 'État final des emprunts en cours:' as info;
SELECT * FROM v_emprunts_en_cours ORDER BY date_emprunt;

-- Statistiques des étudiants
SELECT 'Statistiques finales des étudiants:' as info;
SELECT * FROM v_statistiques_etudiant ORDER BY nombre_total_emprunts DESC; 