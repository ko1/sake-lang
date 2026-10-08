-- A numeric column converts numeric-looking text on the other side.
CREATE TABLE t (id INTEGER, i INTEGER, r REAL);
INSERT INTO t VALUES (1, 12, 1.5), (2, 7, 2.0), (3, NULL, NULL);
SELECT id FROM t WHERE i = '12';
SELECT id FROM t WHERE i = ' 12 ';
SELECT id FROM t WHERE '7' = i;
SELECT id FROM t WHERE r = '1.5';
SELECT id FROM t WHERE r = '2';
SELECT id FROM t WHERE i < 'abc' ORDER BY id;
SELECT id FROM t WHERE i > '9' ORDER BY id;
SELECT id FROM t WHERE i = '12abc';
SELECT id, i = 12.0, r < '1e1' FROM t ORDER BY id;
