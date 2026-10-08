CREATE TABLE r (v INTEGER);
INSERT INTO r VALUES (3), (NULL), (9);
SELECT count(*) FROM r WHERE v > 100 HAVING count(*) = 0;
SELECT sum(v) FROM r WHERE v > 100 HAVING sum(v) IS NULL;
SELECT max(v), min(v) FROM r HAVING max(v) - min(v) > 5;
SELECT avg(v) FROM r HAVING avg(v) > 10;
SELECT 'many', count(v) FROM r HAVING count(v) >= 2;
SELECT total(v) FROM r WHERE v IS NULL HAVING count(*) = 1;
