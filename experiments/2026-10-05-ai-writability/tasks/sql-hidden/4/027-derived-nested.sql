-- A subquery source may itself join tables and contain another subquery source.
CREATE TABLE authors (aid INTEGER, name TEXT);
CREATE TABLE books (bid INTEGER, aid INTEGER, pages INTEGER);
INSERT INTO authors VALUES (1, 'Ola'), (2, 'Per'), (3, 'Siv');
INSERT INTO books VALUES (10, 1, 300), (11, 1, 120), (12, 2, 500), (13, 3, 80), (14, 3, 90), (15, 3, 100);
SELECT name, total FROM (SELECT name, sum(pages) AS total FROM authors JOIN books USING (aid) GROUP BY name) s
  ORDER BY total DESC;
SELECT max(total), min(total) FROM (SELECT aid, sum(pages) AS total FROM books GROUP BY aid);
SELECT name FROM authors JOIN (SELECT aid FROM (SELECT aid, count(*) AS n FROM books GROUP BY aid) WHERE n >= 2) t
  USING (aid) ORDER BY name;
SELECT t.name, t.cnt FROM (SELECT a.name, count(b.bid) AS cnt FROM authors a LEFT JOIN books b ON b.aid = a.aid
  AND b.pages > 100 GROUP BY a.aid) t ORDER BY t.cnt, t.name;
