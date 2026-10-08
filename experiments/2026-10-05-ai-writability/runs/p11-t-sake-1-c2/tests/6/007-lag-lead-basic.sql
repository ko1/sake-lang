-- lag/lead with one argument look one row back/forward in the partition
CREATE TABLE temp (day INTEGER, city TEXT, deg INTEGER);
INSERT INTO temp VALUES (1,'oslo',3),(2,'oslo',5),(3,'oslo',4),(1,'rome',15),(2,'rome',18),(3,'rome',17);
SELECT city, day, deg, lag(deg) OVER (PARTITION BY city ORDER BY day), lead(deg) OVER (PARTITION BY city ORDER BY day) FROM temp ORDER BY city, day;
SELECT city, day, deg - lag(deg) OVER (PARTITION BY city ORDER BY day) AS change FROM temp ORDER BY city, day;
SELECT day, city, lead(city) OVER (ORDER BY city, day) FROM temp ORDER BY city, day;
