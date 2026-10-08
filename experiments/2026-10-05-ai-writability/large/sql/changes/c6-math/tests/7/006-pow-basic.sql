-- pow and power raise to a power and always give a REAL
SELECT pow(2, 10), power(2, 10), typeof(pow(2, 3)), pow(-2, 3), pow(-2, 2);
SELECT pow(2, -1), pow(10, -2), pow(9, 0.5), pow(1.5, 2), pow(0, 0), pow(5, 0);
-- not a real number: NULL
SELECT pow(-8, 0.5), pow(-2, 1.5), pow(NULL, 2), pow(2, NULL);
SELECT pow('3', 2), POWER(' 2 ', '0.5'), pow('two', 2), pow(2, '');
SELECT pow(2);
SELECT power(1, 2, 3);
CREATE TABLE sq (side INTEGER);
INSERT INTO sq VALUES (3), (12), (1);
SELECT side, pow(side, 2), pow(side, 3) FROM sq ORDER BY side;
