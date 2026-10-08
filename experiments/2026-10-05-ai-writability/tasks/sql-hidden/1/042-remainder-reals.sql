SELECT 9.99 % 4, 9 % 4.99, -9.5 % 4;
SELECT 2.5 % 2.5, 100.7 % 7;
SELECT typeof(9 % 4.0), typeof(9 % 4);
SELECT '9.5' % 2, '9' % 2;
SELECT 5.5 % -2, -5.5 % -2;
CREATE TABLE r (x REAL);
INSERT INTO r VALUES (7.25), (-7.25), (0.75);
SELECT x, x % 3 FROM r ORDER BY x;
