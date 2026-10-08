CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT NOT NULL, isbn TEXT, price REAL);
CREATE TABLE sales (book_id INTEGER, qty INTEGER);
INSERT INTO books (title, isbn, price) VALUES
  ('SQL in 10 Minutes', '978-0672336072', 25.5), ('sql_tricks', '978-1234', 10),
  ('Learning Ruby', '0-596-52986-4', 30), ('100% Python', NULL, 15), ('Ruby_Cookbook', '978-0596523695', 40);
INSERT INTO sales VALUES (1, 3), (2, 1), (3, 2), (4, 5), (5, 1), (1, 2);
SELECT b.title, sum(s.qty) FROM books b JOIN sales s ON s.book_id = b.id
  WHERE b.isbn GLOB '978-*' GROUP BY b.id ORDER BY b.title;
SELECT title,
  CASE WHEN title GLOB '[A-Z]*' THEN 'Capital' WHEN title GLOB '[0-9]*' THEN 'Number' ELSE 'other' END
  FROM books ORDER BY id;
SELECT title FROM books WHERE title LIKE '%!_%' ESCAPE '!' ORDER BY title;
SELECT title FROM books WHERE title LIKE '%$%%' ESCAPE '$' OR isbn NOT GLOB '978*' ORDER BY title;
SELECT CASE WHEN isbn GLOB '978-*' THEN 'new' ELSE 'old' END AS kind, count(*), sum(price)
  FROM books GROUP BY kind HAVING count(*) > 1 ORDER BY kind;
