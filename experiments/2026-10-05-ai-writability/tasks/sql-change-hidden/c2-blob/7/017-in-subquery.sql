CREATE TABLE allowed (h BLOB);
CREATE TABLE seen (id INTEGER, h BLOB);
INSERT INTO allowed VALUES (X'A1'), (X'B2');
INSERT INTO seen VALUES (1, X'A1'), (2, X'C3'), (3, X'B2'), (4, NULL);
SELECT id FROM seen WHERE h IN (SELECT h FROM allowed) ORDER BY id;
SELECT id FROM seen WHERE h NOT IN (SELECT h FROM allowed) ORDER BY id;
SELECT 'A1' IN (SELECT h FROM allowed), X'a1' IN (SELECT h FROM allowed);
