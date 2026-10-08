CREATE TABLE book (title TEXT, author TEXT, year INTEGER, pages INTEGER);
INSERT INTO book VALUES ('dune','herbert',1965,412),('emma','austen',1815,474),('it','king',1986,1138),
  ('carrie','king',1974,199),('persuasion','austen',1817,249),('misery','king',1987,320);
SELECT title, row_number() OVER (ORDER BY author DESC, year) FROM book ORDER BY title;
SELECT author, title, row_number() OVER (PARTITION BY author ORDER BY pages DESC) AS n FROM book ORDER BY author, n;
SELECT title, row_number() OVER (PARTITION BY year / 100 ORDER BY title DESC) FROM book ORDER BY year;
SELECT row_number() OVER (ORDER BY length(title), title) AS n, title FROM book WHERE pages > 300 ORDER BY n DESC;
