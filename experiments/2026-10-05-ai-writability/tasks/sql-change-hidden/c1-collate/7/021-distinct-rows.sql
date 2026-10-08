-- SELECT DISTINCT under the collation of each result column.
CREATE TABLE cities (id INTEGER, name TEXT COLLATE NOCASE, cc TEXT, zip TEXT COLLATE RTRIM);
INSERT INTO cities VALUES (1, 'Paris', 'FR', '75'), (2, 'PARIS', 'fr', '75 '), (3, 'paris', 'FR', '75'),
  (4, 'Lyon', 'FR', '69'), (5, 'LYON', 'FR', '69  ');
SELECT count(*) FROM (SELECT DISTINCT name FROM cities);
SELECT count(*) FROM (SELECT DISTINCT name, cc FROM cities);
SELECT count(*) FROM (SELECT DISTINCT cc COLLATE NOCASE, zip FROM cities);
SELECT count(*) FROM (SELECT DISTINCT name || '' FROM cities);
SELECT DISTINCT upper(name), length(zip) FROM cities ORDER BY 1, 2;
