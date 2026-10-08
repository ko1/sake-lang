-- a table with real columns of all three names has no visible rowid
CREATE TABLE odd (oid INTEGER, _rowid_ TEXT, rowid REAL);
INSERT INTO odd VALUES (70, 'p', 2.5), (60, 'q', 1.5);
SELECT oid, _rowid_, rowid FROM odd ORDER BY oid;
SELECT * FROM odd ORDER BY rowid DESC;
SELECT odd.oid + 1 FROM odd ORDER BY 1;
