-- Comparing a column with a scalar subquery uses the column's collation, whichever side it is on.
CREATE TABLE t1 (id INTEGER, a TEXT);
CREATE TABLE t2 (b TEXT COLLATE NOCASE);
INSERT INTO t1 VALUES (1, 'Box'), (2, 'BOX'), (3, 'box');
INSERT INTO t2 VALUES ('box');
SELECT id FROM t1 WHERE a = (SELECT b FROM t2) ORDER BY id;
SELECT id FROM t1 WHERE (SELECT b FROM t2) = a ORDER BY id;
SELECT id FROM t1 WHERE a COLLATE NOCASE = (SELECT b FROM t2) ORDER BY id;
SELECT count(*) FROM t1 WHERE (SELECT b FROM t2) = 'BOX';
