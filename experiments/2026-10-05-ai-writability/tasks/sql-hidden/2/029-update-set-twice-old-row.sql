CREATE TABLE z (a INTEGER, b INTEGER);
INSERT INTO z VALUES (1, 100), (2, 200);
UPDATE z SET a = b, b = 0, a = a + b WHERE a = 1;
SELECT a, b FROM z ORDER BY a;
UPDATE z SET b = b + 1, b = b + 2, b = b + 3 WHERE a = 2;
SELECT a, b FROM z ORDER BY a;
UPDATE z SET a = 5 WHERE a = 2 AND b = 203;
SELECT a, b FROM z ORDER BY a;
