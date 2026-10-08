-- USING (c) uses the left side's column collation.
CREATE TABLE l (k TEXT COLLATE RTRIM, x INTEGER);
CREATE TABLE r (k TEXT, y INTEGER);
INSERT INTO l VALUES ('a  ', 1), ('b', 2);
INSERT INTO r VALUES ('a', 10), ('b  ', 20), ('b', 30);
SELECT x, y FROM l JOIN r USING (k) ORDER BY x, y;
SELECT x, y FROM r JOIN l USING (k) ORDER BY x, y;
SELECT y, x FROM r LEFT JOIN l USING (k) ORDER BY y;
