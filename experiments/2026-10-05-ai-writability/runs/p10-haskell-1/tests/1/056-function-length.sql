SELECT length('hello'), length(''), length('a b');
SELECT length(1.5), length(42), length(-12);
SELECT length(1e20), length(100.0), length(0.1 + 0.2);
SELECT length(NULL), typeof(length('x'));
SELECT LENGTH('ABC'), Length('it''s');
CREATE TABLE t (s TEXT, n INTEGER);
INSERT INTO t VALUES ('pear', 1000), ('fig', -5), (NULL, 7);
SELECT s, length(s), length(n) FROM t ORDER BY n;
SELECT s FROM t WHERE length(s) = 3;
