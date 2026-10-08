-- several ctes, each building on the previous ones
CREATE TABLE reading (sensor TEXT, val INTEGER);
INSERT INTO reading VALUES ('s1', 4), ('s1', 8), ('s2', 1), ('s2', 3), ('s3', 10);
WITH avgs AS (SELECT sensor, avg(val) AS a FROM reading GROUP BY sensor),
     hi AS (SELECT sensor FROM avgs WHERE a > 4),
     hicount AS (SELECT count(*) AS c FROM hi)
SELECT c FROM hicount;
WITH avgs AS (SELECT sensor, avg(val) AS a FROM reading GROUP BY sensor), mx AS (SELECT max(a) AS m FROM avgs) SELECT sensor FROM avgs, mx WHERE a = m;
WITH r AS (SELECT sensor, val FROM reading WHERE val > 2) SELECT sensor, count(*) FROM r GROUP BY sensor ORDER BY sensor;
WITH a1 AS (SELECT 1 AS v), a2 AS (SELECT v + 1 AS v FROM a1), a3 AS (SELECT v * 10 AS v FROM a2) SELECT v FROM a1 UNION ALL SELECT v FROM a2 UNION ALL SELECT v FROM a3 ORDER BY v;
