CREATE TABLE cells (id INTEGER, txt TEXT, num INTEGER);
INSERT INTO cells VALUES (1, 'x', 5), (2, NULL, -2), (3, 'm', NULL), (4, NULL, 9);
SELECT min(coalesce(txt, num)), max(coalesce(txt, num)) FROM cells;
SELECT typeof(min(coalesce(txt, num))), typeof(max(coalesce(txt, num))) FROM cells;
SELECT max(CASE WHEN id < 3 THEN id * 1.5 ELSE id END) FROM cells;
SELECT min(CASE WHEN id = 2 THEN 'zz' ELSE id END) FROM cells;
