-- RENAME TO, ADD COLUMN and RENAME COLUMN keep rowids
CREATE TABLE old (n TEXT);
INSERT INTO old (rowid, n) VALUES (4, 'a'), (9, 'b');
ALTER TABLE old RENAME TO fresh;
ALTER TABLE fresh ADD COLUMN m INTEGER DEFAULT 7;
ALTER TABLE fresh RENAME COLUMN n TO nn;
SELECT rowid, nn, m FROM fresh ORDER BY rowid;
INSERT INTO fresh (nn) VALUES ('c');
SELECT rowid, nn, m FROM fresh ORDER BY rowid;
SELECT rowid FROM old;
