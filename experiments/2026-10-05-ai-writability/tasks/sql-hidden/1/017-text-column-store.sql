CREATE TABLE s (k INTEGER, t TEXT);
INSERT INTO s VALUES (1, 7), (2, -7.0), (3, 2.0 / 3), (4, 1e-7), (5, 12345678901234), (6, 0.5e1);
INSERT INTO s VALUES (7, '007'), (8, ' x '), (9, 1e15), (10, 3 || 4);
SELECT k, t, typeof(t), length(t) FROM s ORDER BY k;
SELECT k FROM s WHERE t = '7';
SELECT k FROM s WHERE t = '1.0e-07';
