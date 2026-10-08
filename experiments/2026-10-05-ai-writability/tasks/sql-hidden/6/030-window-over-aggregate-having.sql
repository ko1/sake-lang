CREATE TABLE tx (shop TEXT, day INTEGER, amt INTEGER);
INSERT INTO tx VALUES ('a',1,10),('a',1,15),('a',2,5),('b',1,40),('b',3,2),('b',3,3),('c',2,30),('c',2,1),('d',4,6);
SELECT shop, sum(amt), sum(amt) - lag(sum(amt)) OVER (ORDER BY shop) FROM tx GROUP BY shop ORDER BY shop;
SELECT shop, count(*), dense_rank() OVER (ORDER BY count(*) DESC) FROM tx GROUP BY shop HAVING count(*) >= 2 ORDER BY shop;
SELECT day, sum(amt), avg(sum(amt)) OVER (ORDER BY day ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM tx GROUP BY day ORDER BY day;
SELECT shop, day, sum(amt), sum(sum(amt)) OVER (PARTITION BY shop ORDER BY day) FROM tx GROUP BY shop, day ORDER BY shop, day;
SELECT sum(amt), count(*), row_number() OVER (), max(count(*)) OVER () FROM tx;
SELECT shop, max(amt), first_value(shop) OVER (ORDER BY max(amt) DESC), cume_dist() OVER (ORDER BY min(amt)) FROM tx GROUP BY shop ORDER BY shop;
