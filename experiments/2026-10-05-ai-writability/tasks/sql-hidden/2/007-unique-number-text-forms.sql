-- a TEXT column stores numbers as text forms; an INTEGER column stores parsed text as numbers
CREATE TABLE t (s TEXT UNIQUE, i INTEGER UNIQUE);
INSERT INTO t VALUES (10, 1);
INSERT INTO t VALUES ('10', 2);
INSERT INTO t VALUES ('10.0', '1');
INSERT INTO t VALUES (1.5, 7.0);
INSERT INTO t VALUES ('1.5', 8);
INSERT INTO t VALUES ('x', ' 7 ');
INSERT INTO t VALUES ('y', '1e1');
SELECT s, typeof(s), i FROM t ORDER BY i;
