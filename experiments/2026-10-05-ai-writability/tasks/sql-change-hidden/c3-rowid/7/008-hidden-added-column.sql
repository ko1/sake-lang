-- a column added with a rowid name hides that name from then on
CREATE TABLE doc (title TEXT);
INSERT INTO doc VALUES ('alpha'), ('beta');
SELECT oid, title FROM doc ORDER BY oid;
ALTER TABLE doc ADD COLUMN oid TEXT DEFAULT 'none';
SELECT oid, rowid, title FROM doc ORDER BY rowid;
UPDATE doc SET oid = 'set' WHERE rowid = 2;
SELECT oid, _rowid_ FROM doc ORDER BY 2;
