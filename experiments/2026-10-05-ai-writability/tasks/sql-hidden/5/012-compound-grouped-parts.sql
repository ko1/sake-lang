-- simple-selects with WHERE, GROUP BY, HAVING and DISTINCT inside a compound
CREATE TABLE sale (rep TEXT, region TEXT, amt INTEGER);
INSERT INTO sale VALUES ('ann', 'n', 10), ('ann', 's', 30), ('bob', 'n', 25), ('bob', 'n', 5), ('cy', 's', 50);
SELECT rep, sum(amt) FROM sale GROUP BY rep HAVING sum(amt) > 30 UNION SELECT region, sum(amt) FROM sale GROUP BY region ORDER BY 1;
SELECT DISTINCT region FROM sale UNION ALL SELECT DISTINCT rep FROM sale WHERE amt > 20 ORDER BY 1;
SELECT rep FROM sale WHERE region = 'n' INTERSECT SELECT rep FROM sale GROUP BY rep HAVING count(*) > 1;
SELECT max(amt) FROM sale UNION SELECT min(amt) FROM sale UNION SELECT avg(amt) FROM sale ORDER BY 1;
SELECT region, count(*) AS n FROM sale GROUP BY region EXCEPT SELECT 'n', 3 ORDER BY n;
