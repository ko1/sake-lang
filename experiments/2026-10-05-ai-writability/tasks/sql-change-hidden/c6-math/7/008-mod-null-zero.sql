-- zero divisors, NULLs and text for mod
CREATE TABLE pair (a INTEGER, b INTEGER);
INSERT INTO pair VALUES (17, 5), (17, 0), (NULL, 3), (8, NULL), (-17, 5);
SELECT a, b, mod(a, b) FROM pair ORDER BY a, b;
SELECT mod('17', '5'), mod(' 4.5 ', 2), mod('17 apples', 5), mod(17, 'five'), mod(3, '0');
SELECT mod(4);
SELECT Mod(4, 2, 1);
