-- an ORDER BY term of a compound that is neither a column number nor a result name is an error
CREATE TABLE t (a INTEGER, b INTEGER);
CREATE TABLE u (c INTEGER, d INTEGER);
INSERT INTO t VALUES (1, 10);
INSERT INTO u VALUES (2, 20);
SELECT a FROM t UNION SELECT c FROM u ORDER BY b;
SELECT a, b FROM t UNION SELECT c, d FROM u ORDER BY a, zz;
SELECT a, b FROM t UNION ALL SELECT c, d FROM u ORDER BY 1, 2, nope;
SELECT a AS k FROM t EXCEPT SELECT c FROM u ORDER BY k;
