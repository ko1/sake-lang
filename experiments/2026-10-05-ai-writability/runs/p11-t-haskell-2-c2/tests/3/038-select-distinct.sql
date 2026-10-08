CREATE TABLE colors (shade TEXT, code INTEGER);
INSERT INTO colors VALUES ('red', 1), ('blue', 2), ('red', 1), ('red', 3), ('Blue', 2);
SELECT DISTINCT shade FROM colors ORDER BY shade;
SELECT DISTINCT shade, code FROM colors ORDER BY shade, code;
SELECT DISTINCT code FROM colors ORDER BY code DESC;
SELECT DISTINCT lower(shade) AS s FROM colors ORDER BY s;
SELECT count(*) FROM colors;
