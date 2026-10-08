CREATE TABLE purchases (buyer TEXT, price INTEGER);
INSERT INTO purchases VALUES ('ann', 10), ('bob', 5), ('ann', 20), ('cy', 50), ('bob', 1), ('bob', 2);
SELECT buyer, sum(price) FROM purchases GROUP BY buyer HAVING sum(price) > 10 ORDER BY buyer;
SELECT buyer, count(*) FROM purchases GROUP BY buyer HAVING count(*) >= 2 ORDER BY buyer;
SELECT buyer FROM purchases GROUP BY buyer HAVING max(price) < 10 ORDER BY buyer;
SELECT buyer FROM purchases GROUP BY buyer HAVING buyer <> 'cy' AND min(price) > 1 ORDER BY buyer;
SELECT buyer FROM purchases GROUP BY buyer HAVING NULL ORDER BY buyer;
