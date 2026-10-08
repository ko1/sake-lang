CREATE TABLE run (who TEXT, wk INTEGER, km INTEGER);
INSERT INTO run VALUES ('jo',1,5),('jo',2,8),('jo',3,6),('jo',4,10),('al',1,3),('al',2,3),('al',3,12);
SELECT who, wk, sum(km) OVER cum, max(km) OVER part, lead(km) OVER cum FROM run
  WINDOW part AS (PARTITION BY who), cum AS (part ORDER BY wk) ORDER BY who, wk;
SELECT who, wk, avg(km) OVER mov FROM run WINDOW base AS (PARTITION BY who), byweek AS (base ORDER BY wk), mov AS (byweek ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) ORDER BY who, wk;
SELECT who, wk, rank() OVER W1, dense_rank() OVER w1 FROM run WINDOW W1 AS (ORDER BY km DESC) ORDER BY who, wk;
SELECT wk, count(*) OVER a, count(*) OVER b FROM run WHERE who = 'jo' WINDOW a AS (ORDER BY wk), b AS (ORDER BY wk DESC) ORDER BY wk;
SELECT who, sum(km), rank() OVER w FROM run GROUP BY who HAVING sum(km) > 0 WINDOW w AS (ORDER BY sum(km)) ORDER BY who;
