CREATE TABLE q (v INTEGER);
INSERT INTO q VALUES (4), (8);
SELECT count(*) FROM q HAVING count(*) > 1;
SELECT count(*) FROM q HAVING count(*) > 2;
SELECT sum(v) FROM q HAVING sum(v) = 12;
SELECT count(*) FROM q WHERE v > 100 HAVING count(*) = 0;
