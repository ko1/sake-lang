-- INSERT ... SELECT inserts the select's rows
CREATE TABLE src (id INTEGER, name TEXT, score INTEGER);
CREATE TABLE dst (id INTEGER, name TEXT, score INTEGER);
INSERT INTO src VALUES (1, 'a', 50), (2, 'b', 80), (3, 'c', 65);
INSERT INTO dst SELECT id, name, score FROM src WHERE score > 60;
SELECT * FROM dst ORDER BY id;
INSERT INTO dst SELECT * FROM src WHERE id = 1;
SELECT count(*), sum(score) FROM dst;
INSERT INTO dst SELECT 9, 'z', 0 UNION ALL SELECT 8, 'y', 1;
SELECT id, name FROM dst WHERE score < 10 ORDER BY id;
INSERT INTO dst SELECT * FROM src WHERE id > 100;
SELECT count(*) FROM dst;
