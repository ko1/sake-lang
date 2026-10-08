-- text arguments and argument count for pow and power
SELECT pow('10', '3'), power(' 4 ', 0.5), pow('2e1', 2), pow('ten', 2), power(2, '3x');
CREATE TABLE growth (yr INTEGER, rate REAL);
INSERT INTO growth VALUES (1, 1.5), (2, 1.5), (3, 2.0), (0, 1.1);
SELECT yr, rate, pow(rate, yr) FROM growth ORDER BY yr;
SELECT power();
SELECT POW(1, 2, 3);
SELECT Power(5);
