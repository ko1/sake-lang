-- an integer ORDER BY term of a compound must be within the column count
SELECT 1, 2 UNION SELECT 3, 4 ORDER BY 3;
SELECT 1 UNION ALL SELECT 2 ORDER BY 1, 2;
SELECT 'a' AS c UNION SELECT 'b' ORDER BY 1 DESC;
SELECT 1, 'x' EXCEPT SELECT 2, 'y' ORDER BY 2;
