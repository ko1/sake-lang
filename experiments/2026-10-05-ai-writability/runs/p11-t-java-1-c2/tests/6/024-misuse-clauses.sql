-- window calls are allowed only in result columns and ORDER BY
CREATE TABLE t (a INTEGER, g TEXT);
INSERT INTO t VALUES (1,'x'),(2,'x'),(3,'y');
SELECT a FROM t WHERE row_number() OVER (ORDER BY a) > 1;
SELECT g, count(*) FROM t GROUP BY rank() OVER (ORDER BY a);
SELECT g, count(*) FROM t GROUP BY g HAVING sum(a) OVER () > 2;
SELECT t.a FROM t JOIN t AS u ON u.a = lead(t.a) OVER (ORDER BY t.a);
SELECT a FROM t WHERE a > (SELECT max(a) FROM t) - dense_rank() OVER (ORDER BY a);
SELECT a, row_number() OVER (ORDER BY a) FROM t ORDER BY a;
