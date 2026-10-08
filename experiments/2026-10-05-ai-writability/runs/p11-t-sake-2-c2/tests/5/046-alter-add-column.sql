-- ADD COLUMN appends a column; existing rows get its DEFAULT value or NULL
CREATE TABLE book (title TEXT);
INSERT INTO book VALUES ('Dune'), ('Emma');
ALTER TABLE book ADD COLUMN pages INTEGER;
ALTER TABLE book ADD year INTEGER DEFAULT 1900;
ALTER TABLE book ADD COLUMN genre TEXT NOT NULL DEFAULT 'misc';
ALTER TABLE book ADD COLUMN rating REAL DEFAULT 3;
SELECT * FROM book ORDER BY title;
SELECT typeof(pages), typeof(year), typeof(rating) FROM book WHERE title = 'Dune';
INSERT INTO book (title, pages) VALUES ('Ulysses', 730);
SELECT title, pages, year, genre FROM book ORDER BY title;
INSERT INTO book VALUES ('X', 1, 2, 'y', 4.5);
INSERT INTO book (title, genre) VALUES ('Y', NULL);
SELECT count(*) FROM book;
