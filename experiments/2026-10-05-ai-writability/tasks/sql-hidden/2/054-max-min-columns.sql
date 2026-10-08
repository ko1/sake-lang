CREATE TABLE g (a INTEGER, b REAL, c TEXT);
INSERT INTO g VALUES (1, 2.5, 'z'), (7, 3.5, '10'), (-4, -4.5, 'A'), (2, NULL, 'b');
SELECT a, max(a, b), min(a, b) FROM g ORDER BY a;
SELECT a, max(a, c), min(b, c, a) FROM g ORDER BY a;
SELECT max('c', 'B', 'a'), min('apple', 'Apple', 'banana'), max(0.5, 1, -2), min(3, 2.5, 4);
SELECT a FROM g WHERE max(a, 3) = 3 ORDER BY a;
