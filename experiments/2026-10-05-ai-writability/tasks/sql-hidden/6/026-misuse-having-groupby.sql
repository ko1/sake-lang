CREATE TABLE s (k TEXT, v INTEGER);
INSERT INTO s VALUES ('a',1),('a',2),('b',5);
SELECT k, sum(v) FROM s GROUP BY k HAVING row_number() OVER (ORDER BY k) = 1;
SELECT k, count(*) FROM s GROUP BY k, ntile(2) OVER (ORDER BY v);
SELECT count(*) FROM s HAVING max(v) OVER () > 1;
SELECT k FROM s WHERE v > avg(v) OVER (PARTITION BY k);
SELECT k, v FROM s WHERE EXISTS (SELECT 1 FROM s AS t WHERE t.v = cume_dist() OVER ());
SELECT a.k FROM s AS a LEFT JOIN s AS b ON b.v = first_value(a.v) OVER ();
SELECT k, sum(v), row_number() OVER (ORDER BY k) FROM s GROUP BY k ORDER BY k;
