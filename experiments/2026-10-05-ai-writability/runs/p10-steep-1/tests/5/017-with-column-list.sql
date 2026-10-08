-- a cte's column list names its columns
CREATE TABLE t (a INTEGER, b TEXT);
INSERT INTO t VALUES (1, 'u'), (2, 'v');
WITH c(n, label) AS (SELECT a, b FROM t) SELECT label, n FROM c ORDER BY n;
WITH c(n) AS (SELECT a * 10 FROM t) SELECT sum(n) FROM c;
WITH c(n) AS (SELECT a FROM t) SELECT a FROM c;
WITH c AS (SELECT a, b AS bee FROM t) SELECT a, bee FROM c ORDER BY a DESC;
