CREATE TABLE books (title TEXT, genre TEXT, pages INTEGER);
INSERT INTO books VALUES ('a', 'sf', 300), ('b', 'crime', 250), ('c', 'sf', 120), ('d', 'poetry', 80);
SELECT genre, count(*) FROM books GROUP BY 1 ORDER BY 1;
SELECT pages / 100 AS hundreds, count(*) FROM books GROUP BY 1 ORDER BY 1;
SELECT genre, pages > 200, count(*) FROM books GROUP BY 1, 2 ORDER BY 1, 2;
SELECT count(*), genre FROM books GROUP BY 2 ORDER BY 2 DESC;
