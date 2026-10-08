CREATE TABLE ships (port TEXT, tons INTEGER);
INSERT INTO ships VALUES ('rio', 10), ('rio', 40), ('oslo', 5), ('kobe', 70), ('kobe', 20), ('kobe', 1);
SELECT port AS p, sum(tons) AS t FROM ships GROUP BY p HAVING t >= 50 ORDER BY t;
SELECT port, count(*) AS c, avg(tons) AS a FROM ships GROUP BY port HAVING c > 1 AND a < 30 ORDER BY port;
SELECT port, max(tons) - min(tons) AS gap FROM ships GROUP BY port HAVING gap > 0 ORDER BY gap DESC;
SELECT port FROM ships GROUP BY port HAVING nope > 1;
