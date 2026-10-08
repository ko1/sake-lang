CREATE TABLE amounts (id INTEGER, amt REAL, qty INTEGER);
INSERT INTO amounts VALUES (1, 2.0, 2), (2, 2.5, 2), (3, 3.0, 3), (4, 2.0, NULL);
SELECT count(*) FROM amounts GROUP BY CASE WHEN id < 3 THEN qty ELSE amt END ORDER BY 1;
SELECT amt, count(*) FROM amounts GROUP BY amt ORDER BY amt;
SELECT qty, count(*), sum(amt) FROM amounts GROUP BY qty ORDER BY qty DESC NULLS LAST;
SELECT count(*) FROM amounts WHERE amt = qty;
