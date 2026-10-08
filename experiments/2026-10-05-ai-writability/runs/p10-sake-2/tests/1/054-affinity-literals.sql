-- No conversion between two operands without affinity.
SELECT 12 = '12', '12' = 12, 1 < '0', '1' = 1.0;
SELECT 1 + 0 = '1', '1' + 0 = 1;
SELECT 'a' > 99, 5 IS '5';
CREATE TABLE t (i INTEGER, s TEXT, r REAL);
INSERT INTO t VALUES (5, '5', 5.0);
SELECT i = s, s = i, r = s, i = r FROM t;
SELECT i + 0 = '5', s || '' = 5, i = '5' FROM t;
SELECT abs(i) = '5', upper(s) = 5 FROM t;
