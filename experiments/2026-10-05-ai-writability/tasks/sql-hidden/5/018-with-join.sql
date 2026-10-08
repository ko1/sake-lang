-- ctes joined with tables and with each other
CREATE TABLE city (id INTEGER, name TEXT, country TEXT);
CREATE TABLE trip (city_id INTEGER, nights INTEGER);
INSERT INTO city VALUES (1, 'paris', 'fr'), (2, 'lyon', 'fr'), (3, 'rome', 'it');
INSERT INTO trip VALUES (1, 3), (3, 2), (1, 1), (2, 4);
WITH nights AS (SELECT city_id, sum(nights) AS n FROM trip GROUP BY city_id) SELECT c.name, x.n FROM city c JOIN nights x ON x.city_id = c.id ORDER BY x.n DESC, c.name;
WITH nights AS (SELECT city_id, sum(nights) AS n FROM trip GROUP BY city_id), bycountry AS (SELECT c.country, sum(x.n) AS total FROM city c LEFT JOIN nights x ON x.city_id = c.id GROUP BY c.country) SELECT country, total FROM bycountry ORDER BY country;
WITH fr AS (SELECT id FROM city WHERE country = 'fr') SELECT count(*) FROM trip t JOIN fr USING (id);
WITH fr(city_id) AS (SELECT id FROM city WHERE country = 'fr') SELECT sum(nights) FROM trip JOIN fr USING (city_id);
