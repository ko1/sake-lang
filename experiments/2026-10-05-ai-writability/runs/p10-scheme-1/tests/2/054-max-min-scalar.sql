SELECT max(1, 5, 3), min(1, 5, 3), max(2.5, 2), min(-1, -1.5), max('apple', 'pear');
SELECT max(1, 'a'), min(1, 'a'), max(10, '9'), min('B', 'a'), max(3, NULL), min(NULL, 1, 2);
CREATE TABLE lim (v INTEGER, lo INTEGER, hi INTEGER);
INSERT INTO lim VALUES (5, 1, 10), (-3, 0, 4), (12, 2, 8), (NULL, 0, 1);
SELECT v, min(max(v, lo), hi) FROM lim ORDER BY v;
SELECT typeof(max(1, 2.5)), typeof(min(1, 2.5));
