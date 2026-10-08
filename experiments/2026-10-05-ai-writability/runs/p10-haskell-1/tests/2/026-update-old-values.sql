-- every SET expression sees the row as it was before the statement
CREATE TABLE pair (x INTEGER, y INTEGER);
INSERT INTO pair VALUES (1, 2), (10, 20);
UPDATE pair SET x = y, y = x;
SELECT x, y FROM pair ORDER BY x;
UPDATE pair SET x = x + 1, y = x * 100;
SELECT x, y FROM pair ORDER BY x;
UPDATE pair SET y = y + 1 WHERE x = 3 OR y = 300;
SELECT x, y FROM pair ORDER BY x;
