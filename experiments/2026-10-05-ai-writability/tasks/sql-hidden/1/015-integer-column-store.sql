CREATE TABLE n (k INTEGER, v INTEGER);
INSERT INTO n VALUES (1, 3.0), (2, '  -45  '), (3, '7.000'), (4, '2E2'), (5, 0.0);
INSERT INTO n VALUES (6, 1e15), (7, -1.0), (8, '+0'), (9, 10 / 2.0), (10, '1.0e1');
INSERT INTO n VALUES (11, 9 * 9), (12, '000123');
SELECT k, v, typeof(v) FROM n ORDER BY k;
SELECT k FROM n WHERE v = 1000000000000000;
