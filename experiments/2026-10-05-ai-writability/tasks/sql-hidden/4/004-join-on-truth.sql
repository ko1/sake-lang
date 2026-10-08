-- ON keeps a pair only when its condition is true: NULL and false-like text drop it.
CREATE TABLE a (id INTEGER, flag TEXT);
CREATE TABLE b (id INTEGER, w INTEGER);
INSERT INTO a VALUES (1, 'yes'), (2, '1'), (3, NULL), (4, '0.5');
INSERT INTO b VALUES (10, 1), (20, NULL);
SELECT a.id, b.id FROM a JOIN b ON flag ORDER BY a.id, b.id;
SELECT a.id, b.id FROM a JOIN b ON w ORDER BY a.id;
SELECT a.id, b.id FROM a LEFT JOIN b ON flag AND w ORDER BY a.id;
SELECT a.id FROM a JOIN b ON a.id = 1 ORDER BY b.id;
SELECT count(*) FROM a JOIN b ON NULL;
SELECT count(*) FROM a LEFT JOIN b ON NULL;
