CREATE TABLE t (name TEXT, x INTEGER, y INTEGER);
INSERT INTO t VALUES ('a', 1, 9), ('b', 5, 2), ('c', 3, 3), ('d', -4, 1);
SELECT name FROM t ORDER BY x + y, name;
SELECT name FROM t ORDER BY x * y DESC, name;
SELECT name FROM t ORDER BY abs(x);
SELECT name, x FROM t ORDER BY -x;
SELECT name FROM t ORDER BY y % 2, name DESC;
SELECT name FROM t ORDER BY upper(name) DESC;
