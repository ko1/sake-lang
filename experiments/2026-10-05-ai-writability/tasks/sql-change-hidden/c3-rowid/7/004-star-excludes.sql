-- SELECT * lists only the real columns
CREATE TABLE pt (x INTEGER, y INTEGER);
INSERT INTO pt (rowid, x, y) VALUES (7, 1, 2), (9, 3, 4);
SELECT * FROM pt ORDER BY x;
SELECT rowid, * FROM pt ORDER BY 1;
SELECT *, oid FROM pt ORDER BY x DESC;
SELECT count(*) FROM (SELECT * FROM pt);
