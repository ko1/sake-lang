CREATE TABLE sales (rep TEXT, region TEXT, amount INTEGER);
INSERT INTO sales VALUES ('al', 'n', 100), ('al', 's', 50), ('bea', 'n', 300), ('cal', 's', 20), ('cal', 's', 30), ('dee', 'e', 75);
SELECT rep FROM sales GROUP BY rep HAVING sum(amount) BETWEEN 50 AND 160 ORDER BY rep;
SELECT rep FROM sales GROUP BY rep HAVING count(*) IN (2, 3) AND rep LIKE '%a%' ORDER BY rep;
SELECT region, sum(amount) FROM sales GROUP BY region HAVING NOT sum(amount) > 100 OR region = 'n' ORDER BY region;
SELECT rep, max(amount) FROM sales GROUP BY rep HAVING max(amount) = min(amount) ORDER BY rep;
SELECT region FROM sales GROUP BY region HAVING group_concat(rep, '' ORDER BY rep) LIKE '%cal%' ORDER BY region;
SELECT rep FROM sales WHERE amount > 40 GROUP BY rep HAVING count(*) = 1 ORDER BY rep DESC;
