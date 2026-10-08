-- BETWEEN chooses a collation separately for its lower and its upper comparison.
CREATE TABLE names (id INTEGER, ci TEXT COLLATE NOCASE, cs TEXT);
INSERT INTO names VALUES (1, 'Bea', 'Bea'), (2, 'carl', 'carl'), (3, 'DAN', 'DAN'), (4, 'abe', 'abe');
SELECT id FROM names WHERE ci BETWEEN 'b' AND 'D' ORDER BY id;
SELECT id FROM names WHERE cs BETWEEN 'b' AND 'D' ORDER BY id;
SELECT id FROM names WHERE cs BETWEEN 'b' COLLATE NOCASE AND 'd' ORDER BY id;
SELECT id FROM names WHERE cs BETWEEN 'B' AND 'd' COLLATE NOCASE ORDER BY id;
SELECT id FROM names WHERE ci NOT BETWEEN 'B' AND 'CZ' ORDER BY id;
