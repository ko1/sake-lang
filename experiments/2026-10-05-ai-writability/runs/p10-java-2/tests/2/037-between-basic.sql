CREATE TABLE temps (city TEXT, deg REAL);
INSERT INTO temps VALUES ('oslo', -3.5), ('rome', 18.0), ('lima', 22.4), ('cairo', 30.0), ('nome', NULL);
SELECT city FROM temps WHERE deg BETWEEN 0 AND 25 ORDER BY city;
SELECT city FROM temps WHERE deg NOT BETWEEN 0 AND 25 ORDER BY city;
SELECT city, deg BETWEEN 18 AND 30 FROM temps ORDER BY city;
SELECT 5 BETWEEN 5 AND 5, 5 BETWEEN 6 AND 4, 'm' BETWEEN 'a' AND 'z', 'M' BETWEEN 'a' AND 'z';
