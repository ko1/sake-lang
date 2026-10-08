-- Scalar subqueries inside functions, CASE, GROUP BY expressions and LIMIT-ordered picks.
CREATE TABLE temps (city TEXT, deg INTEGER);
CREATE TABLE limits (name TEXT, val INTEGER);
INSERT INTO temps VALUES ('A', 12), ('B', 25), ('C', 31), ('D', 18);
INSERT INTO limits VALUES ('hot', 24), ('cold', 15);
SELECT city, CASE WHEN deg > (SELECT val FROM limits WHERE name = 'hot') THEN 'hot'
  WHEN deg < (SELECT val FROM limits WHERE name = 'cold') THEN 'cold' ELSE 'mild' END FROM temps ORDER BY city;
SELECT abs(deg - (SELECT avg(deg) FROM temps)) AS dist, city FROM temps ORDER BY dist, city;
SELECT deg > (SELECT val FROM limits WHERE name = 'hot') AS hot, count(*) FROM temps GROUP BY 1 ORDER BY 1;
SELECT coalesce((SELECT city FROM temps WHERE deg > 40), 'none'), (SELECT city FROM temps ORDER BY deg LIMIT 1 OFFSET 1);
SELECT upper((SELECT name FROM limits ORDER BY val DESC LIMIT 1)), length((SELECT group_concat(city, '') FROM temps WHERE deg > 20));
SELECT typeof((SELECT deg FROM temps WHERE city = 'Z')), (SELECT deg FROM temps WHERE city = 'Z') IS NULL;
