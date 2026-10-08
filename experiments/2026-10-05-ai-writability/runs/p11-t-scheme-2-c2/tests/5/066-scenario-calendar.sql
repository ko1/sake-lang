-- scenario: a booking calendar with generated days and free slots
CREATE TABLE room (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE booking (room_id INTEGER, day INTEGER, who TEXT, UNIQUE (room_id, day));
INSERT INTO room (name) VALUES ('red'), ('blue');
INSERT INTO booking VALUES (1, 2, 'ann'), (1, 3, 'bob'), (2, 3, 'cy'), (2, 5, 'ann');
WITH RECURSIVE days(d) AS (SELECT 1 UNION ALL SELECT d + 1 FROM days WHERE d < 5)
SELECT r.name, d FROM room r, days WHERE NOT EXISTS (SELECT 1 FROM booking b WHERE b.room_id = r.id AND b.day = d) ORDER BY r.name, d;
WITH RECURSIVE days(d) AS (SELECT 1 UNION ALL SELECT d + 1 FROM days WHERE d < 5)
SELECT d, (SELECT count(*) FROM booking WHERE day = d) FROM days ORDER BY d;
CREATE TABLE slot (room_id INTEGER, day INTEGER);
WITH RECURSIVE days(d) AS (SELECT 1 UNION ALL SELECT d + 1 FROM days WHERE d < 5)
INSERT INTO slot SELECT r.id, d FROM room r, days;
SELECT count(*) FROM slot;
SELECT room_id, day FROM slot EXCEPT SELECT room_id, day FROM booking ORDER BY day, room_id LIMIT 4;
BEGIN;
INSERT INTO booking VALUES (1, 1, 'dan'), (2, 1, 'dan');
INSERT INTO booking VALUES (1, 4, 'eve'), (1, 2, 'eve');
SELECT who, count(*) FROM booking GROUP BY who ORDER BY who;
COMMIT;
SELECT who FROM booking WHERE room_id = 1 INTERSECT SELECT who FROM booking WHERE room_id = 2 ORDER BY who;
CREATE VIEW busiest AS SELECT day, count(*) AS n FROM booking GROUP BY day;
SELECT day FROM busiest WHERE n = (SELECT max(n) FROM busiest) ORDER BY day;
SELECT day, n FROM busiest UNION ALL SELECT 0, count(*) FROM booking ORDER BY 1;
DROP VIEW busiest;
