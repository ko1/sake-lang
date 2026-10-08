-- bill of materials: multiplying quantities down a recursive cte
CREATE TABLE part (parent TEXT, child TEXT, qty INTEGER);
INSERT INTO part VALUES ('bike', 'wheel', 2), ('bike', 'frame', 1), ('wheel', 'spoke', 32), ('wheel', 'rim', 1), ('frame', 'tube', 3);
WITH RECURSIVE need(item, n) AS (SELECT 'bike', 1 UNION ALL SELECT p.child, need.n * p.qty FROM part p JOIN need ON p.parent = need.item)
SELECT item, n FROM need WHERE item NOT IN (SELECT parent FROM part) ORDER BY item;
WITH RECURSIVE need(item, n) AS (SELECT 'wheel', 5 UNION ALL SELECT p.child, need.n * p.qty FROM part p JOIN need ON p.parent = need.item)
SELECT sum(n) FROM need;
WITH RECURSIVE lvl(item, d) AS (SELECT 'bike', 0 UNION ALL SELECT p.child, lvl.d + 1 FROM part p JOIN lvl ON p.parent = lvl.item)
SELECT d, count(*) FROM lvl GROUP BY d ORDER BY d;
