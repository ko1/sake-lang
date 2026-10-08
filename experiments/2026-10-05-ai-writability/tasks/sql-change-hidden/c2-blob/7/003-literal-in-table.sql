CREATE TABLE keys (id INTEGER, k BLOB);
INSERT INTO keys VALUES (1, X'00ff00ff'), (2, x'c0ffee'), (3, X'');
SELECT id, k FROM keys ORDER BY id;
INSERT INTO keys VALUES (4, X'abc');
SELECT count(*) FROM keys;
