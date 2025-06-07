-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : queries.sql
-- Toutes les requêtes simples, jointures, agrégats et sous-requêtes

-- ========================================
-- PARTIE 3.1 - REQUÊTES SIMPLES
-- ========================================

-- Liste de tous les livres (titre, année, genre)
SELECT 'Liste de tous les livres:' as requete;
SELECT titre, annee_publication, genre 
FROM livre 
ORDER BY titre;

-- Étudiants nés après 2000
SELECT 'Étudiants nés après 2000:' as requete;
SELECT nom, prenom, date_naissance 
FROM etudiant 
WHERE date_naissance > '2000-12-31'
ORDER BY date_naissance;

-- Livres disponibles actuellement (avec exemplaires disponibles)
SELECT 'Livres disponibles actuellement:' as requete;
SELECT l.titre, l.nb_exemplaires, 
       COALESCE(emprunts_actifs.nb_empruntes, 0) as nb_empruntes,
       (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) as nb_disponibles
FROM livre l
LEFT JOIN (
    SELECT isbn, COUNT(*) as nb_empruntes
    FROM emprunt 
    WHERE date_retour_reelle IS NULL
    GROUP BY isbn
) emprunts_actifs ON l.isbn = emprunts_actifs.isbn
WHERE (l.nb_exemplaires - COALESCE(emprunts_actifs.nb_empruntes, 0)) > 0
ORDER BY l.titre;

-- Liste des emails des étudiants
SELECT 'Liste des emails des étudiants:' as requete;
SELECT email 
FROM etudiant 
ORDER BY email;

-- Liste des livres publiés après 2015
SELECT 'Livres publiés après 2015:' as requete;
SELECT titre, annee_publication 
FROM livre 
WHERE annee_publication > 2015
ORDER BY annee_publication DESC;

-- ========================================
-- PARTIE 3.2 - REQUÊTES AVEC JOINTURES
-- ========================================

-- Liste des livres avec auteur complet
SELECT 'Livres avec auteur complet:' as requete;
SELECT l.titre, l.annee_publication, l.genre,
       CONCAT(a.prenom, ' ', a.nom) as auteur_complet,
       a.nationalite
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
ORDER BY l.titre;

-- Emprunts en cours (non retournés) avec nom de l'étudiant et titre du livre
SELECT 'Emprunts en cours:' as requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       l.titre,
       em.date_emprunt,
       em.date_retour_prevue,
       CASE 
           WHEN em.date_retour_prevue < CURRENT_DATE THEN 'EN RETARD'
           ELSE 'À TEMPS'
       END as statut
FROM emprunt em
JOIN etudiant e ON em.id_etudiant = e.id
JOIN livre l ON em.isbn = l.isbn
WHERE em.date_retour_reelle IS NULL
ORDER BY em.date_emprunt;

-- Étudiants ayant emprunté un livre d'un auteur français
SELECT 'Étudiants ayant emprunté un livre d''auteur français:' as requete;
SELECT DISTINCT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       l.titre,
       CONCAT(a.prenom, ' ', a.nom) as auteur_francais
FROM emprunt em
JOIN etudiant e ON em.id_etudiant = e.id
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
WHERE a.nationalite = 'Française'
ORDER BY etudiant;

-- Historique complet des emprunts d'un étudiant donné (Marie Dupont - id=1)
SELECT 'Historique des emprunts de Marie Dupont:' as requete;
SELECT l.titre,
       CONCAT(a.prenom, ' ', a.nom) as auteur,
       em.date_emprunt,
       em.date_retour_prevue,
       em.date_retour_reelle,
       CASE 
           WHEN em.date_retour_reelle IS NULL THEN 'EN COURS'
           WHEN em.date_retour_reelle > em.date_retour_prevue THEN 'RENDU EN RETARD'
           ELSE 'RENDU À TEMPS'
       END as statut
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
WHERE em.id_etudiant = 1
ORDER BY em.date_emprunt;

-- Liste des livres empruntés par au moins 2 étudiants différents
SELECT 'Livres empruntés par au moins 2 étudiants différents:' as requete;
SELECT l.titre,
       CONCAT(a.prenom, ' ', a.nom) as auteur,
       COUNT(DISTINCT em.id_etudiant) as nb_etudiants_differents
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
GROUP BY l.isbn, l.titre, a.prenom, a.nom
HAVING COUNT(DISTINCT em.id_etudiant) >= 2
ORDER BY nb_etudiants_differents DESC;

-- ========================================
-- PARTIE 4 - AGRÉGATS, REGROUPEMENTS ET STATISTIQUES
-- ========================================

-- Nombre de livres par genre
SELECT 'Nombre de livres par genre:' as requete;
SELECT genre, COUNT(*) as nombre_livres
FROM livre
GROUP BY genre
ORDER BY nombre_livres DESC;

-- Moyenne d'âge des étudiants
SELECT 'Moyenne d''âge des étudiants:' as requete;
SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(date_naissance))), 2) as age_moyen
FROM etudiant;

-- Nombre de livres empruntés par chaque étudiant
SELECT 'Nombre de livres empruntés par étudiant:' as requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       COUNT(em.id) as total_emprunts,
       COUNT(CASE WHEN em.date_retour_reelle IS NULL THEN 1 END) as emprunts_en_cours
FROM etudiant e
LEFT JOIN emprunt em ON e.id = em.id_etudiant
GROUP BY e.id, e.prenom, e.nom
ORDER BY total_emprunts DESC;

-- Nombre d'emprunts par nationalité d'auteur
SELECT 'Nombre d''emprunts par nationalité d''auteur:' as requete;
SELECT a.nationalite,
       COUNT(em.id) as nombre_emprunts
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
GROUP BY a.nationalite
ORDER BY nombre_emprunts DESC;

-- Nombre d'emprunts encore en retard
SELECT 'Nombre d''emprunts en retard:' as requete;
SELECT COUNT(*) as emprunts_en_retard
FROM emprunt
WHERE date_retour_reelle IS NULL 
AND date_retour_prevue < CURRENT_DATE;

-- Moyenne de jours de retard par étudiant (pour les livres rendus en retard)
SELECT 'Moyenne de jours de retard par étudiant:' as requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       COUNT(*) as nb_retards,
       ROUND(AVG(date_retour_reelle - date_retour_prevue), 2) as moyenne_jours_retard
FROM emprunt em
JOIN etudiant e ON em.id_etudiant = e.id
WHERE em.date_retour_reelle IS NOT NULL 
AND em.date_retour_reelle > em.date_retour_prevue
GROUP BY e.id, e.prenom, e.nom
ORDER BY moyenne_jours_retard DESC;

-- Top 3 des auteurs les plus empruntés
SELECT 'Top 3 des auteurs les plus empruntés:' as requete;
SELECT CONCAT(a.prenom, ' ', a.nom) as auteur,
       a.nationalite,
       COUNT(em.id) as nombre_emprunts
FROM emprunt em
JOIN livre l ON em.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
GROUP BY a.id, a.prenom, a.nom, a.nationalite
ORDER BY nombre_emprunts DESC
LIMIT 3;

-- ========================================
-- SOUS-REQUÊTES (Partie 5.2)
-- ========================================

-- Étudiants ayant emprunté plus de 3 livres
SELECT 'Étudiants ayant emprunté plus de 3 livres:' as requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       (SELECT COUNT(*) FROM emprunt WHERE id_etudiant = e.id) as total_emprunts
FROM etudiant e
WHERE (SELECT COUNT(*) FROM emprunt WHERE id_etudiant = e.id) > 3
ORDER BY total_emprunts DESC;

-- Livres jamais empruntés
SELECT 'Livres jamais empruntés:' as requete;
SELECT l.titre,
       CONCAT(a.prenom, ' ', a.nom) as auteur
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
WHERE l.isbn NOT IN (SELECT DISTINCT isbn FROM emprunt)
ORDER BY l.titre;

-- Étudiants ayant toujours rendu leurs livres en retard
SELECT 'Étudiants ayant toujours rendu en retard:' as requete;
SELECT CONCAT(e.prenom, ' ', e.nom) as etudiant,
       COUNT(*) as nb_emprunts_rendus
FROM etudiant e
JOIN emprunt em ON e.id = em.id_etudiant
WHERE em.date_retour_reelle IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM emprunt em2 
    WHERE em2.id_etudiant = e.id 
    AND em2.date_retour_reelle IS NOT NULL
    AND em2.date_retour_reelle <= em2.date_retour_prevue
)
GROUP BY e.id, e.prenom, e.nom
HAVING COUNT(*) > 0;

-- Auteurs dont aucun livre n'a été emprunté
SELECT 'Auteurs dont aucun livre n''a été emprunté:' as requete;
SELECT CONCAT(a.prenom, ' ', a.nom) as auteur,
       a.nationalite
FROM auteur a
WHERE NOT EXISTS (
    SELECT 1 FROM livre l 
    JOIN emprunt em ON l.isbn = em.isbn 
    WHERE l.id_auteur = a.id
)
ORDER BY a.nom; 