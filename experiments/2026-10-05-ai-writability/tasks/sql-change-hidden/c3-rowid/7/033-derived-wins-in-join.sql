-- the derived source's rowid column wins over a joined table's rowid
CREATE TABLE base (k TEXT);
CREATE TABLE other (k TEXT);
INSERT INTO base VALUES ('a'), ('b');
INSERT INTO other (rowid, k) VALUES (30, 'a'), (40, 'b');
SELECT rowid, other.rowid FROM (SELECT rowid, k FROM base) AS d JOIN other USING (k) ORDER BY 1;
