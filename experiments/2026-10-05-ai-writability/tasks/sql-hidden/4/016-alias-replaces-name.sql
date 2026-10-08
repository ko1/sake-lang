-- Once aliased, a table's own name no longer names it.
CREATE TABLE notes (id INTEGER, body TEXT);
CREATE TABLE marks (note_id INTEGER, mark TEXT);
INSERT INTO notes VALUES (1, 'buy milk'), (2, 'call mom');
INSERT INTO marks VALUES (1, 'done');
SELECT n.body, m.mark FROM notes n LEFT JOIN marks m ON m.note_id = n.id ORDER BY n.id;
SELECT n.body FROM notes n LEFT JOIN marks m ON marks.note_id = n.id;
SELECT notes.id FROM notes n GROUP BY n.id;
SELECT n.id FROM notes n ORDER BY n.id LIMIT 1;
SELECT marks.* FROM notes, marks m;
SELECT body FROM notes n WHERE EXISTS (SELECT 1 FROM marks WHERE note_id = notes.id);
SELECT body FROM notes n WHERE EXISTS (SELECT 1 FROM marks WHERE note_id = n.id);
SELECT body FROM notes WHERE id IN (SELECT notes.id FROM notes WHERE id > 1);
