-- ALTER TABLE ADD COLUMN accepts COLLATE; an unknown name adds nothing.
CREATE TABLE notes (id INTEGER, body TEXT);
INSERT INTO notes VALUES (1, 'x'), (2, 'y');
ALTER TABLE notes ADD COLUMN tag TEXT COLLATE NOCASE DEFAULT 'Misc';
ALTER TABLE notes ADD COLUMN ext TEXT COLLATE Dutch;
INSERT INTO notes VALUES (3, 'z', 'TODO');
SELECT id FROM notes WHERE tag = 'MISC' ORDER BY id;
SELECT id FROM notes WHERE tag = 'todo';
SELECT * FROM notes ORDER BY id;
