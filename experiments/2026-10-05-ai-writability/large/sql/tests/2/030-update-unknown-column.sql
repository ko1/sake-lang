CREATE TABLE z (a INTEGER, b INTEGER);
UPDATE z SET c = 1;
UPDATE z SET a = c;
UPDATE z SET a = 1 WHERE c = 2;
INSERT INTO z VALUES (1, 2);
UPDATE z SET a = 1, nope = 2;
UPDATE missing SET a = 1;
UPDATE z SET b = a + b;
SELECT a, b FROM z;
