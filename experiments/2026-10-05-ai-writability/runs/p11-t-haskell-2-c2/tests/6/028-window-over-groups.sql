-- in an aggregate query the window works on the groups, and may use aggregates
CREATE TABLE ord (cust TEXT, region TEXT, total INTEGER);
INSERT INTO ord VALUES ('ann','n',50),('bob','s',20),('ann','n',30),('cy','s',90),('dan','n',10),('bob','s',40),('eve','w',25);
SELECT cust, sum(total), rank() OVER (ORDER BY sum(total) DESC) FROM ord GROUP BY cust ORDER BY cust;
SELECT region, count(*), sum(count(*)) OVER (ORDER BY region) FROM ord GROUP BY region ORDER BY region;
SELECT region, sum(total), sum(total) * 100 / sum(sum(total)) OVER () FROM ord GROUP BY region ORDER BY region;
SELECT cust, max(total), row_number() OVER (ORDER BY cust DESC) FROM ord GROUP BY cust HAVING count(*) > 1 ORDER BY cust;
SELECT count(*), sum(total), count(*) OVER () FROM ord WHERE total > 1000;
