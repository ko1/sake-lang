CREATE TABLE k (id INTEGER PRIMARY KEY, v TEXT);
INSERT INTO k VALUES (1, 'a'), (2, 'b');
INSERT INTO k VALUES (2, 'c');
INSERT INTO k VALUES ('2', 'c');
INSERT INTO k VALUES (2.0, 'c');
INSERT INTO k VALUES (' 3 ', 'c');
UPDATE k SET id = 1 WHERE v = 'c';
UPDATE k SET id = 30 WHERE v = 'c';
SELECT id, typeof(id), v FROM k ORDER BY id;
