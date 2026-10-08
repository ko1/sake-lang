-- compound selects as ctes and as the main select of a WITH
CREATE TABLE t (n INTEGER);
INSERT INTO t VALUES (1), (2), (3);
WITH both AS (SELECT n FROM t UNION ALL SELECT n * 10 FROM t) SELECT sum(n), count(*) FROM both;
WITH small AS (SELECT n FROM t WHERE n < 3), big AS (SELECT n FROM t WHERE n > 1) SELECT n FROM small INTERSECT SELECT n FROM big;
WITH c(x, y) AS (SELECT n, 'a' FROM t UNION SELECT n, 'b' FROM t WHERE n = 2) SELECT x, y FROM c ORDER BY y DESC, x;
WITH c AS (SELECT n FROM t) SELECT n FROM c EXCEPT SELECT 2 UNION SELECT 7 ORDER BY 1;
