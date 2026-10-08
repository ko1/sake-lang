-- views used in joins, IN, EXISTS and as part of a compound select
CREATE TABLE film (id INTEGER, title TEXT, year INTEGER);
CREATE TABLE rating (film_id INTEGER, stars INTEGER);
INSERT INTO film VALUES (1, 'alpha', 1999), (2, 'beta', 2005), (3, 'gamma', 2010), (4, 'delta', 2020);
INSERT INTO rating VALUES (1, 5), (1, 3), (2, 2), (3, 4), (3, 5);
CREATE VIEW avg_rating AS SELECT film_id, avg(stars) AS a FROM rating GROUP BY film_id;
CREATE VIEW recent AS SELECT id, title FROM film WHERE year >= 2005;
SELECT r.title, a.a FROM recent r JOIN avg_rating a ON a.film_id = r.id ORDER BY r.title;
SELECT title FROM recent WHERE id IN (SELECT film_id FROM avg_rating WHERE a >= 4);
SELECT f.title FROM film f WHERE NOT EXISTS (SELECT 1 FROM avg_rating a WHERE a.film_id = f.id) ORDER BY f.title;
SELECT title FROM recent UNION SELECT f.title FROM film f JOIN avg_rating a ON a.film_id = f.id WHERE a.a > 4 ORDER BY title;
SELECT f.title, a.a FROM film f LEFT JOIN avg_rating a ON a.film_id = f.id ORDER BY a.a DESC, f.title;
