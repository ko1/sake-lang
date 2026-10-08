CREATE TABLE e (id INTEGER, sig BLOB);
INSERT INTO e VALUES (1, X'AA'), (2, X'aa'), (3, X'AA00'), (4, NULL), (5, X'AA'), (6, NULL);
SELECT sig, count(*) FROM e GROUP BY sig ORDER BY sig;
SELECT DISTINCT sig FROM e ORDER BY sig DESC;
SELECT count(DISTINCT sig), count(sig) FROM e;
