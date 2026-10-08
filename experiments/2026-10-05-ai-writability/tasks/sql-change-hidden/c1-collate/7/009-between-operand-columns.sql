-- BETWEEN with columns as bounds: x >= a and x <= b each pick their collation.
CREATE TABLE r (id INTEGER, lo TEXT COLLATE NOCASE, hi TEXT, x TEXT);
INSERT INTO r VALUES (1, 'A', 'c', 'b'), (2, 'a', 'C', 'b'), (3, 'B', 'Z', 'b'), (4, 'M', 'z', 'm  ');
SELECT id FROM r WHERE x BETWEEN lo AND hi ORDER BY id;
SELECT id FROM r WHERE x COLLATE NOCASE BETWEEN lo AND hi ORDER BY id;
SELECT id FROM r WHERE 'b' BETWEEN lo AND hi ORDER BY id;
SELECT id FROM r WHERE x COLLATE RTRIM BETWEEN 'm' AND 'm' ORDER BY id;
