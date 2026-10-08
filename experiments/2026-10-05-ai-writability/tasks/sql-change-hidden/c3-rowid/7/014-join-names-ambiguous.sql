-- an unqualified rowid name with two or more sources is ambiguous
CREATE TABLE l (a INTEGER);
CREATE TABLE m (b INTEGER);
INSERT INTO l VALUES (1);
INSERT INTO m VALUES (2);
SELECT rowid FROM l, m;
SELECT a, b FROM l JOIN m ON _rowid_ = 1;
SELECT a FROM l, (SELECT 5 AS z) WHERE oid = 1;
SELECT l.rowid, m.rowid FROM l, m;
