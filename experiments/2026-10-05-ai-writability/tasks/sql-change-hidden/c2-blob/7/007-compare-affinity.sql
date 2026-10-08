CREATE TABLE m (n INTEGER, r REAL, s TEXT, b BLOB);
INSERT INTO m VALUES (7, 7.0, '7', X'37');
SELECT n = X'37', r = X'37', s = X'37', b = '7', b = 7, b = X'37' FROM m;
SELECT n < b, s < b, b > s FROM m;
SELECT b IS X'37', b IS NOT '7', s IS b FROM m;
SELECT count(*) FROM m WHERE b BETWEEN X'30' AND X'39';
SELECT count(*) FROM m WHERE s BETWEEN '0' AND X'00';
