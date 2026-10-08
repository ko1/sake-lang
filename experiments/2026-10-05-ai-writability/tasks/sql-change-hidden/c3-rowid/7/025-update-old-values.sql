-- SET expressions and WHERE see the rowid before the change
CREATE TABLE bk (name TEXT, prev INTEGER);
INSERT INTO bk VALUES ('u', 0), ('v', 0);
UPDATE bk SET prev = rowid, rowid = rowid * 10, name = name || oid;
SELECT rowid, name, prev FROM bk ORDER BY 1;
UPDATE bk SET rowid = 5 WHERE rowid = 20;
DELETE FROM bk WHERE oid = 10;
SELECT rowid, name, prev FROM bk;
