CREATE TABLE cities (name TEXT, country TEXT);
INSERT INTO cities VALUES ('bern', 'CH'), ('Zurich', 'CH'), ('basel', 'CH'), ('lyon', 'FR'), ('Paris', 'FR'), ('nice', 'FR');
SELECT country, min(name), max(name) FROM cities GROUP BY country ORDER BY country;
SELECT country, min(lower(name)), max(upper(name)) FROM cities GROUP BY country ORDER BY country DESC;
SELECT min(name || country), max(length(name) || name) FROM cities;
SELECT min(name) FROM cities WHERE name > 'Z';
