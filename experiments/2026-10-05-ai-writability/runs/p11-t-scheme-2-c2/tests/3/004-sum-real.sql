CREATE TABLE m (v REAL, n INTEGER);
INSERT INTO m VALUES (1.5, 1), (2.25, 2), (NULL, 3), (4.0, 4);
SELECT sum(v), typeof(sum(v)) FROM m;
SELECT sum(n), sum(n * 0.5), typeof(sum(n * 0.5)) FROM m;
SELECT sum(CASE WHEN n = 4 THEN 0.5 ELSE n END) FROM m;
SELECT sum(v) FROM m WHERE n = 4;
