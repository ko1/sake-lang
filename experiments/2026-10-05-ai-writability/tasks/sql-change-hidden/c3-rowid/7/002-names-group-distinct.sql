-- rowid in GROUP BY, HAVING, DISTINCT and arithmetic
CREATE TABLE sale (region TEXT, amt INTEGER);
INSERT INTO sale VALUES ('n', 5), ('s', 8), ('n', 2), ('s', 1), ('e', 9);
SELECT rowid % 2, count(*), sum(amt) FROM sale GROUP BY rowid % 2 ORDER BY 1;
SELECT region, group_concat(rowid, '-' ORDER BY rowid) FROM sale GROUP BY region HAVING max(rowid) > 3 ORDER BY region;
SELECT DISTINCT rowid / 2 FROM sale ORDER BY 1;
SELECT avg(oid), total(_rowid_) FROM sale;
