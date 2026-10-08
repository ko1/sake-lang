SELECT 17 / 5, -17 / 5, 17 / -5, -17 / -5;
SELECT 17 % 5, -17 % 5, 17 % -5, -17 % -5;
SELECT 5 / 17, 0 % 3, 3 % 1;
SELECT (17 / 5) * 5 + 17 % 5;
SELECT typeof(17 % 5), typeof(17 / 5);
SELECT 123456789 * 1000;
CREATE TABLE d (a INTEGER, b INTEGER);
INSERT INTO d VALUES (9, 2), (-9, 2), (9, -4), (-9, -4), (0, 7);
SELECT a, b, a / b, a % b FROM d ORDER BY a, b;
