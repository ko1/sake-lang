-- PARTITION BY puts values equal under the term's collation into one partition.
CREATE TABLE pay (id INTEGER, team TEXT COLLATE NOCASE, tag TEXT, amt INTEGER);
INSERT INTO pay VALUES (1, 'Red', 'Red', 5), (2, 'RED', 'RED', 7), (3, 'blue', 'blue', 1), (4, 'red', 'red', 2), (5, 'Blue', 'Blue', 9);
SELECT id, sum(amt) OVER (PARTITION BY team), count(*) OVER (PARTITION BY tag) FROM pay ORDER BY id;
SELECT id, row_number() OVER (PARTITION BY tag COLLATE NOCASE ORDER BY id) FROM pay ORDER BY id;
SELECT id, count(*) OVER (PARTITION BY team COLLATE BINARY) FROM pay ORDER BY id;
