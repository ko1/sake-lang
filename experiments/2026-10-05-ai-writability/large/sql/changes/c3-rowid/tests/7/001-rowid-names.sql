-- rowid, _rowid_ and oid read the same INTEGER key of each row, in any case
CREATE TABLE fruit (name TEXT, qty INTEGER);
INSERT INTO fruit VALUES ('apple', 4), ('pear', 7), ('fig', 2);
SELECT rowid, _rowid_, oid, name FROM fruit ORDER BY rowid;
SELECT ROWID, Oid, "rowid", name FROM fruit ORDER BY 1 DESC;
SELECT name, typeof(rowid) FROM fruit WHERE oid = 2;
