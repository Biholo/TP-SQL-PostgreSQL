-- TP SQL/PostgreSQL – Gestion d'une bibliothèque universitaire
-- Fichier : insert_data.sql
-- Insertion des données de test

-- Insertion des auteurs (5 auteurs avec nationalités variées)
INSERT INTO auteur (nom, prenom, nationalite) VALUES
('Hugo', 'Victor', 'Française'),
('Tolkien', 'J.R.R.', 'Britannique'),
('García Márquez', 'Gabriel', 'Colombienne'),
('Murakami', 'Haruki', 'Japonaise'),
('Rowling', 'J.K.', 'Britannique');

-- Insertion des livres (10 livres répartis entre les auteurs)
INSERT INTO livre (isbn, titre, id_auteur, annee_publication, genre, nb_exemplaires) VALUES
-- Livres de Victor Hugo
('978-2-07-036057-1', 'Les Misérables', 1, 1862, 'Roman historique', 3),
('978-2-07-041799-1', 'Notre-Dame de Paris', 1, 1831, 'Roman historique', 2),

-- Livres de J.R.R. Tolkien
('978-0-547-92822-7', 'Le Seigneur des Anneaux', 2, 1954, 'Fantasy', 4),
('978-0-547-92838-8', 'Le Hobbit', 2, 1937, 'Fantasy', 2),

-- Livres de Gabriel García Márquez
('978-0-06-088328-7', 'Cent ans de solitude', 3, 1967, 'Réalisme magique', 2),
('978-0-06-114455-1', 'L''Amour aux temps du choléra', 3, 1985, 'Romance', 1),

-- Livres de Haruki Murakami
('978-0-375-70427-4', 'Norwegian Wood', 4, 1987, 'Roman contemporain', 3),
('978-1-84343-068-9', 'Kafka sur le rivage', 4, 2002, 'Roman contemporain', 2),

-- Livres de J.K. Rowling
('978-0-439-70818-8', 'Harry Potter à l''école des sorciers', 5, 1997, 'Fantasy jeunesse', 5),
('978-0-439-06486-6', 'Harry Potter et la Chambre des secrets', 5, 1998, 'Fantasy jeunesse', 0); -- Livre épuisé

-- Insertion des étudiants (6 étudiants avec des âges variés)
INSERT INTO etudiant (nom, prenom, date_naissance, email) VALUES
('Dupont', 'Marie', '2001-03-15', 'marie.dupont@univ.fr'),      -- 23 ans
('Martin', 'Pierre', '1999-07-22', 'pierre.martin@univ.fr'),    -- 25 ans
('Durand', 'Sophie', '2003-11-08', 'sophie.durand@univ.fr'),    -- 21 ans
('Moreau', 'Lucas', '2000-01-30', 'lucas.moreau@univ.fr'),      -- 24 ans
('Bernard', 'Emma', '2002-09-12', 'emma.bernard@univ.fr'),      -- 22 ans
('Petit', 'Thomas', '1998-05-18', 'thomas.petit@univ.fr');      -- 26 ans

-- Insertion des emprunts (12 emprunts avec cas spécifiques)

-- Emprunts normaux rendus à temps
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue, date_retour_reelle) VALUES
(1, '978-2-07-036057-1', '2024-01-15', '2024-02-15', '2024-02-10'), -- Rendu à temps
(2, '978-0-547-92822-7', '2024-01-20', '2024-02-20', '2024-02-18'), -- Rendu à temps

-- Emprunts rendus en retard (2 cas)
(3, '978-0-06-088328-7', '2024-02-01', '2024-03-01', '2024-03-10'), -- Retard de 9 jours
(4, '978-0-375-70427-4', '2024-02-10', '2024-03-10', '2024-03-20'), -- Retard de 10 jours

-- Emprunts en cours (non retournés) - au moins 4 cas
(1, '978-0-547-92838-8', '2024-03-01', '2024-04-01', NULL),         -- En cours
(2, '978-2-07-041799-1', '2024-03-05', '2024-04-05', NULL),         -- En cours
(3, '978-1-84343-068-9', '2024-03-10', '2024-04-10', NULL),         -- En cours
(5, '978-0-439-70818-8', '2024-03-15', '2024-04-15', NULL),         -- En cours

-- Étudiant avec 5 emprunts (Thomas Petit - id 6)
(6, '978-2-07-036057-1', '2024-03-20', '2024-04-20', NULL),         -- Emprunt 1
(6, '978-0-547-92822-7', '2024-03-21', '2024-04-21', NULL),         -- Emprunt 2
(6, '978-0-06-088328-7', '2024-03-22', '2024-04-22', NULL),         -- Emprunt 3
(6, '978-0-375-70427-4', '2024-03-23', '2024-04-23', NULL),         -- Emprunt 4
(6, '978-0-439-70818-8', '2024-03-24', '2024-04-24', NULL);         -- Emprunt 5

-- Mise à jour des dates de dernier emprunt pour les étudiants
UPDATE etudiant SET dernier_emprunt = '2024-03-10' WHERE id = 1;
UPDATE etudiant SET dernier_emprunt = '2024-03-05' WHERE id = 2;
UPDATE etudiant SET dernier_emprunt = '2024-03-10' WHERE id = 3;
UPDATE etudiant SET dernier_emprunt = '2024-02-10' WHERE id = 4;
UPDATE etudiant SET dernier_emprunt = '2024-03-15' WHERE id = 5;
UPDATE etudiant SET dernier_emprunt = '2024-03-24' WHERE id = 6;

-- Commentaires sur les cas spécifiques insérés :
-- 1. Emprunts en retard : étudiants 3 et 4 ont rendu leurs livres en retard
-- 2. Emprunts non retournés : étudiants 1, 2, 3, 5 ont des emprunts en cours
-- 3. Étudiant avec 5 emprunts : Thomas Petit (id=6) a exactement 5 emprunts actifs
-- 4. Livre épuisé : "Harry Potter et la Chambre des secrets" a 0 exemplaire
-- 5. Tentative d'emprunt d'un livre épuisé sera testée dans les requêtes

-- Affichage des données insérées pour vérification
SELECT 'Auteurs insérés:' as info;
SELECT * FROM auteur;

SELECT 'Livres insérés:' as info;
SELECT * FROM livre;

SELECT 'Étudiants insérés:' as info;
SELECT * FROM etudiant;

SELECT 'Emprunts insérés:' as info;
SELECT * FROM emprunt; 