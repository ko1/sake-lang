-- q.c with no source q, or a source q without column c, is no such column: q.c as written.
CREATE TABLE t (a INTEGER, b TEXT);
CREATE TABLE u (a INTEGER, c TEXT);
INSERT INTO t VALUES (1, 'x');
INSERT INTO u VALUES (1, 'y');
SELECT v.a FROM t JOIN u ON t.a = u.a;
SELECT t.c FROM t JOIN u ON t.a = u.a;
SELECT u.b FROM t, u;
SELECT T.Zed FROM t;
SELECT t.a FROM t JOIN u ON t.a = w.a;
SELECT t.a FROM t, u WHERE u.b = 'x';
SELECT t.a, u.c FROM t, u ORDER BY t.nope;
SELECT t.a, u.c FROM t, u;
