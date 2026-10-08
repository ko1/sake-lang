-- ORDER BY sorts under a column's collation or a COLLATE on the term; ties fall to the next term.
CREATE TABLE books (id INTEGER, title TEXT COLLATE NOCASE, isbn TEXT, shelf TEXT COLLATE RTRIM);
INSERT INTO books VALUES (1, 'zen', 'b9', 'a  '), (2, 'Art', 'B1', 'a'), (3, 'art', 'a5', 'a!'),
  (4, 'Moby', '_c', 'A'), (5, '[draft]', 'b2', ' a');
SELECT id FROM books ORDER BY title, id;
SELECT id FROM books ORDER BY title DESC, id DESC;
SELECT id FROM books ORDER BY isbn, id;
SELECT id FROM books ORDER BY isbn COLLATE NOCASE, id;
SELECT id FROM books ORDER BY shelf, id;
SELECT id FROM books ORDER BY shelf COLLATE BINARY, id;
