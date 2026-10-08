-- dropping a table drops its indexes
CREATE TABLE t (a INTEGER);
CREATE UNIQUE INDEX ta ON t (a);
CREATE INDEX tb ON t (a);
DROP TABLE t;
DROP INDEX ta;
CREATE TABLE t (a INTEGER);
INSERT INTO t VALUES (1), (1);
CREATE INDEX tb ON t (a);
CREATE INDEX ta ON t (a);
SELECT count(*) FROM t;
