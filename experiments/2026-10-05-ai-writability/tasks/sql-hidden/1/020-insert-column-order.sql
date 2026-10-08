CREATE TABLE r (a TEXT, b INTEGER, c REAL, d TEXT);
INSERT INTO r (d, c, b, a) VALUES ('D', 3, 2, 'A');
INSERT INTO r (b) VALUES (20), (10);
INSERT INTO r (c, a) VALUES ('7', 70);
INSERT INTO r (a, b, c, d) VALUES ('x', 1, 1, 'y');
SELECT a, b, c, d FROM r ORDER BY b NULLS LAST, a;
SELECT typeof(a), typeof(c) FROM r WHERE c = 7;
