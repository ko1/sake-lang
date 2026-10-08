-- rowid in PARTITION BY and frames
CREATE TABLE pt (g TEXT, n INTEGER);
INSERT INTO pt VALUES ('a', 1), ('b', 2), ('a', 3), ('b', 4), ('a', 5);
SELECT rowid, rank() OVER (PARTITION BY rowid % 2 ORDER BY n DESC) FROM pt ORDER BY rowid;
SELECT rowid, first_value(rowid) OVER (PARTITION BY g ORDER BY rowid ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) FROM pt ORDER BY rowid;
