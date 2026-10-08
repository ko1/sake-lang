CREATE TABLE gx (k TEXT, v INTEGER);
INSERT INTO gx VALUES ('a', 1), ('a', 2), ('b', 3);
SELECT k FROM gx GROUP BY group_concat(k);
SELECT k FROM gx GROUP BY k, count(*) + 1;
SELECT k, avg(v) AS mean FROM gx GROUP BY mean;
SELECT k FROM gx GROUP BY CASE WHEN sum(v) > 1 THEN 1 END;
SELECT k, total(v) FROM gx GROUP BY k ORDER BY k;
