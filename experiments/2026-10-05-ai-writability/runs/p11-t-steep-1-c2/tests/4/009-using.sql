CREATE TABLE cities (code TEXT, city TEXT);
CREATE TABLE temps (code TEXT, temp REAL);
INSERT INTO cities VALUES ('NYC', 'New York'), ('LAX', 'Los Angeles'), ('SEA', 'Seattle');
INSERT INTO temps VALUES ('NYC', 21.5), ('SEA', 14.0), ('NYC', 19.0), ('BOS', 17.5);
SELECT code, city, temp FROM cities JOIN temps USING (code) ORDER BY code, temp;
SELECT city, avg(temp) FROM cities JOIN temps USING (code) GROUP BY city ORDER BY city;
SELECT code, temp FROM cities INNER JOIN temps USING (code) WHERE temp > 15 ORDER BY temp;
