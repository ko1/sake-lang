CREATE TABLE tri (a TEXT, b TEXT, c TEXT, k INTEGER);
INSERT INTO tri VALUES ('x', 'y', 'z', 1), ('p', 'q', 'r', 2);
UPDATE tri SET a = b, b = c, c = a;
SELECT k, a, b, c FROM tri ORDER BY k;
UPDATE tri SET a = a || b || c, k = k + 10 WHERE k = 1;
SELECT k, a FROM tri ORDER BY k;
UPDATE tri SET k = k * 2 WHERE k > 5;
UPDATE tri SET k = k - 1 WHERE k > 5;
SELECT k, b FROM tri ORDER BY k;
