-- count(DISTINCT x) counts values distinct under x's collation.
CREATE TABLE visits (id INTEGER, email TEXT COLLATE NOCASE, page TEXT, ref TEXT COLLATE RTRIM);
INSERT INTO visits VALUES (1, 'a@b.c', '/x', 'g'), (2, 'A@B.C', '/X', 'g  '), (3, 'd@e.f', '/x', NULL),
  (4, 'a@b.C', '/y', 'b'), (5, NULL, '/Y', 'g ');
SELECT count(DISTINCT email), count(DISTINCT page), count(DISTINCT ref) FROM visits;
SELECT count(DISTINCT page COLLATE NOCASE), count(DISTINCT email COLLATE BINARY) FROM visits;
SELECT count(DISTINCT lower(email)) FROM visits;
