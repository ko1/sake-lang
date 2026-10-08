CREATE TABLE m (k INTEGER, x REAL);
INSERT INTO m VALUES (1, 0), (2, -17), (3, '0.125'), (4, ' 2e-3 '), (5, '+6'), (6, 7 / 2);
INSERT INTO m VALUES (7, 7 / 2.0), (8, '1.'), (9, NULL), (10, 1e16);
SELECT k, x, typeof(x) FROM m ORDER BY k;
SELECT k, x / 2 FROM m WHERE k = 2;
SELECT k FROM m WHERE x = 3;
