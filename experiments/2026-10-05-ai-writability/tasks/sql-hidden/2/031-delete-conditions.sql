CREATE TABLE f (name TEXT, ext TEXT, size INTEGER);
INSERT INTO f VALUES ('a', 'tmp', 10), ('b', 'txt', 2000), ('c', 'log', 500), ('d', NULL, 0), ('e', 'TMP', 30), ('f', 'bak', 99);
DELETE FROM f WHERE ext LIKE 'tmp';
SELECT name FROM f ORDER BY name;
DELETE FROM f WHERE ext NOT IN ('txt', 'log');
SELECT name FROM f ORDER BY name;
DELETE FROM f WHERE size NOT BETWEEN 100 AND 1000;
SELECT name, ext, size FROM f ORDER BY name;
