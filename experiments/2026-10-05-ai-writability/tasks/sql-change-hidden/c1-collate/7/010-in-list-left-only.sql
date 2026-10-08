-- x IN (list) compares under x's collation only.
CREATE TABLE c (id INTEGER, k TEXT COLLATE NOCASE, s TEXT);
INSERT INTO c VALUES (1, 'Red', 'Red'), (2, 'GREEN', 'green'), (3, 'blue', 'BLUE');
SELECT id FROM c WHERE k IN ('red', 'blue') ORDER BY id;
SELECT id FROM c WHERE s IN ('red', 'blue') ORDER BY id;
SELECT id FROM c WHERE s COLLATE NOCASE IN ('red', 'blue') ORDER BY id;
SELECT id FROM c WHERE 'RED' IN (k, s) ORDER BY id;
SELECT id FROM c WHERE s IN (k) ORDER BY id;
SELECT id FROM c WHERE k IN (s) ORDER BY id;
SELECT id FROM c WHERE k NOT IN ('GREEN', 'x') ORDER BY id;
