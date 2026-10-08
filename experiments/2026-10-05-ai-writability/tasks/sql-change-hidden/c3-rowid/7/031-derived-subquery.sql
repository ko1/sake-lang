-- a subquery that lists rowid has a column named rowid
CREATE TABLE src (w TEXT);
INSERT INTO src VALUES ('m'), ('n'), ('o');
SELECT rowid, w FROM (SELECT rowid, w FROM src WHERE w <> 'n') ORDER BY rowid;
SELECT s.rowid FROM (SELECT rowid, w FROM src) AS s WHERE s.w = 'o';
SELECT * FROM (SELECT rowid, w FROM src) ORDER BY 1 DESC;
