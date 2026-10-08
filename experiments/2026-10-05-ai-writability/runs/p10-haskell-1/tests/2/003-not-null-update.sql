CREATE TABLE notes (id INTEGER, body TEXT NOT NULL);
INSERT INTO notes VALUES (1, 'first'), (2, 'second'), (3, 'third');
UPDATE notes SET body = NULL WHERE id = 2;
SELECT * FROM notes ORDER BY id;
UPDATE notes SET body = upper(body) WHERE id >= 2;
UPDATE notes SET body = nullif(body, 'first');
SELECT * FROM notes ORDER BY id;
UPDATE notes SET id = NULL WHERE id = 3;
SELECT id, body FROM notes ORDER BY body;
