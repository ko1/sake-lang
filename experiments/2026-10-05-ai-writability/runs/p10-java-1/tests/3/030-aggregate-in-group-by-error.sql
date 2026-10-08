CREATE TABLE gb (k INTEGER, v INTEGER);
INSERT INTO gb VALUES (1, 5), (1, 6), (2, 7);
SELECT k FROM gb GROUP BY count(*);
SELECT k, sum(v) FROM gb GROUP BY k, max(v);
SELECT sum(v) AS s FROM gb GROUP BY s;
SELECT k, sum(v) FROM gb GROUP BY k ORDER BY k;
