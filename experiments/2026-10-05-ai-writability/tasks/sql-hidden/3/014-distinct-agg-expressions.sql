CREATE TABLE xs (x INTEGER);
INSERT INTO xs VALUES (1), (4), (7), (10), (2), (5);
SELECT sum(DISTINCT x % 3), count(DISTINCT x % 3), avg(DISTINCT x % 3) FROM xs;
SELECT sum(DISTINCT x > 4), max(DISTINCT x / 3) FROM xs;
SELECT x % 2 AS parity, sum(DISTINCT x % 3) FROM xs GROUP BY parity ORDER BY parity;
SELECT total(DISTINCT x * 0.5) FROM xs WHERE x < 5;
