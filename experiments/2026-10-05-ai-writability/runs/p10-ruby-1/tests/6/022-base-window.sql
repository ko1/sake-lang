-- OVER (base ORDER BY ...) and OVER (base frame) add to a named window
CREATE TABLE acct (who TEXT, n INTEGER, amt INTEGER);
INSERT INTO acct VALUES ('a',1,100),('a',2,-30),('a',3,50),('b',1,10),('b',2,20),('b',3,-5),('b',4,40);
SELECT who, n, sum(amt) OVER (byw ORDER BY n), sum(amt) OVER (byw ORDER BY n DESC) FROM acct WINDOW byw AS (PARTITION BY who) ORDER BY who, n;
SELECT who, n, sum(amt) OVER (byw ORDER BY n ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM acct WINDOW byw AS (PARTITION BY who) ORDER BY who, n;
SELECT who, n, count(*) OVER (w2 ORDER BY amt RANGE BETWEEN 20 PRECEDING AND 20 FOLLOWING) FROM acct WINDOW w2 AS (PARTITION BY who) ORDER BY who, n;
SELECT who, n, sum(amt) OVER (w3 ORDER BY n) FROM acct WINDOW w1 AS (PARTITION BY who), w3 AS (w1) ORDER BY who, n;
