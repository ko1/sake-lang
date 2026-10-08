CREATE TABLE sh (x INTEGER, y TEXT);
INSERT INTO sh VALUES (1, 'p'), (2, 'p'), (3, 'q'), (4, 'q'), (5, 'q');
-- y in GROUP BY is the table column, although a result column is named y
SELECT count(*) AS cnt, upper(y) AS y FROM sh GROUP BY y ORDER BY cnt;
SELECT length(y) AS y, count(*) FROM sh GROUP BY y ORDER BY 2;
-- in HAVING, x is the table column; the alias z is found because no column is named z
SELECT y, sum(x) AS z FROM sh GROUP BY y HAVING z > 5 ORDER BY y;
SELECT y AS x, count(*) FROM sh GROUP BY y HAVING max(x) < 3 ORDER BY 1;
-- in ORDER BY, the alias comes first
SELECT y, count(*) AS x FROM sh GROUP BY y ORDER BY x DESC;
