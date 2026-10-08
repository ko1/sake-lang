-- Aggregate min and max pick the extreme under the argument's collation.
CREATE TABLE w (id INTEGER, ci TEXT COLLATE NOCASE, cs TEXT);
INSERT INTO w VALUES (1, 'delta', 'delta'), (2, 'Echo', 'Echo'), (3, 'alpha', 'alpha'), (4, 'Bravo', 'Bravo'), (5, '_z', '_z');
SELECT min(ci), max(ci), min(cs), max(cs) FROM w;
SELECT min(cs COLLATE NOCASE), max(cs COLLATE NOCASE), max(ci COLLATE BINARY) FROM w;
SELECT max(ci) FROM w WHERE id < 5;
SELECT id, ci FROM w WHERE ci = (SELECT max(ci) FROM w);
