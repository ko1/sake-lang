CREATE TABLE races (event TEXT, lane INTEGER, time REAL);
INSERT INTO races VALUES ('100m', 1, 10.5), ('100m', 2, NULL), ('100m', 3, 9.98), ('200m', 1, NULL), ('200m', 4, 21.3);
INSERT INTO races VALUES ('400m', 2, NULL);
SELECT event, min(time), max(time), min(lane), max(lane) FROM races GROUP BY event ORDER BY event;
SELECT event FROM races GROUP BY event HAVING min(time) IS NULL ORDER BY event;
SELECT max(time) - min(time) FROM races WHERE event = '100m';
SELECT typeof(min(time)), typeof(max(lane)) FROM races;
