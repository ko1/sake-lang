-- A left row with several matches gives several rows; one with none gives exactly one.
CREATE TABLE authors (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE books (title TEXT, author_id INTEGER);
INSERT INTO authors (name) VALUES ('Austen'), ('Borges'), ('Calvino');
INSERT INTO books VALUES ('Emma', 1), ('Persuasion', 1), ('Ficciones', 2), ('Aleph', 2), ('Labyrinths', 2);
SELECT name, title FROM authors LEFT JOIN books ON author_id = id ORDER BY name, title;
SELECT name, count(title) FROM authors LEFT JOIN books ON author_id = id GROUP BY name ORDER BY name;
SELECT name, count(*) FROM authors LEFT JOIN books ON author_id = id GROUP BY name ORDER BY name;
