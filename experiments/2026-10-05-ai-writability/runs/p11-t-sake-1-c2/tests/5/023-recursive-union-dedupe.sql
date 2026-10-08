-- with UNION, a row already put in the queue is not put in again, so this terminates
WITH RECURSIVE cyc(n) AS (SELECT 1 UNION SELECT n % 4 + 1 FROM cyc) SELECT group_concat(n, ' ') FROM cyc;
WITH RECURSIVE r(x) AS (SELECT 0 UNION SELECT (x + 3) % 7 FROM r) SELECT group_concat(x, ',') FROM r;
WITH RECURSIVE r(a, b) AS (SELECT 1, 'x' UNION SELECT 1, 'x' FROM r) SELECT count(*) FROM r;
