-- scenario: sensor readings with time-based windows, smoothing and gap detection
CREATE TABLE sensor (id INTEGER PRIMARY KEY, room TEXT UNIQUE);
CREATE TABLE reading (sensor_id INTEGER, t INTEGER, temp REAL);
INSERT INTO sensor (room) VALUES ('lab'), ('hall');
INSERT INTO reading VALUES (1, 0, 20.5), (1, 10, 21.0), (1, 20, 21.5), (1, 50, 23.0), (1, 55, 22.0), (1, 60, NULL);
INSERT INTO reading VALUES (2, 0, 18.0), (2, 30, 18.5), (2, 35, 19.5), (2, 90, 17.0);
INSERT INTO reading VALUES (2, 95, 'warm');
SELECT sensor_id, count(*), count(temp) FROM reading GROUP BY sensor_id ORDER BY sensor_id;
-- readings in the last 15 time units, including this one
SELECT sensor_id, t, count(*) OVER (PARTITION BY sensor_id ORDER BY t RANGE BETWEEN 15 PRECEDING AND CURRENT ROW) FROM reading ORDER BY sensor_id, t;
SELECT sensor_id, t, avg(temp) OVER (PARTITION BY sensor_id ORDER BY t RANGE BETWEEN 15 PRECEDING AND CURRENT ROW) FROM reading ORDER BY sensor_id, t;
-- smoothed over neighbouring readings
SELECT sensor_id, t, avg(temp) OVER (PARTITION BY sensor_id ORDER BY t ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM reading ORDER BY sensor_id, t;
-- gaps longer than 20
SELECT s.room, r.t, r.gap FROM (SELECT sensor_id, t, t - lag(t) OVER (PARTITION BY sensor_id ORDER BY t) AS gap FROM reading) AS r
  JOIN sensor AS s ON s.id = r.sensor_id WHERE r.gap > 20 ORDER BY s.room, r.t;
-- readings within 10 units after this one
SELECT sensor_id, t, count(*) OVER (PARTITION BY sensor_id ORDER BY t RANGE BETWEEN 1 FOLLOWING AND 10 FOLLOWING) FROM reading ORDER BY sensor_id, t;
-- hottest reading per room, and how each compares with the room's maximum
SELECT s.room, r.t, r.temp, max(r.temp) OVER (PARTITION BY s.room) - r.temp FROM reading AS r JOIN sensor AS s ON s.id = r.sensor_id
  WHERE r.temp IS NOT NULL ORDER BY s.room, r.t;
SELECT sensor_id, t, temp, rank() OVER (PARTITION BY sensor_id ORDER BY temp DESC NULLS LAST) FROM reading ORDER BY sensor_id, t;
UPDATE reading SET temp = 22.5 WHERE temp IS NULL;
SELECT sensor_id, t, temp - first_value(temp) OVER (PARTITION BY sensor_id ORDER BY t) AS rise FROM reading ORDER BY sensor_id, t;
SELECT sensor_id, t, last_value(t) OVER (PARTITION BY sensor_id ORDER BY temp RANGE BETWEEN CURRENT ROW AND 1 FOLLOWING) FROM reading
  WHERE sensor_id = 1 ORDER BY t;
SELECT t, temp FROM reading WHERE sensor_id = 2 ORDER BY lead(temp) OVER (ORDER BY t) DESC NULLS FIRST, t;
-- a third sensor joins; the per-room summary is ranked by warmth
INSERT INTO sensor (room) VALUES ('roof');
INSERT INTO reading VALUES (3, 0, 15.0), (3, 20, 16.5);
SELECT s.room, round(avg(r.temp), 2) AS a, rank() OVER (ORDER BY avg(r.temp) DESC) FROM sensor AS s JOIN reading AS r ON r.sensor_id = s.id GROUP BY s.room ORDER BY s.room;
SELECT room, ntile(2) OVER (ORDER BY id) FROM sensor ORDER BY id;
