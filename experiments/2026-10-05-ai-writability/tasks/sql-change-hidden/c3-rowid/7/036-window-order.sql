-- rowid in a window ORDER BY and as a window argument
CREATE TABLE rd (val INTEGER);
INSERT INTO rd VALUES (5), (3), (8), (1);
SELECT rowid, val, sum(val) OVER (ORDER BY rowid) FROM rd ORDER BY rowid;
SELECT val, lag(rowid) OVER (ORDER BY val) FROM rd ORDER BY val;
SELECT val, row_number() OVER (ORDER BY oid DESC) FROM rd ORDER BY val;
