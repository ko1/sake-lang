CREATE TABLE trips (driver TEXT, city TEXT, km INTEGER);
INSERT INTO trips VALUES ('x', 'oslo', 10), ('x', 'oslo', 5), ('x', 'rome', 7), ('y', 'oslo', 3), ('y', 'rome', 4), ('y', 'rome', 6);
SELECT driver, city, count(*), sum(km) FROM trips GROUP BY driver, city ORDER BY driver, city;
SELECT city, driver, max(km) FROM trips GROUP BY city, driver ORDER BY city DESC, driver DESC;
SELECT count(*) FROM trips GROUP BY driver, city HAVING count(*) > 1 ORDER BY 1;
