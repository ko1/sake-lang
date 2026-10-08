CREATE TABLE c (k TEXT, n INTEGER, f REAL);
INSERT INTO c VALUES ('a', 1, 0.5), ('b', NULL, 1.5), ('c', 3, NULL);
UPDATE c SET n = coalesce(n, 0) + 1;
SELECT k, n FROM c ORDER BY k;
UPDATE c SET f = n / 2;
SELECT k, f, typeof(f) FROM c ORDER BY k;
UPDATE c SET k = upper(k);
SELECT k FROM c ORDER BY k DESC;
