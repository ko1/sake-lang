CREATE TABLE t (name TEXT, score INTEGER);
INSERT INTO t VALUES ('cy', 7), ('al', 9), ('bo', 3), ('di', 7);
SELECT name, score FROM t ORDER BY 2, 1;
SELECT name, score FROM t ORDER BY 2 DESC, 1 DESC;
SELECT score * 10, name FROM t ORDER BY 1, 2;
SELECT * FROM t ORDER BY 1;
SELECT name FROM t ORDER BY 1 + 0, name;
