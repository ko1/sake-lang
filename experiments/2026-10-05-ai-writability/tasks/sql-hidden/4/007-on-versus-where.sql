-- The same condition placed in ON or in WHERE of a LEFT JOIN gives different rows.
CREATE TABLE plants (id INTEGER, name TEXT);
CREATE TABLE waterings (plant INTEGER, liters REAL);
INSERT INTO plants VALUES (1, 'fern'), (2, 'rose'), (3, 'cactus'), (4, 'palm');
INSERT INTO waterings VALUES (1, 0.5), (2, 2.0), (2, 1.0), (4, 3.5);
SELECT name, liters FROM plants LEFT JOIN waterings ON plant = id AND liters >= 1.0 ORDER BY name, liters;
SELECT name, liters FROM plants LEFT JOIN waterings ON plant = id WHERE liters >= 1.0 ORDER BY name, liters;
SELECT name, count(liters) FROM plants LEFT JOIN waterings ON plant = id AND liters < 2.0 GROUP BY name ORDER BY name;
SELECT name, count(liters) FROM plants LEFT JOIN waterings ON plant = id WHERE liters < 2.0 GROUP BY name ORDER BY name;
SELECT name FROM plants LEFT JOIN waterings ON plant = id AND plant IS NULL ORDER BY name;
SELECT name FROM plants LEFT JOIN waterings ON plant = id WHERE plant IS NULL ORDER BY name;
