-- an index changes no result; DROP INDEX removes it
CREATE TABLE t (a INTEGER, b TEXT);
INSERT INTO t VALUES (3, 'c'), (1, 'a'), (2, 'b'), (1, 'z');
CREATE INDEX t_a ON t (a);
CREATE INDEX IF NOT EXISTS t_ab ON t (a, b);
CREATE INDEX IF NOT EXISTS t_a ON t (b);
SELECT a, b FROM t WHERE a = 1 ORDER BY b;
SELECT a, b FROM t ORDER BY a, b;
INSERT INTO t VALUES (1, 'a');
SELECT count(*) FROM t WHERE a = 1;
DROP INDEX t_a;
DROP INDEX IF EXISTS t_a;
DROP INDEX IF EXISTS t_ab;
CREATE INDEX t_a ON t (b);
SELECT count(*) FROM t;
