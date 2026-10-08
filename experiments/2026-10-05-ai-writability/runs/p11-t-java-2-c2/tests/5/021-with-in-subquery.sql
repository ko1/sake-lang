-- WITH may start a select used as a subquery
CREATE TABLE t (k INTEGER);
INSERT INTO t VALUES (1), (2), (3), (4);
SELECT k FROM t WHERE k IN (WITH ev AS (SELECT k FROM t WHERE k % 2 = 0) SELECT k FROM ev) ORDER BY k;
SELECT (WITH m AS (SELECT max(k) AS v FROM t) SELECT v * 100 FROM m);
SELECT z FROM (WITH c AS (SELECT k + 10 AS z FROM t) SELECT z FROM c WHERE z > 12) ORDER BY z DESC;
