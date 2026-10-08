CREATE TABLE pairs (id INTEGER, x INTEGER, y INTEGER);
INSERT INTO pairs VALUES (1, 3, 8), (2, 9, 4), (3, 5, NULL);
SELECT id, max(x, y), min(x, y) FROM pairs ORDER BY id;
SELECT max(x), min(y) FROM pairs;
SELECT max(max(x, y)), min(min(x, y)) FROM pairs;
SELECT max(x, y, 6) FROM pairs WHERE id = 2;
