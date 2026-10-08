CREATE TABLE notes (id INTEGER PRIMARY KEY, val TEXT);
INSERT INTO notes (val) VALUES ('2.5'), (' 1.5 apples'), ('none'), (NULL), ('-0.5e1');
SELECT sum(val), typeof(sum(val)) FROM notes;
SELECT total(val), avg(val) FROM notes;
SELECT avg(val) FROM notes WHERE id <= 2;
SELECT min(val), max(val), count(val) FROM notes;
SELECT sum(val) FROM notes WHERE id = 3;
