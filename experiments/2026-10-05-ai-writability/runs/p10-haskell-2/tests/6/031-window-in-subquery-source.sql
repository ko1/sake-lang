-- window results as a source: top row per group, through a subquery, a view and a WITH
CREATE TABLE bid (item TEXT, bidder TEXT, amount INTEGER);
INSERT INTO bid VALUES ('vase','ann',10),('vase','bo',15),('vase','cy',12),('lamp','bo',30),('lamp','dee',25),('rug','cy',8);
SELECT item, bidder, amount FROM (SELECT item, bidder, amount, row_number() OVER (PARTITION BY item ORDER BY amount DESC) AS rn FROM bid) WHERE rn = 1 ORDER BY item;
CREATE VIEW ranked AS SELECT item, bidder, rank() OVER (PARTITION BY item ORDER BY amount DESC) AS r FROM bid;
SELECT item, bidder FROM ranked WHERE r = 2 ORDER BY item;
INSERT INTO bid VALUES ('rug','ann',9);
SELECT item, bidder FROM ranked WHERE r = 1 ORDER BY item;
WITH g AS (SELECT item, amount - lag(amount) OVER (PARTITION BY item ORDER BY amount) AS step FROM bid)
SELECT item, max(step) FROM g GROUP BY item ORDER BY item;
SELECT bidder FROM bid WHERE amount IN (SELECT max(amount) OVER () FROM bid) ORDER BY bidder;
