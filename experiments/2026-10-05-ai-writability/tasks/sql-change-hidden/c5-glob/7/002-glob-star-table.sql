CREATE TABLE cities (name TEXT, country TEXT);
INSERT INTO cities VALUES ('Paris', 'FR'), ('Porto', 'PT'), ('Perth', 'AU'), ('paris', 'US'), ('Lisbon', 'PT'), ('Pisa', 'IT');
SELECT name, country FROM cities WHERE name GLOB 'P*' ORDER BY name;
SELECT name FROM cities WHERE name GLOB '*s*' ORDER BY name;
SELECT country FROM cities WHERE name GLOB 'paris' ORDER BY country;
SELECT count(*) FROM cities WHERE name GLOB '*o*' AND country GLOB 'P*';
