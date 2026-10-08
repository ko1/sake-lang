CREATE TABLE ratings (film TEXT, stars INTEGER);
INSERT INTO ratings VALUES ('up', 5), ('up', 4), ('jaws', 3), ('jaws', 4), ('jaws', 4), ('cars', 2);
SELECT film, avg(stars) FROM ratings GROUP BY film ORDER BY film;
SELECT avg(stars), typeof(avg(stars)) FROM ratings WHERE film = 'cars';
SELECT film FROM ratings GROUP BY film HAVING avg(stars) > 3.5 ORDER BY avg(stars) DESC;
SELECT round(avg(stars), 3), avg(stars) * 6 FROM ratings;
SELECT avg(stars - 3) FROM ratings WHERE film <> 'up';
