-- geometry: distances from the origin with a CTE, a view and a running maximum
CREATE TABLE spot (id INTEGER, x REAL, y REAL);
INSERT INTO spot VALUES (1, 3.0, 4.0), (2, -6.0, 8.0), (3, 1.0, -1.0), (4, 0.0, 2.5);
CREATE VIEW dist AS SELECT id, sqrt(pow(x, 2) + pow(y, 2)) AS d FROM spot;
SELECT id, d, floor(d), ceil(d) FROM dist ORDER BY id;
WITH ring AS (SELECT id, floor(d / 2) AS band FROM dist)
SELECT band, count(*) FROM ring GROUP BY band ORDER BY band;
SELECT id, max(trunc(d)) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) FROM dist ORDER BY id;
SELECT id, round(pi() * pow(d, 2), 2) FROM dist WHERE d < 5 ORDER BY id;
