-- SELECT without FROM evaluates its expressions once, on one empty row.
SELECT 1;
SELECT 1, 'two', 3.5, NULL;
SELECT 42 AS answer;
SELECT 'x' y, -7;
SELECT 10 + 5, 10 - 5, 10 * 5;
