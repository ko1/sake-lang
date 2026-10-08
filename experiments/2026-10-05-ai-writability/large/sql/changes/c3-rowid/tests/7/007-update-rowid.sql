-- UPDATE may change the rowid; SET expressions see the old one
CREATE TABLE task (title TEXT, note TEXT);
INSERT INTO task VALUES ('wash', ''), ('cook', ''), ('read', '');
UPDATE task SET rowid = 100 WHERE title = 'cook';
UPDATE task SET oid = rowid + 20, note = 'was ' || rowid WHERE title = 'read';
SELECT rowid, title, note FROM task ORDER BY rowid;
UPDATE task SET rowid = NULL WHERE title = 'wash';
UPDATE task SET _rowid_ = 'abc' WHERE title = 'wash';
INSERT INTO task (title) VALUES ('nap');
SELECT rowid, title FROM task ORDER BY rowid;
