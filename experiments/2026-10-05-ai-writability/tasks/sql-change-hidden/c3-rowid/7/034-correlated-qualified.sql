-- a correlated subquery may use the outer table's rowid
CREATE TABLE q1 (v INTEGER);
INSERT INTO q1 VALUES (10), (20), (30), (40);
SELECT v, (SELECT count(*) FROM q1 AS i WHERE i.rowid < q1.rowid) FROM q1 ORDER BY v;
SELECT v FROM q1 AS o WHERE EXISTS (SELECT 1 FROM q1 AS i WHERE i.rowid = o.rowid + 1 AND i.v > o.v) ORDER BY v;
SELECT v FROM q1 WHERE rowid = (SELECT max(rowid) FROM q1);
