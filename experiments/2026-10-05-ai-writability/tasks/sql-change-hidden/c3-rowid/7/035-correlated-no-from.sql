-- an unqualified rowid in a subquery without FROM is the enclosing table's
CREATE TABLE q2 (c TEXT);
INSERT INTO q2 VALUES ('h'), ('i');
SELECT c, (SELECT rowid * 100) FROM q2 ORDER BY c;
SELECT c FROM q2 WHERE (SELECT oid) = 2;
CREATE TABLE q3 (d TEXT);
INSERT INTO q3 (rowid, d) VALUES (2, 'two');
UPDATE q2 SET c = (SELECT d FROM q3 WHERE q3.rowid = q2.rowid) WHERE rowid = 2;
SELECT rowid, c FROM q2 ORDER BY rowid;
