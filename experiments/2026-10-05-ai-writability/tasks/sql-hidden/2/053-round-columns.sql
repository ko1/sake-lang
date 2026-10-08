CREATE TABLE m (x REAL, n INTEGER);
INSERT INTO m VALUES (1.4999, 0), (1.5, 0), (-1.5, 0), (3.14159, 2), (0.045, 2), (99.95, 1), (7.5, -3);
SELECT x, n, round(x, n) FROM m ORDER BY x;
SELECT round(x) FROM m WHERE n = 0 ORDER BY x;
SELECT round('  -3.5'), round(' 9.99 kg', 1), round(42, 2), typeof(round(42, 2)), round(0.5, 0);
SELECT round(2.5) = 3, round(-0.5), round(1e15 + 0.5);
