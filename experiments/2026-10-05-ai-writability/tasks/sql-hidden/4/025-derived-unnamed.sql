-- Unnamed subquery sources, alone and in products.
CREATE TABLE v (n INTEGER);
INSERT INTO v VALUES (2), (5), (8);
SELECT lo, hi FROM (SELECT min(n) AS lo FROM v), (SELECT max(n) AS hi FROM v);
SELECT n, n - lo FROM v, (SELECT min(n) AS lo FROM v) ORDER BY n;
SELECT * FROM (SELECT n * 10 AS t FROM v WHERE n > 2), (SELECT 'z' AS tag) ORDER BY t DESC;
SELECT count(*), sum(k) FROM (SELECT n AS k FROM v), (SELECT 1 AS one);
SELECT avg(n) FROM (SELECT n FROM v WHERE n < 6);
