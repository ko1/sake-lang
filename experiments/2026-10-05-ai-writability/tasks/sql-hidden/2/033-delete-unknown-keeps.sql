-- rows whose condition is unknown are not deleted
CREATE TABLE t (k INTEGER, v INTEGER);
INSERT INTO t VALUES (1, 5), (2, NULL), (3, 15), (4, 10);
DELETE FROM t WHERE v > 8;
SELECT k, v FROM t ORDER BY k;
DELETE FROM t WHERE NOT v > 8;
SELECT k, v FROM t ORDER BY k;
DELETE FROM t WHERE v IN (1, NULL);
SELECT k FROM t ORDER BY k;
DELETE FROM t WHERE v IS NULL;
SELECT count_left FROM t;
SELECT 'empty' WHERE 1;
