-- mod is the remainder as a REAL, with the sign of the first argument
SELECT mod(7, 3), mod(-7, 3), mod(7, -3), mod(-7, -3), typeof(mod(7, 3));
SELECT mod(7.5, 2), mod(5.5, 2.5), mod(-7.5, 2), mod(10, 3.5), mod(0, 5);
-- unlike %, mod does not truncate its operands
SELECT 7.5 % 2, mod(7.5, 2), 17 % 5, mod(17, 5);
CREATE TABLE minutes (id INTEGER, total INTEGER);
INSERT INTO minutes VALUES (1, 125), (2, 59), (3, 600), (4, 61);
SELECT id, total / 60, mod(total, 60) FROM minutes ORDER BY id;
