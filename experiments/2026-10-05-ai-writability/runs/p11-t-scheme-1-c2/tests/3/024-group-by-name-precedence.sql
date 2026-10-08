CREATE TABLE inv (a INTEGER, b INTEGER);
INSERT INTO inv VALUES (1, 10), (1, 10), (2, 30), (3, 40);
-- a in GROUP BY is the table's column a, not the alias
SELECT count(*) AS n, b / 100 AS a FROM inv GROUP BY a ORDER BY n, a;
-- b in HAVING is the table's column b
SELECT a AS b, count(*) FROM inv GROUP BY a HAVING b > 25 ORDER BY 1;
-- n is only an alias
SELECT a, count(*) AS n FROM inv GROUP BY a HAVING n = 1 ORDER BY a;
