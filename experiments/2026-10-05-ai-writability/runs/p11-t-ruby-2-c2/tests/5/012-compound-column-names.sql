-- a compound's column names are those of its first simple-select
CREATE TABLE t (a INTEGER, b TEXT);
INSERT INTO t VALUES (1, 'one'), (2, 'two');
SELECT num, word FROM (SELECT a AS num, b AS word FROM t UNION ALL SELECT 3 AS x, 'three' AS y) ORDER BY num;
SELECT a FROM (SELECT a, b FROM t UNION SELECT 9, 'nine') WHERE b = 'nine';
SELECT x FROM (SELECT a AS num FROM t UNION SELECT 3 AS x);
SELECT s.b FROM (SELECT a, b FROM t EXCEPT SELECT 1, 'one') AS s;
