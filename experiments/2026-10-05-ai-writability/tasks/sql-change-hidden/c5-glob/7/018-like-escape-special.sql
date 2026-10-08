-- _ or % as the escape character loses its wildcard meaning
SELECT 'x_' LIKE 'x__' ESCAPE '_', 'xy' LIKE 'x__' ESCAPE '_', 'xy' LIKE 'x_y' ESCAPE '_', 'x' LIKE 'x_' ESCAPE '_';
SELECT '%' LIKE '%%' ESCAPE '%', 'abc' LIKE '%' ESCAPE '%', 'abc' LIKE 'abc' ESCAPE '%';
-- a trailing escape character matches nothing; NULL gives NULL
SELECT 'ab' LIKE 'ab#' ESCAPE '#', 'ab#' LIKE 'ab#' ESCAPE '#', '' LIKE '#' ESCAPE '#';
SELECT 'ab' LIKE 'ab' ESCAPE NULL, 'ab' NOT LIKE 'ab#' ESCAPE NULL, NULL NOT LIKE '%' ESCAPE '#';
CREATE TABLE e (id INTEGER PRIMARY KEY, txt TEXT, esc TEXT);
INSERT INTO e (txt, esc) VALUES ('a*b', '*'), ('a*b', '!'), (NULL, '*'), ('a!b', '!');
SELECT id, txt LIKE 'a**b' ESCAPE esc, txt LIKE 'a!!b' ESCAPE esc FROM e ORDER BY id;
